# This block configures OpenTofu itself.
# It specifies the required providers and their versions, and also
# the S3 backend for storing the state file remotely.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # This block configures the S3 backend for remote state storage.
  # This is crucial for collaboration and for maintaining a single
  # source of truth for your infrastructure's state.
  backend "s3" {
    bucket         = "tf-state-bucket-organizethisspace"
    key            = "website/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "tf-state-lock-table"
  }
}

# This block configures the AWS provider.
# It tells OpenTofu which AWS region to deploy the resources to.
# Note: For CloudFront, the ACM certificate must be in us-east-1, but the
# distribution itself can be created in any region. The resources in this script
# are global.
provider "aws" {
  region = "us-east-1"
}

# This code defines a complete and secure configuration for a static website,
# creating an S3 bucket, a CloudFront distribution, an Origin Access Control (OAC),
# and the necessary bucket policy. This script is designed to be run from a clean state.

# 1. Create the S3 Bucket for the static website
# This resource creates a private S3 bucket. We block all public access to it.
resource "aws_s3_bucket" "website_bucket" {
  bucket = "organizethisspace-website"

  tags = {
    Name = "organizethisspace-website"
  }
}

# 2. Block all public access to the S3 bucket
# This is a critical security measure to ensure the bucket's content is
# only accessible via CloudFront.
resource "aws_s3_bucket_public_access_block" "website_bucket_public_access_block" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = true
  # We must set this to 'false' to allow the bucket policy to be attached.
  # The policy we're attaching is NOT public, so this is a secure change.
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. Create a new Origin Access Control (OAC)
# This OAC is the secure connection between CloudFront and your S3 bucket.
# It ensures that only your CloudFront distribution can access the content.
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "organizethisspace-website-oac"
  description                       = "OAC for the organizethisspace static website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 4. Create the CloudFront Distribution
# This resource creates a new distribution that serves content from the S3 bucket
# and uses the OAC for a secure connection.
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for organizethisspace static website"
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id                = "S3-Bucket-Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  default_cache_behavior {
    target_origin_id       = "S3-Bucket-Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # This 'forwarded_values' block is required to resolve the InvalidArgument error.
    # It tells CloudFront not to forward query strings or cookies to the S3 origin.
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# 5. Create the S3 Bucket Policy
# This policy grants the CloudFront OAC explicit permission to read objects (s3:GetObject)
# from your bucket. It uses the ARN of the distribution we just created as the principal.
resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3:GetObject"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.website_bucket.id}/*",
        ]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      },
    ]
  })
}

# Output the CloudFront distribution domain name so you can access your website.
output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
  description = "The domain name of the CloudFront distribution."
}
