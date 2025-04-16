variable "function_name" {
  description = "Unique name for the Lambda function"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "runtime" {
  description = "Lambda runtime (e.g., python3.8)"
  type        = string
}

variable "handler" {
  description = "Entry point handler (e.g., lambda_function.lambda_handler)"
  type        = string
}

variable "role_arn" {
  description = "Execution role ARN"
  type        = string
}

variable "local_path" {
  description = "Local path to code directory (for local source)"
  type        = string
  default     = ""
}

variable "environment_variables" {
  description = "Environment variables for the function"
  type        = map(string)
  default     = {}
}

variable "timeout" {
  description = "Function timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Function memory allocation in MB"
  type        = number
  default     = 128
}

variable "triggers" {
  description = "List of trigger configurations"
  type = list(object({
    type    = string
    source  = string
    config  = map(any)
  }))
  default = []
}

variable "vpc_config" {
  description = "VPC configuration (if needed)"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "layers" {
  description = "List of Lambda layer ARNs"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the function"
  type        = map(string)
  default     = {}
}
