variable "namespace" {
  type = string
}

#DMS 보안 그룹 ID - security 모듈에서 받아옴
variable "dms_sg_id" {
  type = string
}

#DMS가 위치할 서브넷 ID - network 모듈에서 받아옴
variable "subnet_ids" {
  type = list(string)
}

#소스(Azure MySQL) 접속 정보
variable "source_host" {
  type = string
}

variable "source_username" {
  type = string
}

variable "source_password" {
  type = string
  sensitive = true
}

#대상(AWS RDS) 접속 정보
variable "target_endpoint" {
  type = string
}

variable "target_username" {
  type = string
}

variable "target_password" {
  type = string
  sensitive = true
}