output "cloudfront_domain" {
  value = module.cloudfront.cloudfront_domain
}

# dr/ 에서 data.terraform_remote_state.core 로 읽어갈 값들
output "vpc_id" {
  value = module.network.vpc_id
}

output "eks_subnet_ids" {
  value = module.network.eks_subnet_ids
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_route_table_id" {
  value = module.network.private_route_table_id
}

output "eks_cluster_sg_id" {
  value = module.security.eks_cluster_sg_id
}

output "eks_node_sg_id" {
  value = module.security.eks_node_sg_id
}
