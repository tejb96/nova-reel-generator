locals {
  nova_reel_model_id = "amazon.nova-reel-v1:1"
  video_output_prefix = "video/"

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
