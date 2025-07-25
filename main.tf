# main.tf
# This is the main entry point for our Terraform configuration.

# The terraform block configures fundamental Terraform settings.
terraform {
  # required_providers specifies the providers this configuration needs.
  # We are using the official AWS provider from HashiCorp.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0" # Use a version constraint for stability
    }
  }
}

# The provider block configures the specified provider, in this case 'aws'.
# We are telling Terraform to deploy our resources to the region
# defined in our variables file.
provider "aws" {
  region = var.aws_region
}
