output "tunnel1_address" {
  value = aws_vpn_connection.azure.tunnel1_address
}

output "psk" {
  value     = aws_vpn_connection.azure.tunnel1_preshared_key
  sensitive = true
}
