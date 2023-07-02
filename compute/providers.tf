terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  required_version = ">= 1.4.0"
  backend "s3" {
    bucket         = "tf-remote-state-ab"
    key            = "project1compute.tfstate"
    region         = "us-east-1"
    profile        = "adrianpersonal"
    dynamodb_table = "tf-dynamodb-lock"
  }
}

provider "aws" {
  region  = var.region_name
  profile = var.profile_name
}
