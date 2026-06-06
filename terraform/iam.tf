data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lambda_bedrock" {
  statement {
    sid    = "NovaReelAsyncInvoke"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:StartAsyncInvoke",
      "bedrock:GetAsyncInvoke",
      "bedrock:ListAsyncInvokes",
    ]
    resources = [
      "arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/${local.nova_reel_model_id}",
      "arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:async-invoke/*",
    ]
  }

  statement {
    sid    = "VideoBucketAccess"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      module.video_bucket.s3_bucket_arn,
      "${module.video_bucket.s3_bucket_arn}/*",
    ]
  }
}

data "aws_region" "current" {}

module "lambda_execution_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name             = "${var.project_name}-lambda-execution"
  use_name_prefix  = false

  trust_policy_permissions = {
    lambda = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["lambda.amazonaws.com"]
      }]
    }
  }

  policies = {
    AWSLambdaBasicExecutionRole = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    bedrock_s3                   = aws_iam_policy.lambda_bedrock.arn
  }

  tags = {
    Name    = "${var.project_name}-lambda-execution"
    project = var.project_name
  }
}

resource "aws_iam_policy" "lambda_bedrock" {
  name        = "${var.project_name}-lambda-bedrock-s3"
  description = "Allow Nova Reel async invoke and video bucket access"
  policy      = data.aws_iam_policy_document.lambda_bedrock.json

  tags = {
    Name    = "${var.project_name}-lambda-bedrock-s3"
    project = var.project_name
  }
}
