provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-${var.environment}-terraform-state-bucket"

  # Prevent accidental bucket deletion and recreation
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [bucket]
  }

  tags = merge(var.common_tags, {
    Name        = "Terraform State Bucket"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = "${var.project_name}-${var.environment}-terraform-locks"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }

#   tags = {
#     Name        = "Terraform Lock Table"
#     Environment = "shared"
#   }
# }

resource "null_resource" "generate_backend" {
  depends_on = [aws_s3_bucket.terraform_state]

  provisioner "local-exec" {
    command = "bash generate-backend.sh"
  }

  triggers = {
    bucket_name = aws_s3_bucket.terraform_state.bucket
  }
}