# Security group
resource "aws_security_group" "this" {
  name        = "${var.environment}-${var.name}"
  description = var.description
  vpc_id      = var.vpc_id

  tags = var.tags
}

# Ingress rules
resource "aws_security_group_rule" "ingress" {
  for_each = { for idx, rule in var.ingress_rules : idx => rule }

  security_group_id = aws_security_group.this.id
  type              = "ingress"
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  description       = each.value.description

  cidr_blocks              = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null
  source_security_group_id = length(each.value.security_groups) > 0 ? each.value.security_groups[0] : null
}

# Egress rules
resource "aws_security_group_rule" "egress" {
  for_each = { for idx, rule in var.egress_rules : idx => rule }

  security_group_id = aws_security_group.this.id
  type              = "egress"
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  description       = each.value.description

  cidr_blocks              = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null
  source_security_group_id = length(each.value.security_groups) > 0 ? each.value.security_groups[0] : null
}
