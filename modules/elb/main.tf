# Load Balancer
resource "aws_elb" "this" {
  name            = "${var.environment}-${var.name}"
  internal        = var.internal
  security_groups = [var.security_group_id]
  subnets         = var.subnet_ids

  listener {
    instance_port     = var.instance_port
    instance_protocol = var.instance_protocol
    lb_port           = var.lb_port
    lb_protocol       = var.lb_protocol
  }

  health_check {
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    target              = var.health_check_target
    interval            = var.health_check_interval
  }

  cross_zone_load_balancing   = true
  idle_timeout                = var.idle_timeout
  connection_draining         = true
  connection_draining_timeout = var.connection_draining_timeout

  tags = merge(
    {
      Name = "${var.environment}-${var.name}"
    },
    var.tags
  )
}

