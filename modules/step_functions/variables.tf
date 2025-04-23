variable "name" {
  description = "Name of the state machine"
  type        = string
}

variable "role_arn" {
  description = "ARN of the IAM role that will be used by the state machine"
  type        = string
}

variable "definition" {
  description = "State machine definition in JSON format"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the state machine"
  type        = map(string)
  default     = {}
}