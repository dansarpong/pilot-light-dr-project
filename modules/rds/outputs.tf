output "primary_db_endpoint" {
  description = "Primary Database endpoint"
  value       = aws_db_instance.primary[0].endpoint
}

output "primary_db_arn" {
  description = "Primary Database ARN"
  value       = aws_db_instance.primary[0].arn
}

output "cross_region_db_endpoint" {
  description = "Cross-Region Database endpoint"
  value       = aws_db_instance.cross_region_replica[0].endpoint
}

output "cross_region_db_arn" {
  description = "Cross-Region Database ARN"
  value       = aws_db_instance.cross_region_replica[0].arn
}

output "subnet_group_name" {
  description = "DB Subnet Group name"
  value       = aws_db_subnet_group.db_subnet_group.name
}
