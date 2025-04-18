variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID from VPC module"
  type        = string
}

variable "name" {
  description = "Security group name suffix"
  type        = string
}

variable "description" {
  description = "Security group description"
  type        = string
}

variable "ingress_rules" {
  description = "List of ingress rule objects"
  type = list(object({
    description      = string
    protocol         = string
    from_port        = number
    to_port          = number
    cidr_blocks      = list(string)
    security_groups  = list(string)
  }))
}

variable "egress_rules" {
  description = "List of egress rule objects"
  type = list(object({
    description      = string
    protocol         = string
    from_port        = number
    to_port          = number
    cidr_blocks      = list(string)
    security_groups  = list(string)
  }))
}

variable "tags" {
  description = "Additional tags for the security group"
  type        = map(string)
  default     = {}
}
