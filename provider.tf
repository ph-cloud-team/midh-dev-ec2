############################################
# AWS Provider Configuration
############################################

# Configures the AWS provider for this live environment.
provider "aws" {
  # Uses the approved AWS region supplied by GitLab CI/CD variables.
  region = var.aws_region
}

