module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "5.5.0"

  name          = var.project_name
  description   = "Nova Reel video generation API"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_origins = ["*"]
  }

  routes = {
    "POST /jobs" = {
      integration = {
        uri                    = module.start_job_lambda.lambda_function_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 30000
      }
    }

    "GET /jobs/{id}" = {
      integration = {
        uri                    = module.get_status_lambda.lambda_function_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 15000
      }
    }
  }

  tags = {
    Name    = "${var.project_name}-api"
    project = var.project_name
  }
}
