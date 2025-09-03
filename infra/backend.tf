terraform {
  required_version = ">=1.6.0"
  backend "s3" {
    bucket         = "solar-power-controller"
    key            = "power-manager-aws-ci/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "solar-power-controller"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0"
    }
  }
}