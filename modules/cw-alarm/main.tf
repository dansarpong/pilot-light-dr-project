resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name                = "${var.environment}-${var.alarm_name}"
  comparison_operator       = var.comparison_operator
  evaluation_periods        = var.evaluation_periods
  metric_name               = var.metric_name
  namespace                 = var.namespace
  period                    = var.period
  statistic                 = var.statistic
  threshold                 = var.threshold
  alarm_description         = var.alarm_description
  treat_missing_data        = "missing"

  dimensions = var.dimensions

  alarm_actions              = var.alarm_actions
  ok_actions                 = var.ok_actions
  insufficient_data_actions  = var.insufficient_data_actions

  tags = var.tags
}
