variable "region" {
  description = "Region for this VPC"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cidr_block" {
  description = "Base CIDR block for the VPC"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_http_cidr" {
  description = "CIDR block allowed for HTTP/HTTPS access"
  type        = string
  default     = "0.0.0.0/0"
}
