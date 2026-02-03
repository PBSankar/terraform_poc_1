data "aws_caller_identity" "current" {}

resource "null_resource" "push_nginx_to_ecr" {
  depends_on = [aws_ecr_repository.main]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOT
      set -e

      echo "Logging into ECR..."
      aws ecr get-login-password --region ${var.region} \
        | docker login --username AWS --password-stdin \
        ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com

      echo "Pulling nginx image..."
      docker pull nginx:latest

      echo "Tagging image for ECR..."
      docker tag nginx:latest \
        ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.main.name}:latest

      echo "Pushing image to ECR..."
      docker push \
        ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.main.name}:latest
      echo "NGINX successfully pushed to ECR"
    EOT
  }
}

