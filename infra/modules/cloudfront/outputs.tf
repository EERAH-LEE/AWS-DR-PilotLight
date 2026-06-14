# CloudFront 도메인 - Azure TM 외부 엔드포인트로 등록할 주소
output "cloudfront_domain" {
  value = aws_cloudfront_distribution.main.domain_name
}

# CloudFront 배포 ID - 나중에 캐시 무효화 시 필요
output "cloudfront_id" {
  value = aws_cloudfront_distribution.main.id
}
