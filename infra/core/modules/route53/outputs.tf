#헬스체크 ID - CloudWatch 알람 연동 시 참조용
output "health_check_id" {
  value = aws_route53_health_check.wactch-azure.id
}