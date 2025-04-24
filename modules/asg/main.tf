# Launch Templates
resource "aws_launch_template" "this" {

  name          = "${var.environment}-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name != "" ? var.key_pair_name : null

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  network_interfaces {
    security_groups             = [var.security_group_id]
    associate_public_ip_address = true
  }

  user_data = var.user_data_path != null ? base64encode(templatefile(var.user_data_path, {})) : null

  tags = merge({
    Name = "${var.environment}-lt"
  }, var.tags)
}

# Auto Scaling Groups
resource "aws_autoscaling_group" "this" {

  name = "${var.environment}-asg"

  vpc_zone_identifier = var.subnet_ids
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  target_group_arns = var.target_group_arns
  health_check_type = "ELB"

  dynamic "tag" {
    for_each = merge(
      {
        Name = "${var.environment}-app"
      },
      var.tags
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
