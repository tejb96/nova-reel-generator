import json
import os

import boto3

bedrock = boto3.client("bedrock-runtime")


def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "Invalid JSON body"})

    prompt = body.get("prompt", "").strip()
    if not prompt:
        return _response(400, {"error": "prompt is required"})
    if len(prompt) > 512:
        return _response(400, {"error": "prompt must be 512 characters or fewer"})

    bucket = os.environ["VIDEO_BUCKET"]
    prefix = os.environ["OUTPUT_PREFIX"]
    output_s3_uri = f"s3://{bucket}/{prefix}"

    response = bedrock.start_async_invoke(
        modelId=os.environ["MODEL_ID"],
        modelInput={
            "taskType": "TEXT_VIDEO",
            "textToVideoParams": {"text": prompt},
            "videoGenerationConfig": {
                "fps": 24,
                "durationSeconds": 6,
                "dimension": "1280x720",
                "seed": body.get("seed", 42),
            },
        },
        outputDataConfig={"s3OutputDataConfig": {"s3Uri": output_s3_uri}},
    )

    invocation_arn = response["invocationArn"]
    job_id = invocation_arn.rsplit("/", 1)[-1]

    return _response(
        202,
        {
            "jobId": job_id,
            "invocationArn": invocation_arn,
        },
    )


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
