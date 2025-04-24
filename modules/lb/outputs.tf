output "lb_id" {
  description = "ID of the LB"
  value       = aws_lb.this.id
}

output "lb_name" {
  description = "Name of the LB"
  value       = aws_lb.this.name
}

output "lb_dns_name" {
  description = "DNS name of the LB"
  value       = aws_lb.this.dns_name
}

output "lb_zone_id" {
  description = "Zone ID of the LB"
  value       = aws_lb.this.zone_id
}

output "lb_sg_ids" {
  description = "ID of the LB security group"
  value       = var.security_group_ids
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.name.arn
}
