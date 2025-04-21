variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "is_dr" {
  description = "Whether this is a DR RDS"
  type        = bool
  default     = false
}

variable "source_db_arn" {
  description = "ARN of primary DB for replica creation"
  type        = string
  default     = ""
}

variable "replica_source_id" {
  description = "Source DB identifier for same-region replica"
  type        = string
  default     = ""
}

variable "engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "Database version"
  type        = string
  default     = "8.0"
}

variable "instance_class" {
  description = "Instance type"
  type        = string
  default     = "db.t3.small"
}

variable "allocated_storage" {
  description = "Storage size in GB"
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "Storage type"
  type        = string
  default     = "gp3"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "mydb"
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "admin"
}

variable "password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "backup_retention_days" {
  description = "Backup retention period"
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
