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

module "ecr" {
  source = "./ecr"

  namespace          = var.namespace
  repository_names   = var.ecr_repository_names
  image_scan_on_push = var.ecr_image_scan_on_push
}

module "eks" {
  source = "./eks"

  namespace                                   = var.namespace
  kubernetes_version                          = var.eks_kubernetes_version
  endpoint_public_access                      = var.eks_endpoint_public_access
  endpoint_private_access                     = var.eks_endpoint_private_access
  public_access_cidrs                         = var.eks_public_access_cidrs
  cluster_service_ipv4_cidr                   = var.eks_service_cidr
  bootstrap_cluster_creator_admin_permissions = var.eks_bootstrap_cluster_creator_admin_permissions
  admin_principal_arns                        = var.eks_admin_principal_arns
  subnet_ids                                  = data.terraform_remote_state.core.outputs.eks_subnet_ids
  cluster_security_group_id                   = data.terraform_remote_state.core.outputs.eks_cluster_sg_id
  node_security_group_id                      = data.terraform_remote_state.core.outputs.eks_node_sg_id
  node_groups                                 = var.eks_node_groups
}

resource "aws_security_group_rule" "node_ingress_kubelet_from_eks_cluster_sg" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = data.terraform_remote_state.core.outputs.eks_node_sg_id
  source_security_group_id = module.eks.cluster_security_group_id
  description              = "EKS managed cluster security group to kubelet"
}

resource "aws_security_group_rule" "node_ingress_lbc_webhook_from_eks_cluster_sg" {
  type                     = "ingress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  security_group_id        = data.terraform_remote_state.core.outputs.eks_node_sg_id
  source_security_group_id = module.eks.cluster_security_group_id
  description              = "EKS managed cluster security group to AWS Load Balancer Controller webhook"
}
