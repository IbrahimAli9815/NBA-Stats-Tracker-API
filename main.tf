module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 5.3.0"                # keep your pinned version; upgrade later if you want

  function_name = "nba-stats-tracker"
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"        # ⬅️ recommended upgrade from python3.9
  source_path   = "./lambda"
  publish       = true

  cloudwatch_logs_retention_in_days = 7

  # Least-privilege logging so the function can write to CloudWatch
  attach_policy_statements = true
  policy_statements = [
    {
      effect    = "Allow"
      actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      resources = ["arn:aws:logs:*:*:*"]
    }
  ]
}

# ---- API Gateway HTTP API (explicit) ----
resource "aws_apigatewayv2_api" "http_api" {
  name          = "nba-stats-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.lambda.lambda_function_invoke_arn
  payload_format_version = "2.0"
}

# Route: GET /stats -> Lambda; protect with IAM
resource "aws_apigatewayv2_route" "get_stats" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "GET /stats"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "AWS_IAM"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "prod"
  auto_deploy = true
}

# Allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "allow_apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# Helpful output to call your API
output "api_invoke_url" {
  description = "Invoke URL for GET /stats (IAM auth required)"
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}/${aws_apigatewayv2_stage.prod.name}/stats"
}
