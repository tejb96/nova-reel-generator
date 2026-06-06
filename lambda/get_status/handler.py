import json
import os

import boto3

bedrock = boto3.client("bedrock-runtime")


def handler(event, context):
    job_id = (event.get("pathParameters") or {}).get("id")
    if not job_id:
        return _response(400, {"error": "job id is required"})

    account_id = context.invoked_function_arn.split(":")[4]
    region = os.environ["AWS_REGION_NAME"]
    invocation_arn = f"arn:aws:bedrock:{region}:{account_id}:async-invoke/{job_id}"

    job = bedrock.get_async_invoke(invocationArn=invocation_arn)
    status = job["status"]

    result = {
        "jobId": job_id,
        "status": status,
    }

    if status == "Completed":
        s3_uri = job["outputDataConfig"]["s3OutputDataConfig"]["s3Uri"]
        if not s3_uri.endswith(".mp4"):
            s3_uri = f"{s3_uri.rstrip('/')}/output.mp4"
        result["videoUrl"] = _s3_uri_to_cloudfront_url(s3_uri)
    elif status == "Failed":
        result["failureMessage"] = job.get("failureMessage", "Video generation failed")

    return _response(200, result)


def _s3_uri_to_cloudfront_url(s3_uri):
    bucket = os.environ["VIDEO_BUCKET"]
    prefix = f"s3://{bucket}/"
    if not s3_uri.startswith(prefix):
        return s3_uri

    object_key = s3_uri[len(prefix) :]
    cloudfront_domain = os.environ["CLOUDFRONT_DOMAIN"]
    return f"https://{cloudfront_domain}/{object_key}"


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type",
            "Content-Type": "application/json",
        },
        "body": json.dumps(body),
    }
