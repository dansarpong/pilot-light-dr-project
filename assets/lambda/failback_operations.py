import boto3
import time
from datetime import datetime

def setup_primary_replication(s3_client, primary_bucket, dr_bucket, replication_role_arn):
    s3_client.put_bucket_versioning(
        Bucket=primary_bucket,
        VersioningConfiguration={'Status': 'Enabled'}
    )
    
    replication_config = {
        'Role': replication_role_arn,
        'Rules': [
            {
                'ID': 'primary-replication-rule',
                'Status': 'Enabled',
                'Priority': 1,
                'DeleteMarkerReplication': {'Status': 'Enabled'},
                'Filter': {'Prefix': ''},
                'Destination': {
                    'Bucket': f'arn:aws:s3:::{dr_bucket}',
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
    
    s3_client.put_bucket_replication(
        Bucket=primary_bucket,
        ReplicationConfiguration=replication_config
    )

def handle_s3_failback(params):
    dr_s3_client = boto3.client('s3', region_name=params['dr_region'])
    primary_s3_client = boto3.client('s3', region_name=params['primary_region'])
    
    try:
        dr_s3_client.delete_bucket_replication(Bucket=params['dr_bucket'])
    except Exception as e:
        print(f"Warning: Could not disable DR replication: {str(e)}")
    
    setup_primary_replication(
        primary_s3_client,
        params['primary_bucket'],
        params['dr_bucket'],
        params['replication_role_arn']
    )
    
    return {"status": "S3 failback completed"}

def create_snapshot(params):
    dr_rds_client = boto3.client('rds', region_name=params['dr_region'])
    timestamp = time.strftime('%Y-%m-%d-%H-%M-%S')
    snapshot_id = f"failback-snapshot-{timestamp}"
    
    dr_rds_client.create_db_snapshot(
        DBSnapshotIdentifier=snapshot_id,
        DBInstanceIdentifier=params['dr_rds_name']
    )
    
    return {"snapshot_id": snapshot_id}

def check_snapshot_status(params, snapshot):
    dr_rds_client = boto3.client('rds', region_name=params['dr_region'])
    response = dr_rds_client.describe_db_snapshots(
        DBSnapshotIdentifier=snapshot['snapshot_id']
    )
    
    return {
        "is_available": response['DBSnapshots'][0]['Status'] == 'available',
        "snapshot_id": snapshot['snapshot_id']
    }

def copy_snapshot(params, snapshot):
    primary_rds_client = boto3.client('rds', region_name=params['primary_region'])
    primary_snapshot_id = f"copied-{snapshot['snapshot_id']}"
    
    primary_rds_client.copy_db_snapshot(
        SourceDBSnapshotIdentifier=f"arn:aws:rds:{params['dr_region']}:{params['account_id']}:snapshot:{snapshot['snapshot_id']}",
        TargetDBSnapshotIdentifier=primary_snapshot_id,
        SourceRegion=params['dr_region']
    )
    
    return {"primary_snapshot_id": primary_snapshot_id}

def check_copied_snapshot_status(params, snapshot):
    primary_rds_client = boto3.client('rds', region_name=params['primary_region'])
    response = primary_rds_client.describe_db_snapshots(
        DBSnapshotIdentifier=snapshot['primary_snapshot_id']
    )
    
    return {
        "is_available": response['DBSnapshots'][0]['Status'] == 'available',
        "primary_snapshot_id": snapshot['primary_snapshot_id']
    }

def restore_db(params, copied_snapshot):
    primary_rds_client = boto3.client('rds', region_name=params['primary_region'])
    primary_db_identifier = params['primary_rds_name']

    # Get the original DB configuration before deleting
    try:
        original_config = primary_rds_client.describe_db_instances(
            DBInstanceIdentifier=primary_db_identifier
        )['DBInstances'][0]
        security_group_ids = [sg['VpcSecurityGroupId'] for sg in original_config['VpcSecurityGroups']]
        subnet_group_name = original_config['DBSubnetGroup']['DBSubnetGroupName']
    except primary_rds_client.exceptions.DBInstanceNotFoundFault:
        print("DB instance not found, will use default configuration")
        security_group_ids = []
        subnet_group_name = None
    except Exception as e:
        print(f"Warning: Could not fetch original config: {str(e)}")
        security_group_ids = []
        subnet_group_name = None

    # Delete existing instance if it exists
    try:
        primary_rds_client.delete_db_instance(
            DBInstanceIdentifier=primary_db_identifier,
            SkipFinalSnapshot=True,
            DeleteAutomatedBackups=True
        )

        waiter = primary_rds_client.get_waiter('db_instance_deleted')
        waiter.wait(
            DBInstanceIdentifier=primary_db_identifier,
            WaiterConfig={'Delay': 30, 'MaxAttempts': 60}
        )
    except primary_rds_client.exceptions.DBInstanceNotFoundFault:
        print("DB instance does not exist, proceeding with restore...")

    # Restore the instance with original security groups and subnet group
    restore_params = {
        'DBInstanceIdentifier': primary_db_identifier,
        'DBSnapshotIdentifier': copied_snapshot['primary_snapshot_id'],
        'MultiAZ': True,
        'PubliclyAccessible': False,
    }

    if security_group_ids:
        restore_params['VpcSecurityGroupIds'] = security_group_ids
    if subnet_group_name:
        restore_params['DBSubnetGroupName'] = subnet_group_name

    primary_rds_client.restore_db_instance_from_db_snapshot(**restore_params)
    
    return {"db_identifier": primary_db_identifier}

def check_db_status(params, db_info):
    primary_rds_client = boto3.client('rds', region_name=params['primary_region'])
    response = primary_rds_client.describe_db_instances(
        DBInstanceIdentifier=db_info['db_identifier']
    )
    
    return {
        "is_available": response['DBInstances'][0]['DBInstanceStatus'] == 'available',
        "db_identifier": db_info['db_identifier']
    }

def create_read_replica(params):
    dr_rds_client = boto3.client('rds', region_name=params['dr_region'])
    dr_instance_identifier = params['dr_rds_name']
    
    try:
        # Get the original DR instance configuration before deleting
        try:
            original_config = dr_rds_client.describe_db_instances(
                DBInstanceIdentifier=dr_instance_identifier
            )['DBInstances'][0]
            security_group_ids = [sg['VpcSecurityGroupId'] for sg in original_config['VpcSecurityGroups']]
            subnet_group_name = original_config['DBSubnetGroup']['DBSubnetGroupName']
        except dr_rds_client.exceptions.DBInstanceNotFoundFault:
            print(f"DB instance {dr_instance_identifier} not found, will use default configuration")
            security_group_ids = []
            subnet_group_name = None
        except Exception as e:
            print(f"Warning: Could not fetch original config: {str(e)}")
            security_group_ids = []
            subnet_group_name = None

        # First try to delete the existing instance if it exists
        try:
            dr_rds_client.delete_db_instance(
                DBInstanceIdentifier=dr_instance_identifier,
                SkipFinalSnapshot=True,
                DeleteAutomatedBackups=True
            )
            
            waiter = dr_rds_client.get_waiter('db_instance_deleted')
            waiter.wait(
                DBInstanceIdentifier=dr_instance_identifier,
                WaiterConfig={'Delay': 30, 'MaxAttempts': 60}
            )
        except dr_rds_client.exceptions.DBInstanceNotFoundFault:
            print(f"DB instance {dr_instance_identifier} does not exist, proceeding with creation...")
        
        # Create the read replica with original configuration
        replica_params = {
            'DBInstanceIdentifier': dr_instance_identifier,
            'SourceDBInstanceIdentifier': f"arn:aws:rds:{params['primary_region']}:{params['account_id']}:db:{params['primary_rds_name']}",
            'MultiAZ': True,
            'PubliclyAccessible': False,
        }

        if security_group_ids:
            replica_params['VpcSecurityGroupIds'] = security_group_ids
        if subnet_group_name:
            replica_params['DBSubnetGroupName'] = subnet_group_name

        dr_rds_client.create_db_instance_read_replica(**replica_params)
        
        return {"status": "Read replica creation initiated"}
        
    except Exception as e:
        raise Exception(f"Failed to create read replica: {str(e)}")

def update_asg(params):
    primary_ec2_client = boto3.client('ec2', region_name=params['primary_region'])
    primary_asg_client = boto3.client('autoscaling', region_name=params['primary_region'])
    dr_asg_client = boto3.client('autoscaling', region_name=params['dr_region'])
    primary_rds_client = boto3.client('rds', region_name=params['primary_region'])
    ssm_client = boto3.client('ssm', region_name=params['primary_region'])

    primary_db_identifier = params['primary_rds_name']

    # Get the new endpoint
    response = primary_rds_client.describe_db_instances(
        DBInstanceIdentifier=primary_db_identifier
    )
    new_endpoint = response['DBInstances'][0]['Endpoint']['Address']

    # Update the SSM parameter with the new endpoint
    ssm_client.put_parameter(
        Name='primary_rds_name',
        Value=new_endpoint,
        Type='String',
        Overwrite=True
    )
    
    # Get latest AMI
    images = primary_ec2_client.describe_images(
        Filters=[
            {
                'Name': 'name',
                'Values': [f"AMI-{params['asg_name']}-*"]
            },
            {
                'Name': 'state',
                'Values': ['available']
            }
        ],
        Owners=['self']
    )
    
    if not images['Images']:
        raise Exception("No AMIs found in primary region")
    
    latest_ami = sorted(images['Images'], 
                       key=lambda x: x['CreationDate'],
                       reverse=True)[0]
    
    # Update primary ASG
    asg_response = primary_asg_client.describe_auto_scaling_groups(
        AutoScalingGroupNames=[params['asg_name']]
    )
    launch_template_id = asg_response['AutoScalingGroups'][0]['LaunchTemplate']['LaunchTemplateId']
    
    primary_ec2_client.create_launch_template_version(
        LaunchTemplateId=launch_template_id,
        SourceVersion='$Latest',
        LaunchTemplateData={
            'ImageId': latest_ami['ImageId']
        }
    )
    
    primary_asg_client.update_auto_scaling_group(
        AutoScalingGroupName=params['asg_name'],
        DesiredCapacity=1,
        MinSize=1,
        MaxSize=2,
        LaunchTemplate={
            'LaunchTemplateId': launch_template_id,
            'Version': '$Latest'
        }
    )
    
    # Scale down DR ASG
    dr_asg_client.update_auto_scaling_group(
        AutoScalingGroupName=params['asg_name'],
        DesiredCapacity=0,
        MinSize=0,
        MaxSize=2
    )
    
    return {"status": "ASG configuration updated"}

def disable_ssm_sync(params):
    events_client = boto3.client('events', region_name=params['dr_region'])
    # lambda_client = boto3.client('lambda', region_name=params['dr_region'])
    
    rule_name = f"ssm-sync-rule-dr"
    # function_name = f"{params['environment']}-ssm-sync-lambda-dr"
    
    # # Remove Lambda permission for EventBridge
    # try:
    #     lambda_client.remove_permission(
    #         FunctionName=function_name,
    #         StatementId=f"Allow-EventBridge-Invoke-{rule_name}"
    #     )
    # except Exception as e:
    #     print(f"Warning: Could not remove Lambda permission: {str(e)}")
    
    # Disable the rule
    try:
        events_client.disable_rule(
            Name=rule_name
        )
    except Exception as e:
        print(f"Warning: Could not disable rule: {str(e)}")
    
    return {"status": "SSM sync disabled in DR region"}

def lambda_handler(event, context):
    operation = event['operation']
    params = event['params']
    
    operations = {
        'S3_FAILBACK': lambda: handle_s3_failback(params),
        'CREATE_SNAPSHOT': lambda: create_snapshot(params),
        'CHECK_SNAPSHOT': lambda: check_snapshot_status(params, event['snapshot']),
        'COPY_SNAPSHOT': lambda: copy_snapshot(params, event['snapshot']),
        'CHECK_COPIED_SNAPSHOT': lambda: check_copied_snapshot_status(params, event['snapshot']),
        'RESTORE_DB': lambda: restore_db(params, event['copied_snapshot']),
        'CHECK_DB_STATUS': lambda: check_db_status(params, event['db_info']),
        'CREATE_READ_REPLICA': lambda: create_read_replica(params),
        'UPDATE_ASG': lambda: update_asg(params),
        'DISABLE_SSM_SYNC': lambda: disable_ssm_sync(params)
    }
    
    return operations[operation]()
