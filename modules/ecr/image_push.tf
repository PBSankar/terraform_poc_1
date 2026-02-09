data "aws_caller_identity" "current" {}

# Get latest image version from ECR
data "external" "latest_version" {
  program = ["bash", "-c", <<-EOT
    set -e
    REPO_NAME="${aws_ecr_repository.main.name}"
    REGION="${var.region}"
    
    # Get all image tags
    TAGS=$(aws ecr describe-images --repository-name $REPO_NAME --region $REGION \
      --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags' --output json 2>/dev/null || echo '[]')
    
    # Extract version tags (exclude 'latest')
    VERSION=$(echo $TAGS | jq -r '.[] | select(. != "latest")' | sort -V | tail -1)
    
    if [ -z "$VERSION" ]; then
      echo '{"version":"1.0"}'
    else
      # Increment version
      MAJOR=$(echo $VERSION | cut -d. -f1)
      MINOR=$(echo $VERSION | cut -d. -f2)
      NEW_MINOR=$((MINOR + 1))
      echo "{\"version\":\"$MAJOR.$NEW_MINOR\"}"
    fi
  EOT
  ]
  
  depends_on = [aws_ecr_repository.main]
}

locals {
  # Use provided version or auto-increment
  image_version = var.image_version != "" ? var.image_version : data.external.latest_version.result.version
}

resource "null_resource" "push_image_to_ecr" {
  depends_on = [aws_ecr_repository.main]
  
  triggers = {
    version = local.image_version
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOT
      set -e

      echo "Logging into ECR..."
      aws ecr get-login-password --region ${var.region} \
        | docker login --username AWS --password-stdin \
        ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com

      echo "Pulling source image: ${var.source_image}"
      docker pull ${var.source_image}

      ECR_REPO="${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.main.name}"
      VERSION="${local.image_version}"

      echo "Tagging image with version: $VERSION"
      docker tag ${var.source_image} $ECR_REPO:$VERSION
      docker tag ${var.source_image} $ECR_REPO:latest

      echo "Pushing versioned image: $VERSION"
      docker push $ECR_REPO:$VERSION
      
      echo "Pushing latest tag"
      docker push $ECR_REPO:latest
      
      echo "Successfully pushed image version $VERSION and latest to ECR"
    EOT
  }
}

