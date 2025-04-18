
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "name" {
  description = "Name for the load balancer"
  type        = string
}

variable "internal" {
  description = "Whether the ELB is internal"
  type        = bool
  default     = false
}

variable "security_group_id" {
  description = "Security group ID for the ELB"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ELB"
  type        = list(string)
}

variable "instance_port" {
  description = "Port on which instances receive traffic"
  type        = number
  default     = 80
}

variable "instance_protocol" {
  description = "Protocol for instances"
  type        = string
  default     = "HTTP"
}

variable "lb_port" {
  description = "Port on which the ELB listens"
  type        = number
  default     = 80
}

variable "lb_protocol" {
  description = "Protocol for the ELB"
  type        = string
  default     = "HTTP"
}

variable "health_check_target" {
  description = "Target of health checks"
  type        = string
  default     = "HTTP:80/"
}

variable "health_check_interval" {
  description = "Interval between health checks"
  type        = number
  default     = 30
}

variable "health_check_healthy_threshold" {
  description = "Number of checks before instance is declared healthy"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of checks before instance is declared unhealthy"
  type        = number
  default     = 2
}

variable "health_check_timeout" {
  description = "Timeout for health checks"
  type        = number
  default     = 5
}

variable "idle_timeout" {
  description = "Connection idle timeout in seconds"
  type        = number
  default     = 60
}

variable "connection_draining_timeout" {
  description = "Connection draining timeout in seconds"
  type        = number
  default     = 300
}

variable "tags" {
  description = "Additional tags for the ELB"
  type        = map(string)
  default     = {}
}

