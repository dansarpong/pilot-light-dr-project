output "primary_bucket_arn" {
  description = "ARN of primary S3 bucket"
  value       = aws_s3_bucket.primary.arn
}

output "dr_bucket_arn" {
  description = "ARN of DR S3 bucket"
  value       = aws_s3_bucket.dr.arn
}
