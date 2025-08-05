module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 5.3.0"

  function_name = "nba-stats-tracker"
  handler       = "handler.lambda_handler"
  runtime       = "python3.9"
  source_path   = "./lambda"
  publish       = true

  # 🔐 Use IAM to protect the API (not public)
  create_api_gateway     = true
  api_gateway_authorizer = "AWS_IAM"  # ✅ Enforces signed IAM requests
  api_gateway_path       = "stats"
  api_gateway_stage_name = "prod"
  api_gateway_method     = "GET"

  # ✅ Enable detailed logging
  cloudwatch_logs_retention_in_days = 7

  # 🔐 Least-privilege permissions for logs only
  attach_policy_statements = true
  policy_statements = [
    {
      effect    = "Allow"
      actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      resources = ["arn:aws:logs:*:*:*"]
    }
  ]
}