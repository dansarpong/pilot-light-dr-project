output "bucket_arn" {
  description = "ARN of S3 bucket"
  value       = aws_s3_bucket.this.arn
}
