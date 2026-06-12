#output 이름은 자유롭게 쓰되, 루트 main.tf에서 참조할 때 동일한 이름으로 써야함.
#RDS 보안그룹 ID - rds 모듈에서 참조
output "rds_sg_id" {
  value = aws_security_group.rds.id
}

#DMS 보안그룹 ID - dms 모듈에서 참조
output "dms_sg_id" {
  value = aws_security_group.dms.id
}