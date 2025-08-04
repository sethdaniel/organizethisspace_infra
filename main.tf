terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket         = "messy-room-tfstate"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
