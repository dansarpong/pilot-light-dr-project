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

# Replication Configuration
resource "aws_s3_bucket_replication_configuration" "replication" {
  count = var.is_dr ? 0 : 1

  bucket = aws_s3_bucket.this.id
  role   = var.replication_role_arn

  rule {
    id     = "cross-region-replication"
    status = "Enabled"

    destination {
      bucket        = var.destination_bucket_arn
      # storage_class = "STANDARD"

      # Required for cross-region replication
      # metrics {
      #   status = "Enabled"
      #   event_threshold {
      #     minutes = 15
      #   }
      # }
    }

    # Required when not using a prefix
    filter {
      prefix = ""
    }

    # Enable deletion replication
    delete_marker_replication {
      status = "Enabled"
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
        prefix = rule.value.prefix == "" ? null : rule.value.prefix
      }

      dynamic "transition" {
        for_each = rule.value.transition.storage_class != "" ? [rule.value.transition] : []
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration.days > 0 ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }
    }
  }
}
