output "tunnel1_address" {
  value = aws_vpn_connection.azure.tunnel1_address
}

output "psk" {
  value     = random_password.vpn_psk.result
  sensitive = true   # state에는 저장되지만 콘솔 출력은 숨김
}
