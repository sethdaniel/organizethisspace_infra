resource "aws_s3_bucket" "tf_state" {
  bucket = "messy-room-tfstate"
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
