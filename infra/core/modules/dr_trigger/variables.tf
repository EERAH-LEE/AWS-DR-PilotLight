variable "namespace" {
  type = string
}

# 감시할 Azure AGW 주소
variable "azure_agw_fqdn" {
  type        = string
  description = "Azure Application Gateway FQDN or 공인 IP"
}




# 헬스체크 주기 (분)
variable "check_interval_minutes" {
  type    = number
  default = 5
}

# 장애 판단 기준 (분)
variable "alarm_minutes" {
  type    = number
  default = 15
}

# Slack Incoming Webhook URL
variable "slack_webhook_url" {
  type      = string
  sensitive = true
}
