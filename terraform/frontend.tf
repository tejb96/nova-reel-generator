locals {
  frontend_files = {
    for file in fileset("${path.module}/../web", "**/*") : file => file
    if !endswith(file, "config.js")
  }
}

resource "aws_s3_object" "frontend_config" {
  bucket       = module.frontend_bucket.s3_bucket_id
  key          = "config.js"
  content_type = "application/javascript"
  content = templatefile("${path.module}/../web/config.js.tpl", {
    api_base_url = module.api_gateway.stage_invoke_url
  })
  etag = md5(templatefile("${path.module}/../web/config.js.tpl", {
    api_base_url = module.api_gateway.stage_invoke_url
  }))
}

resource "aws_s3_object" "frontend" {
  for_each = local.frontend_files

  bucket       = module.frontend_bucket.s3_bucket_id
  key          = each.key
  source       = "${path.module}/../web/${each.key}"
  etag         = filemd5("${path.module}/../web/${each.key}")
  content_type = lookup(local.frontend_content_types, each.key, "application/octet-stream")
}

locals {
  frontend_content_types = {
    "index.html" = "text/html"
    "script.js"  = "application/javascript"
    "styles.css" = "text/css"
  }
}
