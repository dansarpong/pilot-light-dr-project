variable "alarm_name" {
  description = "Unique name for the CloudWatch alarm"
  type        = string
}

variable "alarm_description" {
  description = "Description for the CloudWatch alarm"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "metric_name" {
  description = "Metric name to monitor (e.g., CPUUtilization)"
  type        = string
}

variable "namespace" {
  description = "Metric namespace (e.g., AWS/EC2)"
  type        = string
}

variable "dimensions" {
  description = "Map of metric dimensions"
  type        = map(string)
  default     = {}
}

variable "statistic" {
  description = "Statistic to apply (SampleCount, Average, Sum, Minimum, Maximum)"
  type        = string
  default     = "Average"
}

variable "period" {
  description = "Period in seconds (must be multiple of 60)"
  type        = number
  default     = 300
}

variable "evaluation_periods" {
  description = "Number of periods to evaluate"
  type        = number
  default     = 2
}

variable "threshold" {
  description = "Alarm threshold value"
  type        = number
}

variable "comparison_operator" {
  description = "Comparison operator (e.g., GreaterThanOrEqualToThreshold)"
  type        = string
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm state changes"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "List of ARNs to notify when alarm returns to OK"
  type        = list(string)
  default     = []
}

variable "insufficient_data_actions" {
  description = "List of ARNs to notify when data is insufficient"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the alarm"
  type        = map(string)
  default     = {}
}
