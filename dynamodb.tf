resource "aws_dynamodb_table" "coupons" {
  name           = "Coupons"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "code"

  attribute {
    name = "code"
    type = "S"
  }
}

resource "aws_dynamodb_table" "users" {
  name           = "Users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "userId"

  attribute {
    name = "userId"
    type = "S"
  }
}
