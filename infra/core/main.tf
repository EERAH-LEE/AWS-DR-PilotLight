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

  dms_sg_id  = module.security.dms_sg_id
  subnet_ids = module.network.eks_subnet_ids

  source_host     = var.azure_mysql_host
  source_username = var.azure_mysql_username
  source_password = var.azure_mysql_password

  target_endpoint = module.rds.rds_endpoint
  target_username = var.db_username
  target_password = var.db_password
}

module "route53" {
  source = "./modules/route53"
  namespace = local.namespace

  azure_endpoint = var.azure_endpoint
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

  eks_alb_dns = ""
}

#module "vpn" {
#  source    = "./modules/vpn"
#  namespace = local.namespace
#
#  vpc_id                 = module.network.vpc_id
#  private_route_table_id = module.network.private_route_table_id
#  azure_vpn_gateway_ip   = var.azure_vpn_gateway_ip
#  azure_vnet_cidr        = var.azure_vnet_cidr
#}
