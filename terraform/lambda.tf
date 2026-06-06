locals {
  lambda_environment = {
    VIDEO_BUCKET      = module.video_bucket.s3_bucket_id
    MODEL_ID          = local.nova_reel_model_id
    OUTPUT_PREFIX     = local.video_output_prefix
    CLOUDFRONT_DOMAIN = module.cdn.cloudfront_distribution_domain_name
    AWS_REGION_NAME   = data.aws_region.current.region
  }
}

module "start_job_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.1.0"

  function_name = "${var.project_name}-start-job"
  description   = "Start Nova Reel async video generation job"
  handler       = "handler.handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256

  create_role = false
  lambda_role = module.lambda_execution_role.arn

  source_path = "${path.module}/../lambda/start_job"

  environment_variables = local.lambda_environment

  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.api_execution_arn}/*/*"
    }
  }

  tags = {
    Name    = "${var.project_name}-start-job"
    project = var.project_name
  }
}

module "get_status_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.1.0"

  function_name = "${var.project_name}-get-status"
  description   = "Poll Nova Reel async video generation job status"
  handler       = "handler.handler"
  runtime       = "python3.12"
  timeout       = 15
  memory_size   = 256

  create_role = false
  lambda_role = module.lambda_execution_role.arn

  source_path = "${path.module}/../lambda/get_status"

  environment_variables = local.lambda_environment

  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.api_execution_arn}/*/*"
    }
  }

  tags = {
    Name    = "${var.project_name}-get-status"
    project = var.project_name
  }
}
