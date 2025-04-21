# VPC
module "vpc_primary" {
  source = "../../modules/vpc"

  providers = {
    aws = aws.primary
  }

  cidr_block = var.vpc_cidr_block
}

# ELB
# module "elb_primary" {
#   source = "../../modules/elb"

#   providers = {
#     aws = aws.primary
#   }

#   environment       = var.environment
#   name              = var.elb_name
#   security_group_id = module.sg_elb_primary.security_group_id
#   subnet_ids        = module.vpc_primary.public_subnets

#   health_check_target = "HTTP:80/"

#   tags = {
#     Region = "primary"
#   }
# }

# ELB SG
module "sg_elb_primary" {
  source = "../../modules/security-group"

  providers = {
    aws = aws.primary
  }

  vpc_id      = module.vpc_primary.vpc_id
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

# ASG
module "asg_primary" {
  source = "../../modules/asg"

  providers = {
    aws = aws.primary
  }

  environment       = var.environment
  ami_id            = var.primary_ami_id
  instance_type     = var.instance_type
  security_group_id = module.sg_asg_primary.security_group_id
  subnet_ids        = module.vpc_primary.private_subnets
  desired_capacity  = var.desired_capacity
  min_size          = var.min_size
  max_size          = var.max_size

  user_data_path = "${path.module}/../../assets/user_data.sh"
}

# ASG SG
module "sg_asg_primary" {
  source = "../../modules/security-group"

  providers = {
    aws = aws.primary
  }

  vpc_id      = module.vpc_primary.vpc_id
  name        = var.asg_sg_name
  description = "Security group for critical application instances"

  ingress_rules = [
    {
      description     = "Allow HTTP from load balancer"
      protocol        = "tcp"
      from_port       = 80
      to_port         = 80
      cidr_blocks     = []
      security_groups = [module.sg_elb_primary.security_group_id] #module.elb_primary.elb_sg_id
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

# RDS
module "rds_primary" {
  source = "../../modules/rds"

  providers = {
    aws = aws.primary
  }

  environment        = var.environment
  db_name            = var.rds_db_name
  username           = var.rds_username
  password           = var.rds_password
  subnet_ids         = module.vpc_primary.private_subnets
  security_group_ids = [module.sg_rds_primary.security_group_id]
}

# RDS SG
module "sg_rds_primary" {
  source = "../../modules/security-group"

  providers = {
    aws = aws.primary
  }

  vpc_id      = module.vpc_primary.vpc_id
  name        = var.rds_sg_name
  description = "Security group for RDS instance"

  ingress_rules = [
    {
      description     = "Allow MySQL from ASG"
      protocol        = "tcp"
      from_port       = 3306
      to_port         = 3306
      cidr_blocks     = []
      security_groups = [module.sg_asg_primary.security_group_id]
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

# S3
module "s3_primary" {
  source = "../../modules/s3"

  providers = {
    aws = aws.primary
  }

  bucket_name            = var.primary_bucket_name
  destination_bucket_arn = module.s3_dr.bucket_arn
  replication_role_arn   = module.iam_s3_replication_role.role_arn

  lifecycle_rules = [
    {
      id      = "archive-infrequent-access"
      enabled = true
      prefix  = ""
      transition = {
        days          = 30
        storage_class = "STANDARD_IA"
      }
      expiration = {
        days = 0 # No expiration for this rule
      }
    },
    {
      id      = "archive-glacier"
      enabled = true
      prefix  = ""
      transition = {
        days          = 90
        storage_class = "GLACIER"
      }
      expiration = {
        days = 0 # No expiration for this rule
      }
    },
    {
      id      = "archive-deep-glacier"
      enabled = true
      prefix  = ""
      transition = {
        days          = 180
        storage_class = "DEEP_ARCHIVE"
      }
      expiration = {
        days = 0 # No expiration for this rule
      }
    },
    {
      id      = "delete-old-data"
      enabled = true
      prefix  = "logs/" # Only apply deletion to logs directory
      transition = {
        days          = 0 # No transition for this rule
        storage_class = ""
      }
      expiration = {
        days = 365 # Delete logs after 1 year
      }
    }
  ]
}

# EventBridge Create AMI
module "eventbridge_create_ami_schedule" {
  source = "../../modules/eventbridge"

  providers = {
    aws = aws.primary
  }

  name                = "${var.create_ami_name}-schedule"
  description         = "Schedule to create AMI"
  schedule_expression = var.ami_eventbridge_schedule
  arn                 = module.lambda_create_ami.function_arn
  target_id           = "${var.create_ami_name}-schedule-target"
}

# Lambda Create AMI
module "lambda_create_ami" {
  source = "../../modules/lambda"

  providers = {
    aws = aws.primary
  }

  function_name = "${var.create_ami_name}-lambda"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  handler       = var.create_ami_handler
  role_arn      = module.lambda_create_ami_role.role_arn
  local_path    = data.archive_file.create_ami_lambda.output_path
}

# SSM Parameter Store
module "ssm_parameters" {
  source = "../../modules/ssm-parameter"

  providers = {
    aws = aws.primary
  }

  parameters = {
    "asg_name" = {
      type        = "String"
      value       = module.asg_primary.asg_name
      description = "Name of the Auto Scaling Group"
    },
    "dr_region" = {
      type        = "String"
      value       = var.dr_region
      description = "Name of the DR region"
    },
    "primary_region" = {
      type        = "String"
      value       = var.primary_region
      description = "Name of the primary region"
    },
    "dr_rds_instance_id" = {
      type        = "String"
      value       = module.rds_dr.db_instance_id
      description = "ID of the DR RDS instance"
    },
    "primary_rds_instance_id" = {
      type        = "String"
      value       = module.rds_primary.db_instance_id
      description = "ID of the primary RDS instance"
    }
  }
}
