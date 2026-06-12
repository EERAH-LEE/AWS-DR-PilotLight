#RDS 엔드포인트 - DMS 모듈에서 타켓 연결 시 사용
output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

#RDS 포트
output "rds_port" {
  value = aws_db_instance.main.port
}