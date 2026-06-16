#Route53 헬스체크 - Azure가 살아있는지 주기적으로 확인
#헬스체크가 실패하면 DR 전환 트리거로 활용

resource "aws_route53_health_check" "wactch-azure" {
  fqdn              = var.azure_endpoint #헬스체크할 Azure 도메인/IP
  port              = 80
  type              = "HTTP"    # HTTP로 상태 확인
  resource_path     = "/health" #Spring BOOT HealthController 엔드포인트
  failure_threshold = 3         # 3번 연속 실패 시 비정상으로 판단
  request_interval  = 30        # 30초마다 체크

  tags = {
    Name = "route53-hc-${var.namespace}"
  }
}


#Route53 헬스체크는 VPN 안탐. 공인 인터넷에서 직접 찌르는 방식이라 Azure의 퍼블릭 엔드포인트를 대상으로 해야한다
#지금은 테스트 단계랑 80,http 쓰지만 나중에 SSL 있으면 443,https로 바꿔서 해야한다
#WAS /health -> 앱 레벨까지 확인 (가장 정확)
#LB  ->  LB까지만 살아있어도 성공 (앱 죽어도 모름)
#Application Gateway -> LB+라우팅까지 확인

#DNS → Traffic Manager → ALB → WAS → DB
#이 구조라면 TM을 헬스체크 대상으로 써야한다
#TM이 이미 ALB->WAS 헬스체크를 하고 있음
#Route53이 TM 찌르면 -> TM이 백엔드 상태 반영해서 응답
#즉 WAS까지 죽어야 비정상으로 판단되는 구조