resource "aws_cloudwatch_event_rule" "this" {
  name                = var.name
  description         = var.description
  schedule_expression = var.event_type == "schedule" ? var.schedule_expression : null
  event_pattern       = var.event_type == "health" ? var.event_pattern : null
}

resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.this.name
  arn       = var.arn
  target_id = var.target_id
}
