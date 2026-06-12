locals {
    vpc_cidr = "192.0.0.0/16"

    eks_subnet_cidrs = ["192.0.1.0/24", "192.0.2.0/24"]
    rds_subnet_cidrs = ["192.0.11.0/24", "192.0.12.0/24"]
    AZs = ["ap-northeast-2a", "ap-northeast-2c"]
}