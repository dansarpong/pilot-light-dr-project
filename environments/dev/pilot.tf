# DR VPC
module "vpc_dr" {
  source = "../../modules/vpc"

  providers = {
    aws = aws.dr
  }

  cidr_block = var.vpc_cidr_block
}


# Security Groups
# DR lb SG
module "sg_lb_dr" {
  source = "../../modules/security-group"

  providers = {
    aws = aws.dr
  }

  vpc_id      = module.vpc_dr.vpc_id
  name        = var.lb_sg_name
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
      security_groups = [module.sg_lb_dr.security_group_id]
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


# DR lb
module "lb_app_dr" {
  source = "../../modules/lb"

  providers = {
    aws = aws.dr
  }

  name               = "${var.environment}-lb"
  security_group_ids = [module.sg_lb_dr.security_group_id]
  subnet_ids         = module.vpc_dr.public_subnets
  vpc_id             = module.vpc_dr.vpc_id
  target_type        = "instance"
}


# DR ASG
module "asg_dr" {
  source = "../../modules/asg"

  providers = {
    aws = aws.dr
  }

  environment               = var.environment
  ami_id                    = var.dr_ami_id
  instance_type             = var.instance_type
  iam_instance_profile_name = module.ec2_instance_role.instance_profile_name
  security_group_id         = module.sg_asg_dr.security_group_id
  subnet_ids                = module.vpc_dr.public_subnets
  desired_capacity          = 0
  min_size                  = 0
  max_size                  = var.max_size
  target_group_arns         = [module.lb_app_dr.target_group_arn]
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
# DR Initialize Failover
module "lambda_initialize_failover" {
  source = "../../modules/lambda"

  providers = {
    aws = aws.dr
  }

  function_name = "${var.environment}-initialize-failover"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  handler       = "initialize_failover.lambda_handler"
  role_arn      = module.lambda_failover_role.role_arn
  local_path    = data.archive_file.initialize_failover_lambda.output_path

  triggers = [
    {
      type   = "sfn_dr_failover"
      source = "states.amazonaws.com"
      config = {
        source_arn = module.dr_failover_step_function.state_machine_arn
      }
    }
  ]
}

# DR Failover Operations
module "lambda_failover_operations" {
  source = "../../modules/lambda"

  providers = {
    aws = aws.dr
  }

  function_name = "${var.environment}-failover-operations"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  handler       = "failover_operations.lambda_handler"
  role_arn      = module.lambda_failover_role.role_arn
  local_path    = data.archive_file.failover_operations_lambda.output_path

  triggers = [
    {
      type   = "sfn_dr_failover"
      source = "states.amazonaws.com"
      config = {
        source_arn = module.dr_failover_step_function.state_machine_arn
      }
    }
  ]
}


# DR Initialize Failback
module "lambda_initialize_failback" {
  source = "../../modules/lambda"

  providers = {
    aws = aws.dr
  }

  function_name = "${var.environment}-initialize-failback"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  handler       = "initialize_failback.lambda_handler"
  role_arn      = module.lambda_failback_role.role_arn
  local_path    = data.archive_file.initialize_failback_lambda.output_path

  triggers = [
    {
      type   = "sfn_dr_failback"
      source = "states.amazonaws.com"
      config = {
        source_arn = module.dr_failback_step_function.state_machine_arn
      }
    }
  ]
}

# DR Failback Operations
module "lambda_failback_operations" {
  source = "../../modules/lambda"

  providers = {
    aws = aws.dr
  }

  function_name = "${var.environment}-failback-operations"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  handler       = "failback_operations.lambda_handler"
  role_arn      = module.lambda_failback_role.role_arn
  local_path    = data.archive_file.failback_operations_lambda.output_path

  triggers = [
    {
      type   = "sfn_dr_failback"
      source = "states.amazonaws.com"
      config = {
        source_arn = module.dr_failback_step_function.state_machine_arn
      }
    }
  ]
}

# Backup SSM Sync Function
module "lambda_ssm_sync_dr" {
  source = "../../modules/lambda"

  providers = {
    aws = aws.dr
  }

  function_name = "${var.ssm_sync_name}-lambda-dr"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  handler       = var.ssm_sync_handler
  role_arn      = module.lambda_ssm_sync_role.role_arn
  local_path    = data.archive_file.ssm_sync_lambda.output_path

  triggers = [
    {
      type   = "eventbridge_ssm_sync_rule_dr"
      source = "events.amazonaws.com"
      config = {
        source_arn = module.eventbridge_ssm_sync_rule_dr.event_rule_arn
      }
    }
  ]

  environment_variables = {
    TARGET_REGION = var.primary_region
  }
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
  arn       = module.dr_failover_step_function.state_machine_arn
  target_id = "${var.environment}-dr-failover-target"
  role_arn  = module.step_functions_failover_role.role_arn
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
  arn       = module.dr_failback_step_function.state_machine_arn
  target_id = "${var.environment}-dr-failback-target"
  role_arn  = module.step_functions_failback_role.role_arn
}

# SSM Sync Rule (Disabled)
module "eventbridge_ssm_sync_rule_dr" {
  source = "../../modules/eventbridge"

  providers = {
    aws = aws.dr
  }

  name        = "${var.ssm_sync_name}-rule-dr"
  description = "Rule to synchronize SSM parameters (DR backup)"
  arn         = module.lambda_ssm_sync_dr.function_arn
  target_id   = "${var.ssm_sync_name}-rule-dr-target"
  event_type  = "health"

  event_pattern = jsonencode(var.ssm_sync_event_pattern)
  state         = "DISABLED"
}

# SFN
# DR Failback Step Function
module "dr_failback_step_function" {
  source = "../../modules/step_functions"

  providers = {
    aws = aws.dr
  }

  name     = "${var.environment}-dr-failback"
  role_arn = module.step_functions_failback_role.role_arn

  definition = templatefile("${path.module}/../../assets/sfn/dr_failback.json", {
    InitializeFailbackFunctionArn = module.lambda_initialize_failback.function_arn
    FailbackOperationsFunctionArn = module.lambda_failback_operations.function_arn
  })
}

# DR Failover Step Function
module "dr_failover_step_function" {
  source = "../../modules/step_functions"

  providers = {
    aws = aws.dr
  }

  name     = "${var.environment}-dr-failover"
  role_arn = module.step_functions_failover_role.role_arn

  definition = templatefile("${path.module}/../../assets/sfn/dr_failover.json", {
    InitializeFailoverFunctionArn = module.lambda_initialize_failover.function_arn
    FailoverOperationsFunctionArn = module.lambda_failover_operations.function_arn
  })
}
