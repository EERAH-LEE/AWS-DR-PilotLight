variable "namespace" {
  type = string
}

#헬스체크할 Azure의 퍼블릭 도메인 or IP
variable "azure_endpoint" {
  type = string
  description = "Azure 앞단 도메인 또는 IP"
}