output "nat_gateway_id" {
  value = module.nat.nat_gateway_id
}

output "nat_eip_public_ip" {
  value = module.nat.nat_eip_public_ip
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_node_group_names" {
  value = module.eks.node_group_names
}
