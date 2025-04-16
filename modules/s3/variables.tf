variable "region" {
  description = "Region for the primary S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "Base name for the S3 bucket"
  type        = string
}

variable "dr_region" {
  description = "Disaster recovery region"
  type        = string
}

variable "versioning_enabled" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "Lifecycle configuration rules"
  type = list(object({
    id       = string
    prefix   = string
    enabled  = bool
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

variable "replication_role_arn" {
  description = "ARN of IAM role for cross-region replication"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
