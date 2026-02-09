output "s3_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

# output "dynamodb_table_name" {
#   value = aws_dynamodb_table.terraform_locks.name
# }

output "region" {
  value = var.region
}

output "backend_config" {
  # Error handling for backend configuration is managed by Terraform's built-in mechanisms.
  value = <<EOF
terraform {
  backend "s3" {
    bucket         = "${aws_s3_bucket.terraform_state.bucket}"
    key            = "${var.project_name}/${var.environment}/terraform.tfstate"
    region         = "${var.region}"
    encrypt        = true
    use_lockfile   = true
  }
}
EOF
}