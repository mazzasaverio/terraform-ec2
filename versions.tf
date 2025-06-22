# =============================================================================
# TERRAFORM AND PROVIDER VERSIONS
# =============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # No backend configuration = local state
  # For remote state, add backend configuration here
}

# =============================================================================
# AWS PROVIDER CONFIGURATION
# =============================================================================

provider "aws" {
  region = var.aws_region

  # Default tags applied to all resources
  default_tags {
    tags = local.common_tags
  }
}
