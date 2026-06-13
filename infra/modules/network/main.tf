resource "aws_vpc" "main" {
    cidr_block = local.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
      Name = "vpc-${var.namespace}"
    }
}

# EKS 노드용 프라이빗 서브넷
resource "aws_subnet" "eks" {
  count = 2   # 서브넷 2개 만들기
  vpc_id = aws_vpc.main.id  # 위에 만든 vpc에 연결
  cidr_block = local.eks_subnet_cidrs[count.index] #[0],[1]로 구분
  availability_zone = local.AZs[count.index] #[0]=2a존, [1]=2c존

  tags = {
    Name = "subnet-${var.namespace}-eks-${count.index + 1}"
  }
}

# RDS용 프라이빗 서브넷 - RDS는 서브넷그룹에 최소 2개 AZ 필요
resource "aws_subnet" "rds" {
  count = 2 
  vpc_id = aws_vpc.main.id
  cidr_block = local.rds_subnet_cidrs[count.index]
  availability_zone = local.AZs[count.index]

  tags = {
    Name = "subnet-${var.namespace}-rds-${count.index + 1}"
  }
}

# IGW
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-${var.namespace}"
  }  
}

#Public rt
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"   # 모든 트래픽을 IGW로
    gateway_id = aws_internet_gateway.main.id
  }  

  tags = {
    Name = "rt-${var.namespace}-public"
  }
}

