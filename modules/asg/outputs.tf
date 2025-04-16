output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.pilot_light_asg.name
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.pilot_light.id
}

output "instance_security_group" {
  description = "Security group associated with instances"
  value       = aws_launch_template.pilot_light.network_interfaces[0].security_groups[0]
}
