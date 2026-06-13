#OAC - CloudFront가 s3에 비공개로 접근하기 위한 인증 설정
#퍼블릭 접근 없이 CloudFront만 s3 읽을 수 있게 함
resource "aws_cloudfront_origin_access_control" "cf-s3" {
  name                              = "oac-s3-${var.namespace}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always" #항상 서명해서 요청
  signing_protocol                  = "sigv4"  #AWS 서명 방식
}
