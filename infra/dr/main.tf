# core state 에서 인프라 값 참조
locals {
  core = data.terraform_remote_state.core.outputs
}

# NAT Gateway - EKS 프라이빗 노드가 인터넷(AWS API) 접근용
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "eip-${local.namespace}-nat"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = local.core.public_subnet_ids[0]

  tags = {
    Name = "nat-${local.namespace}"
  }
}

# 프라이빗 RT에 NAT 경로 추가 (core 가 관리하는 RT에 route만 추가)
resource "aws_route" "private_nat" {
  route_table_id         = local.core.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

module "ecr" {
  source = "./ecr"

  namespace          = local.namespace
  repository_names   = var.ecr_repository_names
  image_scan_on_push = var.ecr_image_scan_on_push
}

module "eks" {
  source = "./eks"

  namespace                 = local.namespace
  kubernetes_version        = var.eks_kubernetes_version
  endpoint_public_access    = var.eks_endpoint_public_access
  endpoint_private_access   = var.eks_endpoint_private_access
  public_access_cidrs       = var.eks_public_access_cidrs
  cluster_service_ipv4_cidr = var.eks_service_cidr
  subnet_ids                = local.core.eks_subnet_ids
  cluster_security_group_id = local.core.eks_cluster_sg_id
  node_security_group_id    = local.core.eks_node_sg_id
  node_groups               = var.eks_node_groups

  depends_on = [aws_nat_gateway.main, aws_route.private_nat]
}
data "terraform_remote_state" "core" {
  backend = "s3"

  config = {
    bucket = "tfstate-azsis-kbeauty"
    key    = "aws/core/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

module "nat" {
  source = "./nat"

  namespace              = var.namespace
  public_subnet_id       = data.terraform_remote_state.core.outputs.public_subnet_ids[0]
  private_route_table_id = data.terraform_remote_state.core.outputs.private_route_table_id
}
