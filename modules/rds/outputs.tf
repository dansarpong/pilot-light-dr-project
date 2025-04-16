output "db_endpoint" {
  description = "Database endpoint"
  value       = var.is_primary ? aws_db_instance.primary[0].endpoint : aws_db_instance.replica[0].endpoint
}

output "db_arn" {
  description = "Database ARN"
  value       = var.is_primary ? aws_db_instance.primary[0].arn : aws_db_instance.replica[0].arn
}

output "subnet_group_name" {
  description = "DB Subnet Group name"
  value       = aws_db_subnet_group.db_subnet_group.name
}
