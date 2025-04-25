import boto3
import os
import json

def lambda_handler(event, context):
    """
    Synchronizes SSM parameters between two regions based on the provided event.
    Returns a success message or an error message.
    """
    # Log the event and context for debugging
    print("Received event:", json.dumps(event, indent=2))
    print("Context:", context)

    source_region = context.invoked_function_arn.split(':')[3]
    target_region = os.environ['TARGET_REGION']

    source_ssm = boto3.client('ssm', region_name=source_region)
    target_ssm = boto3.client('ssm', region_name=target_region)

    # Get the changed parameter details from the event
    detail = event['detail']
    operation = detail['eventName']
    parameter_name = detail['requestParameters']['name']

    try:
        if operation in ['PutParameter']:
            # Get parameter from source region
            response = source_ssm.get_parameter(
                Name=parameter_name,
                WithDecryption=True
            )
            parameter = response['Parameter']

            # Create or update parameter in target region
            target_ssm.put_parameter(
                Name=parameter['Name'],
                Value=parameter['Value'],
                Type=parameter['Type'],
                Overwrite=True
            )

            print(f"Successfully synchronized parameter {parameter_name} to {target_region}")

        elif operation in ['DeleteParameter', 'DeleteParameters']:
            # Delete parameter in target region
            target_ssm.delete_parameter(
                Name=parameter_name
            )
            print(f"Successfully deleted parameter {parameter_name} in {target_region}")

        return {
            'statusCode': 200,
            'body': json.dumps(f'Parameter {parameter_name} successfully {operation.lower()}d in {target_region}')
        }

    except Exception as e:
        print(f"Error synchronizing parameter: {str(e)}")
        raise
