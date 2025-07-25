# variables.tf
# This file defines the input variables for our configuration.

variable "aws_region" {
  description = "The AWS region where resources will be created."
  type        = string
  default     = "us-east-1" # You can change this to your preferred region
}

variable "project_name" {
  description = "The name of the project, used for naming resources."
  type        = string
  default     = "flask-ecs-app"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

# We will create two public and two private subnets for high availability.
variable "public_subnet_cidrs" {
  description = "The CIDR blocks for the public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "The CIDR blocks for the private subnets."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}
