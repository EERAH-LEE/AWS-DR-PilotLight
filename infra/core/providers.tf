terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 6.0"
    }
    random = {
       source  = "hashicorp/random"
       version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "tfstate-azsis-kbeauty"      # S3 버킷 이름
    key    = "aws/core/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

provider "aws" {
  region = local.aws_region
}

