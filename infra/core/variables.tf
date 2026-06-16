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

variable "azure_endpoint" {
  type = string
}

variable "azure_vpn_gateway_ip" {
  type    = string
  default = ""
}

variable "azure_vnet_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
