# Nova Reel Generator

Text-to-video demo using Amazon Bedrock Nova Reel, AWS Lambda, API Gateway, S3, and CloudFront.

## Architecture

```text
Browser -> CloudFront (static UI + /video/* media)
         -> API Gateway HTTP API -> Lambda (start job / get status) -> Bedrock Nova Reel -> S3
```

## Prerequisites

1. AWS CLI configured with profile `terraform` (see `terraform/providers.tf`)
2. Terraform >= 1.15
3. **Bedrock model access** in `us-east-1` (required before generation works):
   - Open [Amazon Bedrock console](https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess)
   - Enable access for **Amazon Nova Reel** (`amazon.nova-reel-v1:1`)

## Deploy

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # if you don't have tfvars yet
terraform init
terraform plan
terraform apply
```

After apply, note the outputs:

```bash
terraform output cloudfront_url
terraform output api_gateway_url
```

The frontend is uploaded automatically; open the CloudFront URL in a browser.

## Manual integration test

Each 6-second clip costs about **$0.48** in Nova Reel usage.

1. Confirm Bedrock model access is enabled (see above).
2. Run `./scripts/test-e2e.sh "Your prompt here"` or use the CloudFront UI.
3. Wait ~90 seconds; the player should load `/video/.../output.mp4` from CloudFront.
4. In AWS Console, verify the object in the video S3 bucket.

Optional CLI check after starting a job:

```bash
API_URL=$(terraform -chdir=terraform output -raw api_gateway_url)
curl -s -X POST "$API_URL/jobs" \
  -H "Content-Type: application/json" \
  -d '{"prompt":"A kitten explores a spaceship, cinematic"}'
```

Poll with the returned `jobId`:

```bash
curl -s "$API_URL/jobs/<jobId>"
```

## Repository layout

```text
lambda/
  start_job/handler.py   # start_async_invoke
  get_status/handler.py  # get_async_invoke + CloudFront URL
terraform/
  s3.tf cloudfront.tf iam.tf lambda.tf api_gateway.tf frontend.tf
web/
  index.html script.js styles.css
```

## Cost notes

Lambda, API Gateway, S3, and CloudFront fit typical free-tier usage for demos. Nova Reel is pay-per-second (~$0.08/sec).
