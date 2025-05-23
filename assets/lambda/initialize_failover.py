import boto3

def lambda_handler(event, context):
    """
    Initializes parameters for failover operations.
    Returns a dictionary of parameters.
    """
    ssm_client = boto3.client('ssm')
    
    params = {
        "asg_name": ssm_client.get_parameter(Name="asg_name")['Parameter']['Value'],
        "dr_region": ssm_client.get_parameter(Name="dr_region")['Parameter']['Value'],
        "primary_region": ssm_client.get_parameter(Name="primary_region")['Parameter']['Value'],
        "dr_rds_name": ssm_client.get_parameter(Name="dr_rds_name")['Parameter']['Value'],
        "primary_rds_name": ssm_client.get_parameter(Name="primary_rds_name")['Parameter']['Value'],
        "primary_bucket": ssm_client.get_parameter(Name="primary_bucket_name")['Parameter']['Value'],
        "dr_bucket": ssm_client.get_parameter(Name="dr_bucket_name")['Parameter']['Value'],
        "replication_role_arn": ssm_client.get_parameter(Name="s3_replication_role_arn")['Parameter']['Value'],
    }
    
    return params
