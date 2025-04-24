# IAM Role
resource "aws_iam_role" "this" {
  name = var.name

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

  tags = var.tags
}

# Custom Policies
resource "aws_iam_policy" "this" {
  for_each = var.policies

  name   = "${var.name}-${each.key}"
  policy = each.value

  tags = var.tags
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

# Instance Profile
resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile ? 1 : 0

  name = "${var.name}-profile"
  role = aws_iam_role.this.name
}
