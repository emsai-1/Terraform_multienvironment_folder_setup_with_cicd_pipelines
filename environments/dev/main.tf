

# Call the VPC module to create the foundational network
module "vpc" {
  source = "../../modules/vpc"

  project_name     = "webapp"
  environment      = var.environment
  aws_region       = var.aws_region
  vpc_cidr_block   = var.vpc_cidr_block
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
}

# Call the EC2 module to deploy the application server into the VPC
module "ec2_web_app" {
  source = "../../modules/ec2"

  # Use the output from the VPC module as input here
  subnet_id = module.vpc.public_subnet_ids[0] # Place instance in the first public subnet

  # Pass variables from the workflow
  environment   = var.environment
  instance_type = var.instance_type
  ami_id        = var.ami_id
}

# Call the S3 module to create a private bucket for application data
module "app_data_bucket" {
  source = "../../modules/S3"

  bucket_name_prefix = var.bucket_name_prefix
  environment        = var.environment
  
  tags = {
    Project     = "webapp"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
