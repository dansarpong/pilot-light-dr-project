resource "aws_lb" "this" {
  name               = var.name
  load_balancer_type = "application"
  internal           = var.internal
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids
}

resource "aws_lb_listener" "name" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.lb_port
  protocol          = var.lb_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.name.arn
  }
}

resource "aws_lb_target_group" "name" {
  name        = "${var.name}-tg"
  port        = var.instance_port
  protocol    = var.instance_protocol
  vpc_id      = var.vpc_id
  target_type = var.target_type
}
