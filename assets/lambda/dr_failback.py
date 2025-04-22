import boto3
import time

def get_ssm_parameter(ssm_client, param_name):
    response = ssm_client.get_parameter(Name=param_name)
    return response['Parameter']['Value']

def wait_for_snapshot(rds_client, snapshot_id):
    print(f"Waiting for snapshot {snapshot_id} to be available...")
    waiter = rds_client.get_waiter('db_snapshot_available')
    waiter.wait(
        DBSnapshotIdentifier=snapshot_id,
        WaiterConfig={'Delay': 30, 'MaxAttempts': 60}  # Max wait time: 30 minutes
    )

def wait_for_db_instance(rds_client, db_instance_id):
    print(f"Waiting for DB instance {db_instance_id} to be available...")
    waiter = rds_client.get_waiter('db_instance_available')
    waiter.wait(
        DBInstanceIdentifier=db_instance_id,
        WaiterConfig={'Delay': 30, 'MaxAttempts': 60}  # Max wait time: 30 minutes
    )

def lambda_handler(event, context):
    # Get SSM client
    ssm_client = boto3.client('ssm')
    
    # Fetch parameters from SSM
    asg_name = get_ssm_parameter(ssm_client, "asg_name")
    dr_region = get_ssm_parameter(ssm_client, "dr_region")
    primary_region = get_ssm_parameter(ssm_client, "primary_region")
    dr_rds_instance_id = get_ssm_parameter(ssm_client, "dr_rds_instance_id")
    primary_rds_instance_id = get_ssm_parameter(ssm_client, "primary_rds_instance_id")
    
    # Initialize clients
    dr_rds_client = boto3.client('rds', region_name=dr_region)
    primary_rds_client = boto3.client('rds', region_name=primary_region)
    primary_asg_client = boto3.client('autoscaling', region_name=primary_region)
    primary_ec2_client = boto3.client('ec2', region_name=primary_region)
    dr_asg_client = boto3.client('autoscaling', region_name=dr_region)
    
    try:
        # Step 1: Create snapshot of DR database
        timestamp = time.strftime('%Y-%m-%d-%H-%M-%S')
        snapshot_id = f"failback-snapshot-{timestamp}"
        print(f"Creating snapshot {snapshot_id} in DR region...")
        
        dr_rds_client.create_db_snapshot(
            DBSnapshotIdentifier=snapshot_id,
            DBInstanceIdentifier=dr_rds_instance_id
        )
        
        # Wait for snapshot to be available
        wait_for_snapshot(dr_rds_client, snapshot_id)
        
        # Step 2: Copy snapshot to primary region
        primary_snapshot_id = f"copied-{snapshot_id}"
        print(f"Copying snapshot to primary region as {primary_snapshot_id}...")
        
        primary_rds_client.copy_db_snapshot(
            SourceDBSnapshotIdentifier=f"arn:aws:rds:{dr_region}:{context.invoked_function_arn.split(':')[4]}:snapshot:{snapshot_id}",
            TargetDBSnapshotIdentifier=primary_snapshot_id,
            SourceRegion=dr_region
        )
        
        # Wait for copied snapshot to be available
        wait_for_snapshot(primary_rds_client, primary_snapshot_id)
        
        # Step 3: Restore DB instance in primary region from snapshot
        print("Restoring DB instance in primary region from snapshot...")
        primary_rds_client.restore_db_snapshot(
            DBInstanceIdentifier=primary_rds_instance_id,
            DBSnapshotIdentifier=primary_snapshot_id
        )
        
        # Wait for primary DB to be available
        wait_for_db_instance(primary_rds_client, primary_rds_instance_id)
        
        # Step 4: Create read replica back to DR region
        print("Creating read replica in DR region...")
        dr_rds_client.create_db_instance_read_replica(
            DBInstanceIdentifier=dr_rds_instance_id,
            SourceDBInstanceIdentifier=f"arn:aws:rds:{primary_region}:{context.invoked_function_arn.split(':')[4]}:db:{primary_rds_instance_id}",
            AvailabilityZone='auto'
        )
        
        # Step 5: Get the latest AMI from primary region
        images = primary_ec2_client.describe_images(
            Filters=[
                {
                    'Name': 'name',
                    'Values': [f"AMI-{asg_name}-*"]
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
        
        # Step 6: Update primary ASG launch template with latest AMI
        asg_response = primary_asg_client.describe_auto_scaling_groups(
            AutoScalingGroupNames=[asg_name]
        )
        launch_template_id = asg_response['AutoScalingGroups'][0]['LaunchTemplate']['LaunchTemplateId']
        
        primary_ec2_client.create_launch_template_version(
            LaunchTemplateId=launch_template_id,
            SourceVersion='$Latest',
            LaunchTemplateData={
                'ImageId': latest_ami['ImageId']
            }
        )
        
        # Step 7: Scale up primary ASG
        print("Scaling up primary ASG...")
        primary_asg_client.update_auto_scaling_group(
            AutoScalingGroupName=asg_name,
            DesiredCapacity=2,
            MinSize=1,
            MaxSize=2,
            LaunchTemplate={
                'LaunchTemplateId': launch_template_id,
                'Version': '$Latest'
            }
        )
        
        # Step 8: Scale down DR ASG
        print("Scaling down DR ASG...")
        dr_asg_client.update_auto_scaling_group(
            AutoScalingGroupName=f"dr-{asg_name}",
            DesiredCapacity=0,
            MinSize=0,
            MaxSize=2
        )
        
        return {
            'statusCode': 200,
            'body': 'DR failback completed successfully'
        }
        
    except Exception as e:
        print(f"Error during failback: {str(e)}")
        raise

