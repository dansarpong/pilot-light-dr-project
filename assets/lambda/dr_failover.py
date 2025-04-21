import boto3

def get_ssm_parameter(ssm_client, param_name):
    response = ssm_client.get_parameter(Name=param_name)
    return response['Parameter']['Value']

def lambda_handler(event, context):
    # Get SSM client
    ssm_client = boto3.client('ssm')
    
    # Fetch parameters from SSM
    asg_name = get_ssm_parameter(ssm_client, "asg_name")
    region = get_ssm_parameter(ssm_client, "primary_region")
    rds_instance_id = get_ssm_parameter(ssm_client, "rds_instance_id")
    
    rds_client = boto3.client('rds', region_name=region)
    asg_client = boto3.client('autoscaling', region_name=region)
    ec2_client = boto3.client('ec2', region_name=region)
    
    try:
        # Step 1: Promote RDS read replica to primary
        print("Promoting RDS read replica to primary...")
        rds_client.promote_read_replica(
            DBInstanceIdentifier=rds_instance_id
        )
        
        # Step 2: Get the latest copied AMI
        print("Finding latest copied AMI...")
        images = ec2_client.describe_images(
            Filters=[
                {
                    'Name': 'name',
                    'Values': [f"Copied-AMI-{asg_name}-*"]
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
            
        # Sort by creation date to get the latest
        latest_ami = sorted(images['Images'], 
                          key=lambda x: x['CreationDate'],
                          reverse=True)[0]
        
        # Step 3: Update ASG launch template with new AMI
        print(f"Updating ASG with AMI: {latest_ami['ImageId']}")
        
        # Get current launch template
        asg_response = asg_client.describe_auto_scaling_groups(
            AutoScalingGroupNames=[asg_name]
        )
        launch_template_id = asg_response['AutoScalingGroups'][0]['LaunchTemplate']['LaunchTemplateId']
        
        # Create new launch template version
        ec2_client.create_launch_template_version(
            LaunchTemplateId=launch_template_id,
            SourceVersion='$Latest',
            LaunchTemplateData={
                'ImageId': latest_ami['ImageId']
            }
        )
        
        # Update ASG to use latest launch template version
        asg_client.update_auto_scaling_group(
            AutoScalingGroupName=asg_name,
            LaunchTemplate={
                'LaunchTemplateId': launch_template_id,
                'Version': '$Latest'
            }
        )
        
        # Step 4: Update ASG capacity
        print("Updating ASG capacity...")
        asg_client.update_auto_scaling_group(
            AutoScalingGroupName=asg_name,
            DesiredCapacity=2,
            MinSize=1,
            MaxSize=2
        )
        
        return {
            'statusCode': 200,
            'body': 'DR failover completed successfully'
        }
        
    except Exception as e:
        print(f"Error during failover: {str(e)}")
        raise