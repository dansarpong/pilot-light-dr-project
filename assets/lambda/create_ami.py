import boto3
from datetime import datetime

def get_ssm_parameter(ssm_client, param_name):
    response = ssm_client.get_parameter(Name=param_name)
    return response['Parameter']['Value']

def wait_for_ami_available(ec2_client, image_id):
    print(f"Waiting for AMI {image_id} to become available...")
    waiter = ec2_client.get_waiter('image_available')
    waiter.wait(
        ImageIds=[image_id],
        WaiterConfig={'Delay': 15, 'MaxAttempts': 40}  # Max wait time: 10 minutes
    )

def lambda_handler(event, context):
    # Get SSM client
    ssm_client = boto3.client('ssm')
    
    # Fetch parameters from SSM
    asg_name = get_ssm_parameter(ssm_client, "asg_name")
    dest_region = get_ssm_parameter(ssm_client, "dr_region")
    current_region = get_ssm_parameter(ssm_client, "primary_region")
    
    ec2_client = boto3.client('ec2', region_name=current_region)
    asg_client = boto3.client('autoscaling', region_name=current_region)
    
    # Step 1: Get instance from ASG
    asg_response = asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name])
    instances = asg_response['AutoScalingGroups'][0]['Instances']
    
    if not instances:
        raise Exception(f"No instances found in Auto Scaling Group: {asg_name}")
    
    instance_id = instances[0]['InstanceId']
    print(f"Selected Instance ID from ASG: {instance_id}")
    
    # Step 2: Create AMI
    ami_name = f"AMI-{asg_name}-{datetime.utcnow().strftime('%Y%m%d-%H%M%S')}"
    image_response = ec2_client.create_image(
        InstanceId=instance_id,
        Name=ami_name,
        NoReboot=True
    )
    
    image_id = image_response['ImageId']
    print(f"Created AMI: {image_id}")
    
    # Wait for AMI to be available
    wait_for_ami_available(ec2_client, image_id)
    
    # Step 3: Copy to destination region
    dest_ec2 = boto3.client('ec2', region_name=dest_region)
    copy_response = dest_ec2.copy_image(
        Name=f"Copied-{ami_name}",
        SourceImageId=image_id,
        SourceRegion=current_region
    )
    
    print(f"Copied AMI to {dest_region}: {copy_response['ImageId']}")
    return {
        'statusCode': 200,
        'body': {
            'sourceImageId': image_id,
            'copiedImageId': copy_response['ImageId']
        }
    }
