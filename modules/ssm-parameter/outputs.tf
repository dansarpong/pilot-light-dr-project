# outputs.tf
output "parameter_arns" {
  description = "Map of parameter names to their ARNs"
  value       = { for name, param in aws_ssm_parameter.this : name => param.arn }
}

output "parameter_values" {
  description = "Map of parameter names to their values (SecureString values remain encrypted)"
  value       = { for name, param in aws_ssm_parameter.this : name => param.value }
  sensitive   = true
}
