# Launch Template
resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-${var.region}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  network_interfaces {
    security_groups = [var.security_group_id]
    associate_public_ip_address = false
  }

  user_data = base64encode(templatefile(var.user_data_path, {}))
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  name_prefix = "${var.environment}-${var.region}-asg-"

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  vpc_zone_identifier = var.private_subnet_ids

  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}
