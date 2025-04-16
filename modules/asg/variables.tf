variable "region" {
  description = "Region for EC2 instances"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0f0c3baa60262d5b9"  # Ubuntu 22.04 LTS
}

variable "instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "ASG desired instance count"
  type        = number
  default     = 0  # Pilot Light default
}

variable "min_size" {
  description = "ASG minimum instance count"
  type        = number
  default     = 0
}

variable "max_size" {
  description = "ASG maximum instance count"
  type        = number
  default     = 2
}

variable "key_pair_name" {
  description = "Key pair for SSH access"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs from VPC module"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID from VPC module"
  type        = string
}

variable "user_data_path" {
  description = "Path to user data script"
  type        = string
  default     = "user_data.sh"
}
