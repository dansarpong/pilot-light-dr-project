provider "aws" {
  region = var.region
}

# Primary Bucket
resource "aws_s3_bucket" "primary" {
  bucket = "${var.environment}-${var.bucket_name}-${var.region}"

  tags = merge({
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "PilotLight-DR"
  }, var.tags)
}

# Primary Bucket Versioning
resource "aws_s3_bucket_versioning" "primary_versioning" {
  bucket = aws_s3_bucket.primary.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# Primary Bucket ACL
resource "aws_s3_bucket_acl" "primary_acl" {
  bucket = aws_s3_bucket.primary.id
  acl    = "private"
}

# DR Bucket
resource "aws_s3_bucket" "dr" {
  provider = aws.dr
  bucket   = "${var.environment}-${var.bucket_name}-${var.dr_region}"

  tags = merge({
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "PilotLight-DR"
  }, var.tags)
}

# DR Bucket Versioning
resource "aws_s3_bucket_versioning" "dr_versioning" {
  bucket = aws_s3_bucket.dr.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# DR Bucket ACL
resource "aws_s3_bucket_acl" "dr_acl" {
  bucket = aws_s3_bucket.dr.id
  acl    = "private"
}

# Replication Configuration
resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = aws_s3_bucket.primary.id
  role   = var.replication_role_arn

  rule {
    id     = "cross-region-replication"
    status = "Enabled"

    destination {
      bucket = aws_s3_bucket.dr.arn
      storage_class = "STANDARD_IA"
    }

    filter {
      prefix = ""
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.primary_versioning,
    aws_s3_bucket_versioning.dr_versioning
  ]
}

# Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "primary_lifecycle" {
  bucket = aws_s3_bucket.primary.id

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
