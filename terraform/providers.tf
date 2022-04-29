terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.11.0"
    }

  }

  required_version = ">= 0.14.9"

  backend "s3" {
    bucket         = "doug-terraform-states"
    key            = "mlflow-server/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}