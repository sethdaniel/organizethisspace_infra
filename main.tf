# This block defines the OpenTofu providers we will use.
# In this case, we only need the AWS provider.
# The source tells OpenTofu where to find the provider.
tofu {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# This configures the AWS provider.
# It uses the default credentials chain to authenticate.
# The region can be changed based on your needs.
provider "aws" {
  region = "us-east-1"
}

# This resource creates a new S3 bucket to host our static website.
# The bucket name must be globally unique across all of AWS.
# We'll use "organizethisspace-website" as a simple, clear name.
# Please change this name if you encounter an error about it not being unique.
resource "aws_s3_bucket" "ots_website" {
  bucket = "organizethisspace-website"
}

# This resource configures the S3 bucket to serve a static website.
# It specifies that "index.html" should be the default page.
resource "aws_s3_bucket_website_configuration" "ots_website_config" {
  bucket = aws_s3_bucket.ots_website.id
  index_document {
    suffix = "index.html"
  }
}

# This resource creates a policy for the S3 bucket, allowing anyone
# to publicly read the contents of the bucket. This is necessary
# for the website to be accessible on the internet.
resource "aws_s3_bucket_policy" "ots_website_policy" {
  bucket = aws_s3_bucket.ots_website.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = [
          "s3:GetObject"
        ],
        Resource = [
          "${aws_s3_bucket.ots_website.arn}/*"
        ]
      }
    ]
  })
}
