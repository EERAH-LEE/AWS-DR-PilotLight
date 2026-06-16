#버킷 이름 - CloudFront origin 설정 시 필요
output "bucket_name" {
  value = aws_s3_bucket.dr-webpage.bucket
}


#버킷 ARN - CloudFront OAC 정책 설정 시 필요
output "bucket_arn" {
  value = aws_s3_bucket.dr-webpage.arn
}


#버킷 도메인 - CloudFront origin domain으로 사용
output "bucket_regional_domain" {
  value = aws_s3_bucket.dr-webpage.bucket_regional_domain_name
}