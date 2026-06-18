locals {
  SUPPRESS_ALERTS = "true"  #끄고싶을때,  켜고 싶다면 "false"
  
  treat_missing_data = "notBreaching" #"notBreaching"데이터 없으면 정상으로 처리(알람 안울림)
                                      # "Breaching" 데이터 없으면 비정상으로 처리(알람 울림) 
}