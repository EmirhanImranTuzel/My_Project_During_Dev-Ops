terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    # github = {
    #   source = "integrations/github"
    #   version = "5.8.0"
    # }
  }
}

provider "aws" {
  region = "us-east-1"
}

# provider "github" {
#   token = "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"
# }