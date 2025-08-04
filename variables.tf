variable "aws_region" {
  default = "us-east-1"
}

variable "frontend_bucket" {
  default = "messy-room-frontend"
}

variable "uploads_bucket" {
  default = "messy-room-uploads"
}

variable "lambda_runtime" {
  default = "python3.11"
}

variable "lambda_code_bucket" {
  default = "messy-room-lambda-code"
}
