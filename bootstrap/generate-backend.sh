#!/bin/bash

# Script to generate backend.tf from bootstrap outputs

# BOOTSTRAP_DIR="./bootstrap"
BACKEND_FILE="./backend.tf"

# Get outputs from bootstrap
# cd $BOOTSTRAP_DIR
BUCKET_NAME=$(terraform output -raw s3_bucket_name 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$BUCKET_NAME" ]; then
  echo "Error: Failed to retrieve s3_bucket_name from terraform outputs"
  exit 1
fi

DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$DYNAMODB_TABLE" ]; then
  echo "Error: Failed to retrieve dynamodb_table_name from terraform outputs"
  exit 1
fi

REGION=$(terraform output -raw region 2>/dev/null || echo "us-west-2")

cd .. || {
  echo "Error: Failed to change directory to parent"
  exit 1
}

# Generate backend.tf
cat > $BACKEND_FILE << EOF
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "infrastructure/dev/terraform.tfstate"
    region         = "$REGION"
    encrypt        = true
    # dynamodb_table = "$DYNAMODB_TABLE"
    use_lockfile   = true
  }
}
EOF

echo "Generated $BACKEND_FILE with:"
echo "  Bucket: $BUCKET_NAME"
echo "  DynamoDB Table: $DYNAMODB_TABLE"
echo "  Region: $REGION"