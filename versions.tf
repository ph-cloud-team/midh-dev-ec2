############################################
# Terraform Version and Provider Constraints
############################################

# Defines Terraform settings for this live repository.
terraform {
  # Requires an enterprise-supported Terraform version.
  required_version = ">= 1.6.0"

  # Uses GitLab's Terraform HTTP backend configured by CI variables.
  backend "http" {}

  # Defines required provider plugins for this live repo.
  required_providers {
    # Uses the official HashiCorp AWS provider.
    aws = {
      # Downloads the AWS provider from the public Terraform registry.
      source = "hashicorp/aws"

      # Pins to the AWS provider major version validated by the platform.
      version = "~> 5.0"
    }
  }
}

