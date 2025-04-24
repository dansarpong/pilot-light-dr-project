output "role_arn" {
  description = "ARN of the created IAM role"
  value       = aws_iam_role.this.arn
}

output "policy_arns" {
  description = "ARNs of created policies"
  value       = values(aws_iam_policy.this)[*].arn
}

output "instance_profile_name" {
  description = "Name of the created instance profile"
  value       = length(aws_iam_instance_profile.this) > 0 ? aws_iam_instance_profile.this[0].name : null
}
