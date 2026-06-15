#apply 후 이 값을 Azure TM 외부 엔드포인트로 등록
output "cloudfront_domain" {
  value = module.cloudfront.cloudfront_domain
}


#---------------------------------------------------
#Azure에서 읽을 값
output "vpn_tunnel_ip" {
  value = module.vpn.tunnel1_address
}

output "cloudfront_domain" {
  value = module.cloudfront.cloudfront_domain
}

output "vpn_psk" {
  value     = module.vpn.psk
  sensitive = true

output "ecr_repository_urls" {
  description = "ECR repository URLs by repository name."
  value       = module.ecr.repository_urls
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint."
  value       = module.eks.cluster_endpoint
}

output "eks_node_group_names" {
  description = "EKS managed node group names."
  value       = module.eks.node_group_names

}
