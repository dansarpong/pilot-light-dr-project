import boto3
import time
import json

def promote_rds_replica(params):
    rds_client = boto3.client('rds', region_name=params['dr_region'])
    db_identifier = params['dr_rds_name']
    ssm_client = boto3.client('ssm', region_name=params['primary_region'])

    # Get the new endpoint
    response = rds_client.describe_db_instances(
        DBInstanceIdentifier=db_identifier
    )
    new_endpoint = response['DBInstances'][0]['Endpoint']['Address']

    # Update the SSM parameter with the new endpoint
    ssm_client.put_parameter(
        Name='dr_rds_name',
        Value=new_endpoint,
        Type='String',
        Overwrite=True
    )
    
    rds_client.promote_read_replica(
        DBInstanceIdentifier=db_identifier
    )
    
    return {"db_identifier": db_identifier}

def check_rds_status(params, promotion):
    rds_client = boto3.client('rds', region_name=params['dr_region'])
    response = rds_client.describe_db_instances(
        DBInstanceIdentifier=promotion['db_identifier']
    )
    
    return {
        "is_available": response['DBInstances'][0]['DBInstanceStatus'] == 'available',
        "db_identifier": promotion['db_identifier']
    }

def handle_s3_failover(params):
    dr_s3_client = boto3.client('s3', region_name=params['dr_region'])
    primary_s3_client = boto3.client('s3', region_name=params['primary_region'])
    
    # Disable replication from primary to DR bucket
    try:
        primary_s3_client.delete_bucket_replication(
            Bucket=params['primary_bucket']
        )
    except Exception as e:
        print(f"Warning: Could not disable primary replication: {str(e)}")
    
    # Enable versioning on DR bucket
    dr_s3_client.put_bucket_versioning(
        Bucket=params['dr_bucket'],
        VersioningConfiguration={'Status': 'Enabled'}
    )
    
    # Set up reverse replication
    replication_config = {
        'Role': params['replication_role_arn'],
        'Rules': [
            {
                'ID': 'reverse-replication-rule',
                'Status': 'Enabled',
                'Priority': 1,
                'DeleteMarkerReplication': {'Status': 'Enabled'},
                'Filter': {'Prefix': ''},
                'Destination': {
                    'Bucket': f'arn:aws:s3:::{params["primary_bucket"]}',
                    'Metrics': {
                        'Status': 'Enabled',
                        'EventThreshold': {'Minutes': 15}
                    },
                    'ReplicationTime': {
                        'Status': 'Enabled',
                        'Time': {'Minutes': 15}
                    }
                }
            }
        ]
    }
    
    dr_s3_client.put_bucket_replication(
        Bucket=params['dr_bucket'],
        ReplicationConfiguration=replication_config
    )
    
    return {"status": "S3 failover completed"}

def update_asg(params):
    ec2_client = boto3.client('ec2', region_name=params['dr_region'])
    asg_client = boto3.client('autoscaling', region_name=params['dr_region'])
    
    # Get latest AMI
    images = ec2_client.describe_images(
        Filters=[
            {
                'Name': 'name',
                'Values': [f"Copied-AMI-{params['asg_name']}-*"]
            },
            {
                'Name': 'state',
                'Values': ['available']
            }
        ],
        Owners=['self']
    )
    
    if not images['Images']:
        raise Exception("No copied AMIs found")
    
    latest_ami = sorted(images['Images'], 
                       key=lambda x: x['CreationDate'],
                       reverse=True)[0]
    
    # Update ASG
    asg_response = asg_client.describe_auto_scaling_groups(
        AutoScalingGroupNames=[params['asg_name']]
    )
    launch_template_id = asg_response['AutoScalingGroups'][0]['LaunchTemplate']['LaunchTemplateId']
    
    ec2_client.create_launch_template_version(
        LaunchTemplateId=launch_template_id,
        SourceVersion='$Latest',
        LaunchTemplateData={
            'ImageId': latest_ami['ImageId']
        }
    )
    
    asg_client.update_auto_scaling_group(
        AutoScalingGroupName=params['asg_name'],
        DesiredCapacity=1,
        MinSize=1,
        MaxSize=2,
        LaunchTemplate={
            'LaunchTemplateId': launch_template_id,
            'Version': '$Latest'
        }
    )
    
    return {"asg_name": params['asg_name']}

def check_asg_status(params, asg_update):
    asg_client = boto3.client('autoscaling', region_name=params['dr_region'])
    response = asg_client.describe_auto_scaling_groups(
        AutoScalingGroupNames=[asg_update['asg_name']]
    )
    
    instances = response['AutoScalingGroups'][0]['Instances']
    is_ready = len(instances) > 0 and all(
        instance['LifecycleState'] == 'InService' 
        for instance in instances
    )
    
    return {
        "is_ready": is_ready,
        "asg_name": asg_update['asg_name']
    }

def enable_ssm_sync(params):
    events_client = boto3.client('events', region_name=params['dr_region'])
    # lambda_client = boto3.client('lambda', region_name=params['dr_region'])
    
    rule_name = f"ssm-sync-rule-dr"
    # function_name = f"{params['environment']}-ssm-sync-lambda-dr"
    
    # # Define the event pattern for SSM parameter changes
    # event_pattern = {
    #     "source": ["aws.ssm"],
    #     "detail-type": ["AWS API Call via CloudTrail"],
    #     "detail": {
    #         "eventSource": ["ssm.amazonaws.com"],
    #         "eventName": ["PutParameter", "DeleteParameter", "DeleteParameters"]
    #     }
    # }
    
    # Enable the EventBridge rule
    rule_response = events_client.enable_rule(
        Name=rule_name
    )
    
    # # Add Lambda permission for EventBridge
    # try:
    #     lambda_client.add_permission(
    #         FunctionName=function_name,
    #         StatementId=f"Allow-EventBridge-Invoke-{rule_name}",
    #         Action='lambda:InvokeFunction',
    #         Principal='events.amazonaws.com',
    #         SourceArn=rule_response['RuleArn']
    #     )
    # except lambda_client.exceptions.ResourceConflictException:
    #     # Permission already exists, ignore
    #     pass
    
    return {"status": "SSM sync enabled in DR region"}

def lambda_handler(event, context):
    operation = event['operation']
    params = event['params']
    
    operations = {
        'PROMOTE_RDS_REPLICA': lambda: promote_rds_replica(params),
        'CHECK_RDS_STATUS': lambda: check_rds_status(params, event['promotion']),
        'S3_FAILOVER': lambda: handle_s3_failover(params),
        'UPDATE_ASG': lambda: update_asg(params),
        'CHECK_ASG_STATUS': lambda: check_asg_status(params, event['asg_update']),
        'ENABLE_SSM_SYNC': lambda: enable_ssm_sync(params)
    }
    
    return operations[operation]()
