variable "namespace" {
  type = string
}

#network 모듈에서 받아노는 RDS 서브넷 ID 목록
variable "rds_subnet_ids" {
  type = list(string)
}

#security 모듈에서 받아오는 RDS 보안그룹 ID
variable "rds_sg_id" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
  sensitive = true  #플랜/로그에서 값 숨기
}