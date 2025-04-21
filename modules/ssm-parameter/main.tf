resource "aws_ssm_parameter" "this" {
  for_each = var.parameters

  name        = each.key
  type        = each.value.type
  value       = each.value.value
  description = each.value.description
  tier        = each.value.tier
  key_id      = each.value.key_id
  overwrite   = each.value.overwrite
  tags        = merge(var.tags, each.value.tags)
}
