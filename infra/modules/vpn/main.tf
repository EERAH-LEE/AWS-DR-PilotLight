# -----------------------------------------------
# Virtual Private Gateway (VGW)
# AWS VPC 측 VPN 엔드포인트
# VPC에 붙여서 VPN 트래픽을 수신하는 역할
# -----------------------------------------------
resource "aws_vpn_gateway" "main" {
  vpc_id = var.vpc_id

  tags = {
    Name = "vgw-${var.namespace}"
  }
}

# -----------------------------------------------
# Customer Gateway (CGW)
# Azure VPN Gateway를 AWS에 등록하는 리소스
# Azure VPN Gateway의 퍼블릭 IP가 필요함
# Azure 포털: VPN Gateway → 개요 → 공용 IP 주소
# -----------------------------------------------
resource "aws_customer_gateway" "azure" {
  bgp_asn    = 65515        # Azure VPN Gateway 기본 ASN
  ip_address = var.azure_vpn_gateway_ip
  type       = "ipsec.1"

  tags = {
    Name = "cgw-${var.namespace}-azure"
  }
}

# -----------------------------------------------
# Site-to-Site VPN Connection
# VGW(AWS) ↔ CGW(Azure) 사이의 실제 IPsec 터널
# static_routes_only = true → BGP 없이 정적 라우팅 사용
# AWS는 자동으로 터널 2개 생성 (Active/Standby 이중화)
# -----------------------------------------------
resource "aws_vpn_connection" "azure" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.azure.id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name = "vpn-${var.namespace}-azure"
  }
}

# -----------------------------------------------
# VPN 정적 라우트
# Azure VNet CIDR → VPN 터널로 보내도록 등록
# DMS가 Azure MySQL IP로 패킷 보낼 때 이 경로로 나감
# -----------------------------------------------
resource "aws_vpn_connection_route" "azure_vnet" {
  vpn_connection_id      = aws_vpn_connection.azure.id
  destination_cidr_block = var.azure_vnet_cidr  # 예: "10.0.0.0/16"
}

# -----------------------------------------------
# VPN 경로 전파 (Route Propagation)
# VGW가 알고 있는 경로를 EKS 프라이빗 RT에 자동으로 추가
# 이게 없으면 DMS → Azure 방향 패킷이 어디로 가야할지 모름
# -----------------------------------------------
resource "aws_vpn_gateway_route_propagation" "eks" {
  vpn_gateway_id = aws_vpn_gateway.main.id
  route_table_id = var.private_route_table_id
}


# PSK 자동 생성
resource "random_password" "vpn_psk" {
  length  = 32
  special = false   # VPN PSK는 영숫자만 허용
}

#테라폼 어플라이시도로 중복내용 잠시 주석처리함 -가영
#resource "aws_vpn_connection" "azure" {
#  vpn_gateway_id      = aws_vpn_gateway.main.id
#  customer_gateway_id = aws_customer_gateway.azure.id
#  type                = "ipsec.1"
#  static_routes_only  = true
#
#  tunnel1_preshared_key = random_password.vpn_psk.result  # PSK 직접 지정
#
#  tags = {
#    Name = "vpn-${var.namespace}-azure"
#  }
#}
