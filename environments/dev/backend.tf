# This file goes in: environments/dev/backend.tf

terraform {
  backend "s3" {
    # This bucket should already exist. It's for non-prod state files.
    bucket         = "genai-bucket-deloitte" 
    key            = "genai-bucket-deloitte/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
