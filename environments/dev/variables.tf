variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "primary_region" {
  description = "Primary region name"
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "DR region name"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "Base CIDR block for the VPCs"
  type        = string
  default     = "10.0.0.0/16"
}

variable "primary_bucket_name" {
  description = "Base name for the primary S3 bucket"
  type        = string
  default     = "primary-bucket"
}

variable "dr_bucket_name" {
  description = "Base name for the DR S3 bucket"
  type        = string
  default     = "pilot-bucket"
}

variable "s3_replication_role_name" {
  description = "Name suffix for the S3 replication IAM role"
  type        = string
  default     = "s3-replication-role"
}

variable "asg_sg_name" {
  description = "Name suffix for the ASG security group"
  type        = string
  default     = "asg-sg"
}

variable "lb_sg_name" {
  description = "Name suffix for the load balancer security group"
  type        = string
  default     = "lb-sg"
}

variable "rds_sg_name" {
  description = "Name suffix for the RDS security group"
  type        = string
  default     = "rds-sg"
}

variable "rds_db_name" {
  description = "Name for the RDS database"
  type        = string
  default     = "mydb"
}

variable "rds_username" {
  description = "Username for the RDS database"
  type        = string
  default     = "admin"
}

variable "rds_password" {
  description = "Password for the RDS database"
  type        = string
  sensitive   = true
}

variable "primary_ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0f0c3baa60262d5b9" # Ubuntu 22.04
}

variable "dr_ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0f9de6e2d2f067fca" # Ubuntu 22.04
}

variable "instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
  default     = "t2.micro"
}

variable "desired_capacity" {
  description = "ASG desired instance count"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "ASG minimum instance count"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "ASG maximum instance count"
  type        = number
  default     = 2
}

variable "create_ami_name" {
  description = "Name for the create AMI resources"
  type        = string
  default     = "create-ami"
}

variable "ssm_sync_name" {
  description = "Name for the SSM sync resources"
  type        = string
  default     = "ssm-sync"
}

variable "ssm_sync_event_pattern" {
  description = "Event pattern for the SSM sync EventBridge rule"
  type = object({
    source      = list(string)
    detail-type = list(string)
    detail = object({
      eventSource = list(string)
      eventName   = list(string)
    })
  })
  default = {
    source      = ["aws.ssm"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["ssm.amazonaws.com"]
      eventName   = ["PutParameter", "DeleteParameter", "DeleteParameters"]
    }
  }
}

variable "ami_eventbridge_schedule" {
  description = "Schedule expression for the AMI EventBridge rule"
  type        = string
  default     = "cron(0 0 * * ? *)"
}

variable "lambda_runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.8"
}

variable "lambda_timeout" {
  description = "Timeout for the Lambda function"
  type        = number
  default     = 900
}

variable "create_ami_handler" {
  description = "Handler for the Lambda function"
  type        = string
  default     = "create_ami.lambda_handler"
}

variable "ssm_sync_handler" {
  description = "Handler for the Lambda function"
  type        = string
  default     = "ssm_sync.lambda_handler"
}

variable "dr_failover_handler" {
  description = "Handler for the Lambda function"
  type        = string
  default     = "dr_failover.lambda_handler"
}

variable "dr_failback_handler" {
  description = "Handler for the failback Lambda function"
  type        = string
  default     = "dr_failback.lambda_handler"
}
