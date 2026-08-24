output "aks_subnet_id" { value = azurerm_subnet.aks.id }
output "private_endpoints_subnet_id" { value = azurerm_subnet.private_endpoints.id }
output "firewall_subnet_id" { value = var.firewall_enabled ? azurerm_subnet.firewall[0].id : null }
output "vnet_id" { value = azurerm_virtual_network.this.id }
output "key_vault_private_dns_zone_id" { value = azurerm_private_dns_zone.key_vault.id }
