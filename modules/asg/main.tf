# Launch Templates
resource "aws_launch_template" "this" {

  name_prefix   = "${var.environment}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name != "" ? var.key_pair_name : null

  network_interfaces {
    security_groups             = [var.security_group_id]
    associate_public_ip_address = false
  }

  user_data = base64encode(templatefile(var.user_data_path, {}))

  tags = merge({ 
    Name = "${var.environment}-lt"
  }, var.tags)
}

# Auto Scaling Groups
resource "aws_autoscaling_group" "this" {

  name_prefix = "${var.environment}-asg-"

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  vpc_zone_identifier = var.subnet_ids
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
