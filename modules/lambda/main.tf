# Lambda Function
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = "Lambda function for ${var.function_name}"
  runtime       = var.runtime
  handler       = var.handler
  role          = var.role_arn
  timeout       = var.timeout
  memory_size   = var.memory_size
  # publish       = true
  filename         = var.local_path
  source_code_hash = filebase64sha256(var.local_path)

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  layers = var.layers

  environment {
    variables = var.environment_variables
  }

  tags          = var.tags
}

# Trigger Permissions
resource "aws_lambda_permission" "trigger" {
  for_each = { for idx, t in var.triggers : idx => t }

  statement_id  = "Allow-${each.value.type}-Invocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = each.value.source
  source_arn    = lookup(each.value.config, "source_arn", null)
}

# Event Source Mappings
resource "aws_lambda_event_source_mapping" "this" {
  for_each = { for t in var.triggers : t.type => t if t.type == "sqs" }

  event_source_arn  = each.value.config["queue_arn"]
  function_name     = aws_lambda_function.this.function_name
  batch_size        = lookup(each.value.config, "batch_size", 10)
  enabled           = lookup(each.value.config, "enabled", true)
}
