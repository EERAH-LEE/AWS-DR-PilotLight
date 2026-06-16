terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket = "tfstate-azsis-kbeauty"
    key    = "aws/dr/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# core/ state 에서 VPC, subnet, SG 정보 읽기
data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "tfstate-azsis-kbeauty"
    key    = "aws/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
