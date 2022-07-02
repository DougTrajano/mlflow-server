terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.11.0"
    }

  }

  required_version = ">= 0.14.9"

  backend "s3" {}
  # backend "local" {}
  # The backend configuration will be added in the terraform init command.
  ## terraform init -backend-config "profile=default"  \
  ## -backend-config "bucket=terraform-states" \
  ## -backend-config "key=mlflow-server/terraform.tfstate" \
  ## -backend-config "region=us-east-1" \
  ## -backend-config "dynamodb_table=terraform-locks" \
  ## -backend-config "encrypt=true"
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}