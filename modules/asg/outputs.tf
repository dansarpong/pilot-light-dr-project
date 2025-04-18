output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.id
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.arn
}

output "lt_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.this.id
}

output "lt_name" {
  description = "Name of the Launch Template"
  value       = aws_launch_template.this.name
}

output "lt_arn" {
  description = "ARN of the Launch Template"
  value       = aws_launch_template.this.arn
}
