resource "aws_s3_bucket" "frontend" {
  bucket = var.frontend_bucket
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  index_document { suffix = "index.html" }
}

resource "aws_s3_bucket" "uploads" {
  bucket = var.uploads_bucket
}

resource "aws_s3_bucket" "lambda_code" {
  bucket = var.lambda_code_bucket
}
