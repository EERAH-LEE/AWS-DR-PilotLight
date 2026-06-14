#apply 후 이 값을 Azure TM 외부 엔드포인트로 등록
output "cloudfront_domain" {
  value = module.cloudfront.cloudfront_domain
}