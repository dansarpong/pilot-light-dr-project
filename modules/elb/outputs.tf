
output "elb_id" {
  description = "ID of the ELB"
  value       = aws_elb.this.id
}

output "elb_name" {
  description = "Name of the ELB"
  value       = aws_elb.this.name
}

output "elb_dns_name" {
  description = "DNS name of the ELB"
  value       = aws_elb.this.dns_name
}

output "elb_zone_id" {
  description = "Zone ID of the ELB"
  value       = aws_elb.this.zone_id
}

output "elb_sg_id" {
  description = "ID of the ELB security group"
  value       = var.security_group_id
}

