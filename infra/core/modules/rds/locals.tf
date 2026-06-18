locals {
  engine_version   = "8.0"
  instance_class   = "db.t3.small"
  max_connections  = 200
  apply_immediately = true
  backup_retention_period = 1  # 1일 이상 설정해야 log_bin = ON

}
