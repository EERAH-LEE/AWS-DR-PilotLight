# RDS 보안그룹 - DMS 인스턴스에서만 3306 접속 허용
resource "aws_security_group" "rds" {
    name = "nsg-${var.namespace}-rds"
    vpc_id = var.vpc_id

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.dms.id] #DMS sg에서만 허용
        description = "MySQL from DMS"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"  #전체를 의미 (TCP,UDP,ICMP 등 전부)
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "nsg-${var.namespace}-rds"
    }
}

# DMS 보안그룹 - Azure VPN CIDR에서 오는 트래픽 허용
resource "aws_security_group" "dms" {
    name = "nsg-${var.namespace}-dms"
    vpc_id = var.vpc_id

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "nsg-${var.namespace}-dms"
    }
}

# EKS control plane security group.
resource "aws_security_group" "eks_cluster" {
    name = "nsg-${var.namespace}-eks-cluster"
    vpc_id = var.vpc_id

#어플라이테스트때문에 잠시 주석처리함 -가영
#    ingress {
#        from_port = 443
#        to_port = 443
#        protocol = "tcp"
#        security_groups = [aws_security_group.eks_node.id]
#        description = "Kubernetes API from EKS worker nodes"
#    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "nsg-${var.namespace}-eks-cluster"
    }
}

# EKS worker node security group.
resource "aws_security_group" "eks_node" {
    name = "nsg-${var.namespace}-eks-node"
    vpc_id = var.vpc_id

    ingress {
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        self        = true
        description = "Node-to-node traffic"
    }

    ingress {
        from_port   = 53
        to_port     = 53
        protocol    = "udp"
        self        = true
        description = "Node-to-node DNS UDP"
    }  

    ingress {
        from_port       = 1025
        to_port         = 65535
        protocol        = "tcp"
        security_groups = [aws_security_group.eks_cluster.id]
        description     = "Control plane to kubelet and pods"
    }
        
#어플라이테스트때문에 잠시 주석처리함 -가영
#    ingress {
#        from_port = 1025
#        to_port = 65535
#        protocol = "tcp"
#        security_groups = [aws_security_group.eks_cluster.id]
#        description = "Control plane to kubelet and pods"
#    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP ingress"
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTPS ingress"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "nsg-${var.namespace}-eks-node"
    }
}

#cycle 에러로 밑에 두개 잠깐 추가함 어플라이진행용 -가영
resource "aws_security_group_rule" "eks_cluster_ingress_from_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_node.id
  description              = "Kubernetes API from EKS worker nodes"
}