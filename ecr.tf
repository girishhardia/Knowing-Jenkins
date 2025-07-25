# ecr.tf
# This file defines the AWS Elastic Container Registry (ECR).

# ECR is a managed Docker container registry that makes it easy to
# store, manage, and deploy Docker container images.
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE" # Allows us to overwrite image tags like 'latest'

  # Configure image scanning to find software vulnerabilities in our images.
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-ecr-repo"
  }
}
