variable "name" {
  description = "Name for the load balancer"
  type        = string
}

variable "internal" {
  description = "Whether the load balancer is internal"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID from VPC module"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs for the load balancer"
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs for the load balancer"
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

variable "target_type" {
  description = "Type of target that you must specify when registering targets with this target group"
  type        = string
}

variable "lb_port" {
  description = "Port on which the load balancer listens"
  type        = number
  default     = 80
}

variable "lb_protocol" {
  description = "Protocol for the load balancer"
  type        = string
  default     = "HTTP"
}

variable "tags" {
  description = "Additional tags for the load balancer"
  type        = map(string)
  default     = {}
}
