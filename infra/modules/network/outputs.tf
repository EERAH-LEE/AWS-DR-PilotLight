#다른 모듈에서 참조할 때 사용
output "vpc_id" {
  value = aws_vpc.main.id
}

# EKS 서브넷 ID 목록
output "eks_subnet_ids" {
    value = aws_subnet.eks[*].id
}

# RDS 서브넷 ID 목록
output "rds_subnet_ids" {
  value = aws_subnet.rds[*].id
}