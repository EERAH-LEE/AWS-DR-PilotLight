variable "namespace" {
  type = string
}

# 감시할 Azure AGW 주소
variable "azure_agw_fqdn" {
  type        = string
  description = "Azure Application Gateway FQDN or 공인 IP"
}



# Slack Incoming Webhook URL
variable "slack_webhook_url" {
  type      = string
  sensitive = true
}
