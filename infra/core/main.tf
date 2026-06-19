module "network" {
  source    = "./modules/network"
  namespace = local.namespace
}

module "security" {
  source    = "./modules/security"
  namespace = local.namespace
  vpc_id    = module.network.vpc_id
}

module "rds" {
  source         = "./modules/rds"
  namespace      = local.namespace
  rds_subnet_ids = module.network.rds_subnet_ids
  rds_sg_id      = module.security.rds_sg_id
  db_name        = var.db_name
  db_username    = var.db_username
  db_password    = var.db_password
}

module "dms" {
  source    = "./modules/dms"
  namespace = local.namespace

  dms_sg_id  = module.security.dms_sg_id
  subnet_ids = module.network.eks_subnet_ids

  source_host     = var.azure_mysql_host
  source_username = var.azure_mysql_username
  source_password = var.azure_mysql_password

  target_endpoint = module.rds.rds_endpoint
  target_username = var.db_username
  target_password = var.db_password
}


module "s3" {
  source    = "./modules/s3"
  namespace = local.namespace
}

module "cloudfront" {
  source    = "./modules/cloudfront"
  namespace = local.namespace

  bucket_name            = module.s3.bucket_name
  bucket_arn             = module.s3.bucket_arn
  bucket_regional_domain = module.s3.bucket_regional_domain
  aliases                = ["www.sue019522.shop"]
  acm_certificate_arn    = "arn:aws:acm:us-east-1:946775837287:certificate/331d02d7-2d43-4606-8d44-8bc0e6456dad"
  
  #eks주소를 CF 등록
  eks_alb_dns = var.eks_alb_dns
}

module "vpn" {
  source    = "./modules/vpn"
  namespace = local.namespace

  vpc_id                 = module.network.vpc_id
  private_route_table_id = module.network.private_route_table_id
  azure_vpn_gateway_ip   = var.azure_vpn_gateway_ip
  azure_vnet_cidr        = var.azure_vnet_cidr

  count = var.azure_vpn_gateway_ip != "" ? 1 : 0
}

module "dr_trigger" {
  source = "./modules/dr_trigger"

  namespace              = local.namespace
  azure_agw_fqdn         = var.azure_agw_fqdn
  

  slack_webhook_url = var.slack_webhook_url
}

module "github_oidc" {
  source = "./modules/github_oidc"

  namespace   = local.namespace
  github_repo = "bespin-multi-cloud-3-azure/final_pj_aws"
}
