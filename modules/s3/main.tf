# Bucket
resource "aws_s3_bucket" "this" {
  bucket = "${var.bucket_name}-${data.aws_region.current.name}"

  tags = var.tags
}

# Bucket Versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# Bucket ACL
resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

# Replication Configuration for primary bucket
resource "aws_s3_bucket_replication_configuration" "replication" {
  count  = var.is_dr ? 0 : 1
  bucket = aws_s3_bucket.this.id
  role   = var.replication_role_arn

  rule {
    id     = "cross-region-replication"
    status = "Enabled"

    destination {
      bucket = var.destination_bucket_arn
    }

    filter {
      prefix = ""
    }
  }

  depends_on = [aws_s3_bucket_versioning.versioning]
}

# Lifecycle Configuration for primary bucket
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  count  = var.is_dr ? 0 : 1
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix
      }

      transition {
        days          = rule.value.transition.days
        storage_class = rule.value.transition.storage_class
      }

      expiration {
        days = rule.value.expiration.days
      }
    }
  }
}
