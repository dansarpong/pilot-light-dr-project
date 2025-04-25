# IAM
# Lambda Create AMI Role
module "lambda_create_ami_role" {
  source = "../../modules/iam"

  environment         = var.environment
  name                = "${var.create_ami_name}-role"
  assume_role_service = "lambda.amazonaws.com"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  policies = {
    create_ami  = file("${path.module}/../../assets/policies/lambda_create_ami.json")
    ssm_access  = file("${path.module}/../../assets/policies/ssm_fullaccess.json")
    lambda_logs = file("${path.module}/../../assets/policies/lambda_logs.json")
  }
}

# Lambda SSM Sync Role
module "lambda_ssm_sync_role" {
  source = "../../modules/iam"

  environment         = var.environment
  name                = "${var.ssm_sync_name}-role"
  assume_role_service = "lambda.amazonaws.com"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  policies = {
    ssm_access  = file("${path.module}/../../assets/policies/ssm_fullaccess.json")
    lambda_logs = file("${path.module}/../../assets/policies/lambda_logs.json")
  }
}

# Lambda Failover Role
module "lambda_failover_role" {
  source = "../../modules/iam"

  environment         = var.environment
  name                = "${var.environment}-failover-role"
  assume_role_service = "lambda.amazonaws.com"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  policies = {
    failover    = file("${path.module}/../../assets/policies/lambda_failover.json")
    ssm_access  = file("${path.module}/../../assets/policies/ssm_fullaccess.json")
    lambda_logs = file("${path.module}/../../assets/policies/lambda_logs.json")
  }
}

# Lambda Failback Role
module "lambda_failback_role" {
  source = "../../modules/iam"

  environment         = var.environment
  name                = "${var.environment}-failback-role"
  assume_role_service = "lambda.amazonaws.com"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  policies = {
    failback    = file("${path.module}/../../assets/policies/lambda_failback.json")
    ssm_access  = file("${path.module}/../../assets/policies/ssm_fullaccess.json")
    lambda_logs = file("${path.module}/../../assets/policies/lambda_logs.json")
  }
}

# S3 Replication Role
module "iam_s3_replication_role" {
  source = "../../modules/iam"

  environment         = var.environment
  name                = var.s3_replication_role_name
  assume_role_service = "s3.amazonaws.com"

  policies = {
    replication = templatefile("${path.module}/../../assets/policies/s3_replication.json", {
      source_bucket_arn      = module.s3_primary.bucket_arn
      destination_bucket_arn = module.s3_dr.bucket_arn
    })
  }
}

# SFN Failover Role
module "step_functions_failover_role" {
  source = "../../modules/iam"

  environment         = var.environment
  name                = "${var.environment}-failover-sfn-role"
  assume_role_service = "states.amazonaws.com"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
  ]

  policies = {
    failover   = file("${path.module}/../../assets/policies/lambda_failover.json")
    ssm_access = file("${path.module}/../../assets/policies/ssm_fullaccess.json")
    sfn_access = file("${path.module}/../../assets/policies/sfn_access.json")
  }
}

# SFN Failback Role
module "step_functions_failback_role" {
  source = "../../modules/iam"

  environment         = var.environment
  name                = "${var.environment}-failback-sfn-role"
  assume_role_service = "states.amazonaws.com"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
  ]

  policies = {
    failback   = file("${path.module}/../../assets/policies/lambda_failback.json")
    ssm_access = file("${path.module}/../../assets/policies/ssm_fullaccess.json")
    sfn_access = file("${path.module}/../../assets/policies/sfn_access.json")
  }
}

# EC2 Instance Role
module "ec2_instance_role" {
  source = "../../modules/iam"

  environment             = var.environment
  name                    = "${var.environment}-ec2-instance-role"
  assume_role_service     = "ec2.amazonaws.com"
  create_instance_profile = true

  policies = {
    instance_profile = file("${path.module}/../../assets/policies/ec2_instance.json")
    ssm_access = file("${path.module}/../../assets/policies/ssm_fullaccess.json")
    s3_access  = file("${path.module}/../../assets/policies/s3_access.json")
  }
}
