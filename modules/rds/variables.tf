variable "region" {
  description = "Region for this RDS instance"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "is_primary" {
  description = "Whether this is the primary database"
  type        = bool
  default     = true
}

variable "source_db_arn" {
  description = "ARN of primary DB for replica creation"
  type        = string
  default     = ""
}

variable "create_same_region_replica" {
  description = "Create read replica in same region"
  type        = bool
  default     = false
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
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage size in GB"
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "Storage type (gp2/io1)"
  type        = string
  default     = "gp2"
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
  default     = false
}
