output "bucket_arn" {
  description = "ARN of S3 bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_name" {
  description = "Name of S3 bucket"
  value       = aws_s3_bucket.this.bucket
}
