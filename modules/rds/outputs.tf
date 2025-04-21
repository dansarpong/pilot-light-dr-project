output "db_endpoint" {
  description = "Database endpoint"
  value       = var.source_db_arn == "" ? aws_db_instance.primary[0].endpoint : aws_db_instance.cross_region_replica[0].endpoint
}

output "db_arn" {
  description = "Database ARN"
  value       = var.source_db_arn == "" ? aws_db_instance.primary[0].arn : aws_db_instance.cross_region_replica[0].arn
}

output "db_instance_id" {
  description = "Database Instance ID"
  value       = var.source_db_arn == "" ? aws_db_instance.primary[0].id : aws_db_instance.cross_region_replica[0].id
}

output "subnet_group_name" {
  description = "Database Subnet Group name"
  value       = aws_db_subnet_group.db_subnet_group.name
}
