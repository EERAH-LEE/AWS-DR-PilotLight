variable "namespace" {
  type = string
}

# S3 모듈에서 받아오는 버킷 정보
variable "bucket_name" {
  type = string
}

variable "bucket_arn" {
  type = string
}

variable "bucket_regional_domain" {
  type = string
}

# DR 시 EKS ALB 도메인 - 없으면 빈 문자열로 두면 S3만 사용
variable "eks_alb_dns" {
  type    = string
  default = ""  # 평상시엔 비워둠, DR 시 infra_dr에서 채워줌
}
