variable "name" {
  description = "Name of the event rule"
  type        = string
}

variable "description" {
  description = "Description of the event rule"
  type        = string
  default     = ""
}

variable "event_type" {
  description = "Type of the event rule"
  type        = string
  default     = "schedule"
}

variable "schedule_expression" {
  description = "Schedule expression for the event rule"
  type        = string
  default     = ""
}

variable "event_pattern" {
  description = "Event pattern for the event rule"
  type        = string
  default     = ""
}

variable "arn" {
  description = "ARN of the target resource"
  type        = string
}

variable "target_id" {
  description = "Target ID for the event rule"
  type        = string
}
