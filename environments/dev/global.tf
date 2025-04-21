# IAM
# Lambda Create AMI Role
module "lambda_create_ami_role" {
  source = "../../modules/iam"

  environment         = var.environment
  name                = "${var.create_ami_name}-role"
  assume_role_service = "lambda.amazonaws.com"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  policies = {
    create_ami = file("${path.module}/../../assets/policies/create_ami.json")
    ssm_access = file("${path.module}/../../assets/policies/ssm_access.json")
  }
}

# S3 Replication Role
module "iam_s3_replication_role" {
  source = "../../modules/iam"

  environment         = var.environment
  name                = var.s3_replication_role_name
  assume_role_service = "s3.amazonaws.com"

  policies = {
    replication = templatefile("${path.module}/../../assets/policies/s3-replication.json", {
      source_bucket_arn      = module.s3_primary.bucket_arn
      destination_bucket_arn = module.s3_dr.bucket_arn
    })
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
    failover   = file("${path.module}/../../assets/policies/lambda_failover.json")
    ssm_access = file("${path.module}/../../assets/policies/ssm_access.json")
  }
}
