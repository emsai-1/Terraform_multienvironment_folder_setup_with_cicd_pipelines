variable "project_name" {
  description = "The name of the project, used to tag resources."
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, qa, prod)."
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "public_subnets" {
  description = "A list of CIDR blocks for public subnets."
  type        = list(string)
}

variable "private_subnets" {
  description = "A list of CIDR blocks for private subnets."
  type        = list(string)
}

variable "aws_region" {
  description = "The AWS region to deploy to."
  type        = string
}
