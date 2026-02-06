# This file goes in: environments/dev/providers.tf
# AND: environments/qa/providers.tf
# AND: environments/prod/providers.tf

terraform {
  required_providers {
    # Lock the version of the AWS provider to ensure consistency
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# The AWS Provider Block
#
# Authentication is handled automatically by the GitHub Actions workflow
# via the 'aws-actions/configure-aws-credentials' step. That step sets
# the standard AWS environment variables (AWS_ACCESS_KEY_ID, etc.)
# which this provider automatically reads.
#
# The region is also passed in via an environment variable from the workflow.
provider "aws" {
  # No configuration is needed here because it's all handled by the CI/CD runner's environment.
  # The region is set by the AWS_REGION environment variable.
}
