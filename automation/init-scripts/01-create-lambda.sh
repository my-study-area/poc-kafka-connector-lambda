#!/bin/bash

echo "########### script 01 - Creating lambda function ###########"
awslocal lambda create-function \
  --function-name "consumer-events" \
  --role "arn:aws:iam::123456789012:role/iam_for_lambda" \
  --handler "lambda_function.handler" \
  --code S3Bucket="hot-reload",S3Key="${LAMBDA_PATH}" \
  --runtime "python3.8" \
  --environment Variables="{ENVIRONMENT=DEV}"

sleep 10
