terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.28"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.8.0"
    }
  }

  required_version = ">= 1.2"
}
