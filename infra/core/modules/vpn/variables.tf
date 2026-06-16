variable "namespace" {
  type = string
}

variable "vpc_id" {
  type = string
}

# Azure VPN Gateway의 퍼블릭 IP
variable "azure_vpn_gateway_ip" {
  type = string
}

# Azure VNet 주소 공간 (DMS가 접근해야 할 대역)
variable "azure_vnet_cidr" {
  type = string
}

# EKS 서브넷 프라이빗 라우팅 테이블 ID
# network 모듈에서 받아옴
variable "private_route_table_id" {
  type = string
}
