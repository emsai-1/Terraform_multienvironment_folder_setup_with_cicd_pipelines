# -----------------------------------------------------------------
#         EXAMPLE VARIABLES FOR LOCAL DEVELOPMENT
# -----------------------------------------------------------------
#
# A developer should copy this file to 'terraform.tfvars' (which is git-ignored)
# and fill in the values to run Terraform on their local machine.
# This file is NOT used by the GitHub Actions CI/CD pipeline.
#
# -----------------------------------------------------------------

# --- General & AWS Provider Variables ---
environment       = "dev"
aws_region        = "us-east-1"


# --- VPC Module Variables ---
vpc_cidr_block    = "10.10.0.0/16"
public_subnets    = ["10.10.1.0/24"]
private_subnets   = ["10.10.10.0/24"]


# --- EC2 Instance Module Variables ---
# IMPORTANT: Go to the AWS EC2 Console in your selected region to find the
# latest AMI ID for "Amazon Linux 2023". This ID changes frequently.
ami_id            = "ami-0c55b159cbfafe1f0" 
instance_type     = "t2.micro"


# --- S3 Bucket Module Variables ---
# Use a prefix that is likely to be globally unique.
bucket_name_prefix = "my-cool-app-data-johndoe"
# ... your other variables ...


