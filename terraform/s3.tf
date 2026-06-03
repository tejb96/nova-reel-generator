locals {
  cloudfront_buckets = {
    frontend = {
      bucket = module.frontend_bucket.s3_bucket_id
      arn    = module.frontend_bucket.s3_bucket_arn
    }
    thumbnail = {
      bucket = module.thumbnail_bucket.s3_bucket_id
      arn    = module.thumbnail_bucket.s3_bucket_arn
    }
    video = {
      bucket = module.video_bucket.s3_bucket_id
      arn    = module.video_bucket.s3_bucket_arn
    }
  }
}

module "video_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.14.0"

  bucket = "nova-reels-video-bucket"
  acl    = "private"
  versioning = {
    enabled = false
  }

  tags = {
    Name    = "nova-reels-video-bucket"
    project = var.project_name
  }
}

module "thumbnail_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.14.0"

  bucket = "nova-reels-thumbnail-bucket"
  acl    = "private"
  versioning = {
    enabled = false
  }

  tags = {
    Name    = "nova-reels-thumbnail-bucket"
    project = var.project_name
  }
}

module "frontend_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.14.0"

  bucket = "nova-reels-frontend-bucket"
  acl    = "private"
  versioning = {
    enabled = false
  }

  tags = {
    Name    = "nova-reels-frontend-bucket"
    project = var.project_name
  }
}

data "aws_iam_policy_document" "cloudfront_oac" {
  for_each = local.cloudfront_buckets

  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${each.value.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [module.cdn.cloudfront_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_oac" {
  for_each = local.cloudfront_buckets

  bucket = each.value.bucket
  policy = data.aws_iam_policy_document.cloudfront_oac[each.key].json
}
