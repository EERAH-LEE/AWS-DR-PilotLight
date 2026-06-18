#RDS 서브넷 그룹 - RDS가 위치할 서브넷 지정 
resource "aws_db_subnet_group" "main" {
  name = "subnetgroup-${var.namespace}"
  subnet_ids = var.rds_subnet_ids

  tags = {
    Name = "subnetgroup-${var.namespace}"
  }
}

#RDS MySQL 인스턴스 - Pilot Light DR용, 항상 on
resource "aws_db_instance" "main" {
  identifier = "mysql-${var.namespace}"
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.small"
  allocated_storage = 20

  db_name = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]

  skip_final_snapshot = true #테스트용, 삭제 시 스냅샷 안찍음
  parameter_group_name = aws_db_parameter_group.main.name


  tags = {
    Name = "mysql-${var.namespace}"
  }
}


####역뱡향용####
# RDS 파라미터 그룹 - DMS 소스로 사용하기 위한 binlog 설정
resource "aws_db_parameter_group" "main" {
  name   = "pg-${var.namespace}"
  family = "mysql8.0"

  # 커넥션 수 제한 증가 (DMS + 앱 동시 접속 대비)
  parameter {
    name  = "max_connections"
    value = "200"
  }

  # DMS CDC가 읽을 수 있는 바이너리 로그 형식 (ROW 필수)
  parameter {
    name  = "binlog_format"
    value = "ROW"
    apply_method = "pending-reboot"
  }

  # DMS binlog 읽기 시 체크섬 검증 비활성화
  parameter {
    name  = "binlog_checksum"
    value = "NONE"
    apply_method = "pending-reboot"
  }
}
