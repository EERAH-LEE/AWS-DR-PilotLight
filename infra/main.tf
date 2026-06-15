module "network" {
    source = "./modules/network"
    namespace = local.namespace
}

module "security" {
    source = "./modules/security"
    namespace = local.namespace
    vpc_id = module.network.vpc_id
}

module "ecr" {
  source = "./modules/ecr"

  namespace          = local.namespace
  repository_names   = var.ecr_repository_names
  image_scan_on_push = var.ecr_image_scan_on_push
}

module "eks" {
  source = "./modules/eks"

  namespace                 = local.namespace
  kubernetes_version        = var.eks_kubernetes_version
  endpoint_public_access    = var.eks_endpoint_public_access
  endpoint_private_access   = var.eks_endpoint_private_access
  public_access_cidrs       = var.eks_public_access_cidrs
  cluster_service_ipv4_cidr = var.eks_service_cidr
  subnet_ids                = module.network.eks_subnet_ids
  cluster_security_group_id = module.security.eks_cluster_sg_id
  node_security_group_id    = module.security.eks_node_sg_id
  node_groups               = var.eks_node_groups
}

module "rds" {
  source = "./modules/rds"
  namespace = local.namespace
  rds_subnet_ids = module.network.rds_subnet_ids
  rds_sg_id = module.security.rds_sg_id
  db_name = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}

module "dms" {
  source    = "./modules/dms"
  namespace = local.namespace

  # security 모듈에서 받아오는 DMS 보안그룹
  dms_sg_id = module.security.dms_sg_id

  # network 모듈에서 받아오는 서브넷 (eks 서브넷 재사용)
  subnet_ids = module.network.eks_subnet_ids

  # 소스: Azure MySQL
  source_host     = var.azure_mysql_host
  source_username = var.azure_mysql_username
  source_password = var.azure_mysql_password

  # 대상: AWS RDS
  target_endpoint = module.rds.rds_endpoint
  target_username = var.db_username
  target_password = var.db_password
}

module "route53" {
  source = "./modules/route53"
  namespace = local.namespace

  #Azure Traffic Manager DNS 이름
  azure_endpoint = var.azure_endpoint
}
