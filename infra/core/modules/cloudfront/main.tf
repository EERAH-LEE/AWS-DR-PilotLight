#----------------------------------------------------
#OAC (Origin Access Control)
#CloudFront가 s3에 비공개로 접근하기 위한 인증 설정
#과거엔 OAI(Identity)를 썼지만 현재는 OAC가 표준
#퍼블릭 접근 없이 CloudFront만 s3 읽을 수 있게 함
#----------------------------------------------------
resource "aws_cloudfront_origin_access_control" "cf-s3" {
  name                              = "oac-s3-${var.namespace}"
  origin_access_control_origin_type = "s3"     # 오리진 타입 : s3
  signing_behavior                  = "always" #항상 서명해서 요청
  signing_protocol                  = "sigv4"  #AWS 서명 방식
}


#----------------------------------------------------
#s3버킷 정책
#위 CloudFront OAC를 통한 요청만 s3 일기 허용
#이 정책 없으면 CF가 S3 파일을 못 읽음
#----------------------------------------------------
resource "aws_s3_bucket_policy" "cf-s3" {
  bucket = var.bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" } #CloudFront 서비스만
      Action    = "s3:GetObject"                           #읽기만 허용
      Resource  = "${var.bucket_arn}/*"                    #버킷 내 모든 파일
      Condition = {
        StringEquals = {
          # 이 CloudFront 배포에서 오는 요청만 허용
          "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
        }
      }
    }]
  })
}


#-------------------------------------------------------
#CloudFront 배포
#전 세계 엣지 서버에 캐싱 + 오리진으로 요청 전달하는 CDN
#-------------------------------------------------------
resource "aws_cloudfront_distribution" "main" {
  aliases = var.aliases

  #오리진 1 : s3 - 항상 존재 (점검 페이지)
  origin {
    origin_id                = "s3-origin"                #이 오리진을 구분하는 ID
    domain_name              = var.bucket_regional_domain #s3 버킷 도메인
    origin_access_control_id = aws_cloudfront_origin_access_control.cf-s3.id
  }


  #오리진 2 : EKS ALB  (DR 시에만 존재)
  #eks_alb_dns 변수가 비어있으면 이 블록 자체를 생성 안 함
  #DR 활성화 후 eks_alb_dns 값 넣고 재 apply 하면 오리진 추가됨
  dynamic "origin" {
    for_each = var.eks_alb_dns != "" ? [1] : []
    content {
      origin_id   = "eks-alb-origin"
      domain_name = var.eks_alb_dns
      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  #오리진 그룹(DR 시에만 존재) - EKS ALB(Primary) -> S3(Failback)
  # eks_alb_dns 있을 때만 생성
  # eks가 5xx 에러 응답 시 자동으로 s3로 전환
  dynamic "origin_group" {
    for_each = var.eks_alb_dns != "" ? [1] : []
    content {
      origin_id = "origin-group"
      failover_criteria {
        status_codes = [500, 502, 503, 504] # 이 에러 응답 시 s3로 failover
      }
      member { origin_id = "eks-alb-origin" } #1순위 EKS ALB
      member { origin_id = "s3-origin" }      #2순위 s3 점검 페이지
    }
  }

  #기본 캐시 동작
  #어떤 오리진으로 요청을 보낼지 결정
  default_cache_behavior {
    #EKS 있으면 origin-group, 없으면 s3-origin으로 직접
    target_origin_id = var.eks_alb_dns != "" ? "origin-group" : "s3-origin"

    viewer_protocol_policy = "redirect-to-https" # HTTP->HTTPS 리디렉트
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false         #쿼리스트링 오리진에 전달 안함(캐시 효율)
      cookies { forward = "none" } # 쿠키 전달 안 함
    }
  }

  enabled             = true
  default_root_object = "index.html" #루트 접근 시 s3의 index.html 반환

  restrictions {
    geo_restriction { restriction_type = "none" } #지역 제한 없음
  }

  # 커스텀 도메인을 쓰는 경우 us-east-1 ACM 인증서를 연결한다.
  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == ""
    acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    ssl_support_method             = var.acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.acm_certificate_arn != "" ? "TLSv1.2_2021" : null
  }

  tags = {
    Name = "cf-${var.namespace}"
  }
}

#뜻
#오리진 -> CF가 콘텐츠를 가져오는 원본 서버
# 사용자 -> CF (엣지 서버) -> 오리진 (실제 데이터 있는 곳)
#CF는 전 세계 엣지 서버에 캐싱하고, 없으면 오리진에서 가져옴, 현재 오리진 서버는 두개
# 기본 캐시 동작 -> 들어오는 요청을 어떻게 처리할지 규칙
