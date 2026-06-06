output "cloudfront_domain_name" {
  description = "CloudFront distribution domain for the web app and media"
  value       = module.cdn.cloudfront_distribution_domain_name
}

output "cloudfront_url" {
  description = "HTTPS URL for the frontend"
  value       = "https://${module.cdn.cloudfront_distribution_domain_name}"
}

output "api_gateway_url" {
  description = "Base URL for the REST API"
  value       = module.api_gateway.stage_invoke_url
}

output "video_bucket_name" {
  description = "S3 bucket for generated videos"
  value       = module.video_bucket.s3_bucket_id
}

output "frontend_bucket_name" {
  description = "S3 bucket for static frontend assets"
  value       = module.frontend_bucket.s3_bucket_id
}

output "start_job_lambda_arn" {
  description = "ARN of the start-job Lambda function"
  value       = module.start_job_lambda.lambda_function_arn
}

output "get_status_lambda_arn" {
  description = "ARN of the get-status Lambda function"
  value       = module.get_status_lambda.lambda_function_arn
}
