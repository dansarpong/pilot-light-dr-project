variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
}

variable "key_pair_name" {
  description = "Key pair for SSH access"
  type        = string
  default = ""
}

variable "security_group_id" {
  description = "Security group ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "user_data_path" {
  description = "Path to user data script"
  type        = string
  default     = "user_data.sh"
}

variable "desired_capacity" {
  description = "ASG desired instance count"
  type        = number
}

variable "min_size" {
  description = "ASG minimum instance count"
  type        = number
}

variable "max_size" {
  description = "ASG maximum instance count"
  type        = number
}

variable "tags" {
  description = "Additional tags for ASG resources"
  type        = map(string)
  default     = {}
}
