# Azure Blob에서 state 읽기
data "terraform_remote_state" "azure" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-azsis-kbeauty-blob"
    storage_account_name = "azsiskbeautytfstate"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
  }
}

#-----------------------------------------------------------


module "network" {
    source = "./modules/network"
    namespace = local.namespace
}

module "security" {
    source = "./modules/security"
    namespace = local.namespace
    vpc_id = module.network.vpc_id
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
  source_host     = data.external.azure_mysql_ip.result.ip # var.azure_mysql_host 대체
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

module "s3" {
  source    = "./modules/s3"
  namespace = local.namespace
}

module "cloudfront" {
  source    = "./modules/cloudfront"
  namespace = local.namespace

  # s3 모듈에서 받아오는 버킷 정보
  bucket_name            = module.s3.bucket_name
  bucket_arn             = module.s3.bucket_arn
  bucket_regional_domain = module.s3.bucket_regional_domain

  # 평상시엔 비워둠 - DR 시 EKS ALB DNS 값으로 채움
  eks_alb_dns = ""
}

module "vpn" {
  source    = "./modules/vpn"
  namespace = local.namespace

  vpc_id                 = module.network.vpc_id
  private_route_table_id = module.network.private_route_table_id

  # Azure VPN Gateway 퍼블릭 IP
  azure_vpn_gateway_ip = data.terraform_remote_state.azure.outputs.vpn_gateway_public_ip  # var.azure_vpn_gateway_ip 대체

  # Azure VNet CIDR (MySQL이 속한 대역)
  azure_vnet_cidr = var.azure_vnet_cidr
}
