#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/terraform"

echo "==> Bedrock model access (manual, one-time)"
echo "Enable Amazon Nova Reel in us-east-1:"
echo "https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess"
echo

read -r -p "Have you enabled Nova Reel model access? [y/N] " confirmed
if [[ "${confirmed}" != "y" && "${confirmed}" != "Y" ]]; then
  echo "Enable model access first, then re-run this script."
  exit 1
fi

API_URL="$(terraform -chdir="${TF_DIR}" output -raw api_gateway_url)"
PROMPT="${1:-A kitten explores a spaceship, cinematic style}"

echo "==> Starting job via ${API_URL}/jobs"
START_PAYLOAD="$(curl -sS -X POST "${API_URL}/jobs" \
  -H "Content-Type: application/json" \
  -d "{\"prompt\":\"${PROMPT}\"}")"

echo "${START_PAYLOAD}" | python3 -m json.tool

JOB_ID="$(echo "${START_PAYLOAD}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["jobId"])')"

echo "==> Polling job ${JOB_ID}"
for attempt in $(seq 1 60); do
  STATUS_PAYLOAD="$(curl -sS "${API_URL}/jobs/${JOB_ID}")"
  STATUS="$(echo "${STATUS_PAYLOAD}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["status"])')"
  echo "Attempt ${attempt}: ${STATUS}"

  if [[ "${STATUS}" == "Completed" ]]; then
    echo "${STATUS_PAYLOAD}" | python3 -m json.tool
    echo
    echo "Open the CloudFront URL from: terraform -chdir=terraform output cloudfront_url"
    exit 0
  fi

  if [[ "${STATUS}" == "Failed" ]]; then
    echo "${STATUS_PAYLOAD}" | python3 -m json.tool
    exit 1
  fi

  sleep 5
done

echo "Timed out waiting for job completion."
exit 1
