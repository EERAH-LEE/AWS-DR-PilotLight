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