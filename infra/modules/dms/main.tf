#DMS 서브넷 그룹 - DMS 복제 인스턴스가 위치할 서브넷
resource "aws_dms_replication_subnet_group" "name" {
  replication_subnet_group_id = "dms-subnetgroup-${var.namespace}"
  replication_subnet_group_description = "DMS subnet group for DR"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "dms-subnetgroup-${var.namespace}"
  }
}

#DMS 복제 인스턴스 - Azure MySQL -> AWS RDS 복제 엔진
resource "aws_dms_replication_instance" "main" {
  replication_instance_id = "dms-${var.namespace}"
  replication_instance_class = "dms.t3.medium"
  allocated_storage = 20

  replication_subnet_group_id = aws_dms_replication_subnet_group.name.id
  vpc_security_group_ids = [var.dms_sg_id]

  publicly_accessible = false #프라이빗 서브넷 사용

  tags = {
    Name = "dms-${var.namespace}"
  }
}

#소스 엔드포인트 - Azure MySQL
resource "aws_dms_endpoint" "source" {
  endpoint_id = "source-mysql-${var.namespace}"
  endpoint_type = "source"
  engine_name = "mysql"

  server_name = var.source_host
  port = 3306
  username = var.source_username
  password = var.source_password
  database_name = "kbeauty"

  ssl_mode = "none" #require_secure_transport OFF 설정했으므로

  tags = {
    Name = "source-mysql-${var.namespace}"
  }
}

#대상 엔드포인트 - AWS RDS MySQL
resource "aws_dms_endpoint" "target" {
  endpoint_id = "target-mysql-${var.namespace}"
  endpoint_type = "target"
  engine_name = "mysql"

  server_name = var.target_endpoint
  port = 3306
  username = var.target_username
  password = var.target_password
  database_name = "kbeauty"

  tags ={
    Name = "target-mysql-${var.namespace}"
  }
}