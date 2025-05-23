variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cidr_block" {
  description = "Base CIDR block for the VPC"
  type        = string
}
