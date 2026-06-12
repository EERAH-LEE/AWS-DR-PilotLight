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
  instance_class = "db.t3.micro"
  allocated_storage = 20

  db_name = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]

  skip_final_snapshot = true #테스트용, 삭제 시 스냅샷 안찍음

  tags = {
    Name = "mysql-${var.namespace}"
  }
}