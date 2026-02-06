# This file goes in: environments/dev/variables.tf
# AND: environments/qa/variables.tf
# AND: environments/prod/variables.tf

# --- General & AWS Provider Variables ---
variable "environment" {
  description = "The deployment environment name (dev, qa, or prod)."
  type        = string
}
variable "aws_region" {
  description = "The AWS region for this environment."
  type        = string
}

# --- VPC Module Variables ---
variable "vpc_cidr_block" {
  description = "The CIDR block for the environment's VPC."
  type        = string
}
variable "public_subnets" {
  description = "A list of CIDR blocks for the public subnets."
  type        = list(string)
}
variable "private_subnets" {
  description = "A list of CIDR blocks for the private subnets."
  type        = list(string)
}


# --- EC2 Instance Module Variables ---
variable "instance_type" {
  description = "The instance type for the application server."
  type        = string
}
variable "ami_id" {
  description = "The Amazon Machine Image ID for the EC2 instance."
  type        = string
}


# --- S3 Bucket Module Variables ---
variable "bucket_name_prefix" {
  description = "A globally unique prefix for the application data S3 bucket."
  type        = string
}
