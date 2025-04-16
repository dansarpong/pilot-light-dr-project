variable "name" {
  description = "Name suffix for IAM resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "assume_role_service" {
  description = "AWS service to assume role (e.g., ec2.amazonaws.com)"
  type        = string
}

variable "policies" {
  description = "Map of policy names to policy documents"
  type = map(string)
  default = {}
}

variable "managed_policy_arns" {
  description = "List of AWS managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
