output "frontend_bucket" {
  value = aws_s3_bucket.frontend.bucket
}

output "uploads_bucket" {
  value = aws_s3_bucket.uploads.bucket
}

output "lambda_code_bucket" {
  value = aws_s3_bucket.lambda_code.bucket
}
