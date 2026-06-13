variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}


# Azure DB 정보
variable "azure_mysql_host" {
  type = string
}

variable "azure_mysql_username" {
  type = string
}

variable "azure_mysql_password" {
  type      = string
  sensitive = true
}

#Azure Traffic Manager DNS
variable "azure_endpoint" {
  type = string
}