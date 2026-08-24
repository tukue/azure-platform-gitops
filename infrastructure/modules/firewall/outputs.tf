output "private_ip_address" { value = azurerm_firewall.this.ip_configuration[0].private_ip_address }
output "route_table_id" { value = azurerm_route_table.aks.id }
output "route_table_name" { value = azurerm_route_table.aks.name }
