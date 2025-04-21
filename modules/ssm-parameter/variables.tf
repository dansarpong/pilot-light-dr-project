# variables.tf
variable "parameters" {
  description = "A map of SSM parameters to create. The map keys are parameter names, values are configuration objects."
  type = map(object({
    type        = string
    value       = string
    description = optional(string, "")
    tier        = optional(string, "Standard")
    key_id      = optional(string)
    overwrite   = optional(bool, false)
    tags        = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for k, param in var.parameters : contains(["String", "StringList", "SecureString"], param.type)
    ])
    error_message = "Parameter type must be one of 'String', 'StringList', 'SecureString'."
  }

  validation {
    condition = alltrue([
      for k, param in var.parameters : contains(["Standard", "Advanced", "Intelligent-Tiering"], param.tier)
    ])
    error_message = "Tier must be one of 'Standard', 'Advanced', 'Intelligent-Tiering'."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags for all parameters. Merged with individual parameter tags (parameter tags take precedence)."
}
