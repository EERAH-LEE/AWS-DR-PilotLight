#DMS 복제 인스턴스 ARN - 복제 태스크 생성 시 필요
output "replication_instance_arn" {
    value = aws_dms_replication_instance.main.replication_instance_arn
}

#소스 엔드포인트 ARN - 복제 태스크에서 참조
output "source_endpoint_arn" {
    value = aws_dms_endpoint.source.endpoint_arn
}

#대상 엔드포인트 ARN - 복제 태스크에서 참조
output "target_endpoint_arn" {
    value = aws_dms_endpoint.target.endpoint_arn
}

#복제 태스크 ARN - 나중에 태스크 시작/중지 시 참조용
output "replication_task_arn" {
  value = aws_dms_replication_task.main.replication_task_arn
}