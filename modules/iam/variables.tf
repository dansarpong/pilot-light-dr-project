variable "name" {
  description = "Name suffix for IAM role"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "assume_role_service" {
  description = "AWS service to assume role"
  type        = string
}

variable "policies" {
  description = "Map of policy names to policy documents"
  type = map(any)
  default = {}
}

variable "managed_policy_arns" {
  description = "List of AWS managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "create_instance_profile" {
  description = "Whether to create an instance profile"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
