# IAM Role
resource "aws_iam_role" "this" {
  name = "${var.environment}-${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = var.assume_role_service
      }
    }]
  })

  tags = merge({
    Environment = var.environment
    ManagedBy   = "Terraform"
  }, var.tags)
}

# Custom Policies
resource "aws_iam_policy" "this" {
  for_each = var.policies

  name   = "${var.environment}-${var.name}-${each.key}"
  policy = templatefile("${path.module}/policies/policy.tmpl", {
    policy_document = each.value
    environment     = var.environment
  })

  tags = merge({
    Environment = var.environment
    ManagedBy   = "Terraform"
  }, var.tags)
}

# Attach custom policies
resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.policies

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[each.key].arn
}

# Attach managed policies
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}
