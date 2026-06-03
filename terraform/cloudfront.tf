module "cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "6.7.0"

  default_root_object = "index.html"


  origin = {
    frontend = {
      domain_name               = module.frontend_bucket.s3_bucket_bucket_regional_domain_name
      origin_id                 = "frontend"
      origin_access_control_key = "s3"
    }
    thumbnail = {
      domain_name               = module.thumbnail_bucket.s3_bucket_bucket_regional_domain_name
      origin_id                 = "thumbnail"
      origin_access_control_key = "s3"
    }
    video = {
      domain_name               = module.video_bucket.s3_bucket_bucket_regional_domain_name
      origin_id                 = "video"
      origin_access_control_key = "s3"
    }
  }
  default_cache_behavior = {
    target_origin_id       = "frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }
  ordered_cache_behavior = [
    {
      path_pattern           = "/thumbnail/*"
      target_origin_id       = "thumbnail"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      min_ttl                = 0
      default_ttl            = 86400
      max_ttl                = 31536000
    },
    {
      path_pattern           = "/video/*"
      target_origin_id       = "video"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      min_ttl                = 0
      default_ttl            = 86400
      max_ttl                = 31536000
    }
  ]
  custom_error_response = [
    {
      error_code         = 403
      response_code      = 200
      response_page_path = "/index.html"
    },
    {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
    },
    {
      error_code         = 500
      response_code      = 200
      response_page_path = "/index.html"
    }
  ]
  restrictions = {
    geo_restriction = {
      restriction_type = "whitelist"
      locations        = ["CA"]
    }
  }
  viewer_certificate = {
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_100"
  tags = {
    Name    = "nova-reels-cdn"
    project = var.project_name
  }
}
