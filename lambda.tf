locals {
  organize_room_zip = fileexists("${path.module}/../messy-room-organizer/organize_room.zip") ? "${path.module}/../messy-room-organizer/organize_room.zip" : null
  paywall_zip       = fileexists("${path.module}/../messy-room-organizer/paywall.zip") ? "${path.module}/../messy-room-organizer/paywall.zip" : null
}

resource "aws_lambda_function" "organize_room" {
  function_name = "organizeRoom"
  handler       = "organize_room.lambda_handler"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_role.arn

  filename      = local.organize_room_zip != null ? local.organize_room_zip : "${path.module}/empty.zip"
  source_code_hash = local.organize_room_zip != null ? filebase64sha256(local.organize_room_zip) : filebase64sha256("${path.module}/empty.zip")

  environment {
    variables = {
      OPENAI_API_KEY = "REPLACE_ME"
      UPLOAD_BUCKET  = var.uploads_bucket
      COUPON_TABLE   = aws_dynamodb_table.coupons.name
      USERS_TABLE    = aws_dynamodb_table.users.name
    }
  }
}

resource "aws_lambda_function" "paywall" {
  function_name = "paywall"
  handler       = "paywall.lambda_handler"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_role.arn

  filename      = local.paywall_zip != null ? local.paywall_zip : "${path.module}/empty.zip"
  source_code_hash = local.paywall_zip != null ? filebase64sha256(local.paywall_zip) : filebase64sha256("${path.module}/empty.zip")

  environment {
    variables = {
      STRIPE_SECRET_KEY = "REPLACE_ME"
      COUPON_TABLE      = aws_dynamodb_table.coupons.name
      USERS_TABLE       = aws_dynamodb_table.users.name
    }
  }
}

resource "aws_apigatewayv2_api" "api" {
  name          = "messy-room-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "organize_room" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.organize_room.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "paywall" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.paywall.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "organize_room" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /organize-room"
  target    = "integrations/${aws_apigatewayv2_integration.organize_room.id}"
}

resource "aws_apigatewayv2_route" "paywall" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /paywall"
  target    = "integrations/${aws_apigatewayv2_integration.paywall.id}"
}

output "api_gateway_url" {
  value = aws_apigatewayv2_api.api.api_endpoint
}
