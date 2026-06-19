locals {
  SUPPRESS_ALERTS = "false"           #끄고싶을때 "true",  켜고 싶다면 "false"
  
  treat_missing_data = "breaching"    #"notBreaching"데이터 없으면 정상으로 처리(알람 안울림)
                                      # "breaching" 데이터 없으면 비정상으로 처리(알람 울림) 
  
  
  
  check_interval_minutes = 5            # Lambda가 Azure AGW를 체크하는 주기(분)
  alarm_minutes = 15                    # 장애 판단 기준 15분, 이 시간 동안 연속 실패시 CW alarm 발동(분)
  period = local.check_interval_minutes * 60   # CW alarm 평가 단위 (초 단위 변환 )
                        # 연속 실패 횟수 3번
  evaluation_periods = ceil(local.alarm_minutes / local.check_interval_minutes)
}