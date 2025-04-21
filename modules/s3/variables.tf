variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "Base name for the S3 bucket"
  type        = string
  default     = ""
}

variable "versioning_enabled" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "Lifecycle configuration rules"
  type = list(object({
    id      = string
    prefix  = string
    enabled = bool
    transition = object({
      days          = number
      storage_class = string
    })
    expiration = object({
      days = number
    })
  }))
  default = []
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "is_dr" {
  description = "Whether this is a DR bucket"
  type        = bool
  default     = false
}

variable "destination_bucket_arn" {
  description = "ARN of the destination bucket for replication"
  type        = string
  default     = ""
}

variable "replication_role_arn" {
  description = "ARN of IAM role for cross-region replication"
  type        = string
  default     = ""
}
