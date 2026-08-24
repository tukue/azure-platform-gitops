moved {
  from = module.key_vault.azurerm_private_dns_zone.key_vault
  to   = module.networking.azurerm_private_dns_zone.key_vault
}

moved {
  from = module.key_vault.azurerm_private_dns_zone_virtual_network_link.key_vault
  to   = module.networking.azurerm_private_dns_zone_virtual_network_link.key_vault
}
