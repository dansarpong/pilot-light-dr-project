# DR VPC
module "vpc_dr" {
  source = "../../modules/vpc"

  providers = {
    aws = aws.dr
  }


  cidr_block = var.vpc_cidr_block
}

# DR ELB
module "elb_app_dr" {
  source = "../../modules/elb"

  providers = {
    aws = aws.dr
  }

  environment       = var.environment
  name              = var.elb_name
  security_group_id = module.sg_elb_dr.security_group_id
  subnet_ids        = module.vpc_dr.public_subnets

  health_check_target = "HTTP:80/"

  tags = {
    Region = "dr"
  }
}

# DR ELB SG
module "sg_elb_dr" {
  source = "../../modules/security-group"

  providers = {
    aws = aws.dr
  }

  vpc_id      = module.vpc_dr.vpc_id
  name        = var.elb_sg_name
  description = "Security group for load balancer"

  ingress_rules = [
    {
      description     = "Allow HTTP from anywhere"
      protocol        = "tcp"
      from_port       = 80
      to_port         = 80
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  ]

  egress_rules = [
    {
      description     = "Allow all outbound traffic"
      protocol        = "-1"
      from_port       = 0
      to_port         = 0
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  ]
}

# DR ASG
module "asg_dr" {
  source = "../../modules/asg"

  providers = {
    aws = aws.dr
  }

  environment       = var.environment
  ami_id            = var.dr_ami_id
  instance_type     = var.instance_type
  security_group_id = module.sg_asg_dr.security_group_id
  subnet_ids        = module.vpc_dr.private_subnets
  desired_capacity  = 0
  min_size          = 0
  max_size          = var.max_size
}

# DR ASG SG
module "sg_asg_dr" {
  source = "../../modules/security-group"

  providers = {
    aws = aws.dr
  }

  vpc_id      = module.vpc_dr.vpc_id
  name        = var.asg_sg_name
  description = "Security group for critical application instances"

  ingress_rules = [
    {
      description     = "Allow HTTP from load balancer"
      protocol        = "tcp"
      from_port       = 80
      to_port         = 80
      security_groups = [module.elb_app_dr.elb_sg_id]
      cidr_blocks     = []
    }
  ]

  egress_rules = [
    {
      description     = "Allow all outbound traffic"
      protocol        = "-1"
      from_port       = 0
      to_port         = 0
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  ]
}

# DR RDS
module "rds_dr" {
  source = "../../modules/rds"

  providers = {
    aws = aws.dr
  }

  is_dr              = true
  password           = null
  environment        = var.environment
  subnet_ids         = module.vpc_dr.private_subnets
  security_group_ids = [module.sg_rds_dr.security_group_id]
  source_db_arn      = module.rds_primary.db_arn
}

# DR RDS SG
module "sg_rds_dr" {
  source = "../../modules/security-group"

  providers = {
    aws = aws.dr
  }

  vpc_id      = module.vpc_dr.vpc_id
  name        = var.rds_sg_name
  description = "Security group for RDS instance"

  ingress_rules = [
    {
      description     = "Allow MySQL from ASG"
      protocol        = "tcp"
      from_port       = 3306
      to_port         = 3306
      cidr_blocks     = []
      security_groups = [module.sg_asg_dr.security_group_id]
    }
  ]

  egress_rules = [
    {
      description     = "Allow all outbound traffic"
      protocol        = "-1"
      from_port       = 0
      to_port         = 0
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  ]
}

# DR S3
module "s3_dr" {
  source = "../../modules/s3"

  providers = {
    aws = aws.dr
  }
  is_dr       = true
  bucket_name = var.dr_bucket_name
}

# Lambda
# DR Lambda Failover
module "lambda_dr_failover" {
  source = "../../modules/lambda"

  providers = {
    aws = aws.dr
  }

  function_name = "${var.environment}-dr-failover"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  handler       = var.dr_failover_handler
  role_arn      = module.lambda_failover_role.role_arn
  local_path    = data.archive_file.dr_failover_lambda.output_path
}

# DR Lambda Failback
module "lambda_dr_failback" {
  source = "../../modules/lambda"

  providers = {
    aws = aws.dr
  }

  function_name = "${var.environment}-dr-failback"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  handler       = var.dr_failback_handler
  role_arn      = module.lambda_failover_role.role_arn
  local_path    = data.archive_file.dr_failback_lambda.output_path
}

# EventBridge
# DR EventBridge Failover
module "eventbridge_dr_failover" {
  source = "../../modules/eventbridge"

  providers = {
    aws = aws.dr
  }

  name       = "${var.environment}-dr-failover"
  event_type = "health"
  event_pattern = jsonencode({
    "source" : ["aws.health"],
    "detail-type" : ["AWS Health Event"],
    "detail" : {
      "services" : ["EC2", "RDS", "S3", "Lambda"],
      "eventTypeCategories" : ["issue"],
      "eventStatusCodes" : ["open"],
      "regions" : ["${var.primary_region}"]
    }
  })
  arn       = module.lambda_dr_failover.function_arn
  target_id = "${var.environment}-dr-failover-target"
}

# DR EventBridge Failback
module "eventbridge_dr_failback" {
  source = "../../modules/eventbridge"

  providers = {
    aws = aws.dr
  }

  name       = "${var.environment}-dr-failback"
  event_type = "health"
  event_pattern = jsonencode({
    "source" : ["aws.health"],
    "detail-type" : ["AWS Health Event"],
    "detail" : {
      "services" : ["EC2", "RDS", "S3", "Lambda"],
      "eventTypeCategories" : ["issue"],
      "eventStatusCodes" : ["closed"],
      "regions" : ["${var.primary_region}"]
    }
  })
  arn       = module.lambda_dr_failback.function_arn
  target_id = "${var.environment}-dr-failback-target"
}
