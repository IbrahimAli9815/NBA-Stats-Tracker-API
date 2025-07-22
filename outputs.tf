output "api_gateway_url" {
  value       = module.lambda.api_gateway_invoke_url
  description = "Public URL to trigger the API Gateway endpoint linked to the Lambda function"
}
