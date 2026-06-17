output "cloudfront_domain" {
  value = module.cloudfront.cloudfront_domain
}

output "vpn_tunnel1_address" {
  value     = length(module.vpn) > 0 ? module.vpn[0].tunnel1_address : ""
  sensitive = false
}

output "vpn_psk" {
  value     = length(module.vpn) > 0 ? module.vpn[0].psk : ""
  sensitive = true
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

# 워크플로우에 넣을 Role ARN 출력
output "github_actions_role_arn" {
  value = module.github_oidc.github_actions_role_arn
}
