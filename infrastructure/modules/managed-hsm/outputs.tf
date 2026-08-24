output "id" { value = azurerm_key_vault_managed_hardware_security_module.this.id }
output "name" { value = azurerm_key_vault_managed_hardware_security_module.this.name }
output "hsm_uri" { value = azurerm_key_vault_managed_hardware_security_module.this.hsm_uri }
output "signing_key_id" { value = var.signing_key_enabled ? azurerm_key_vault_managed_hardware_security_module_key.signing[0].id : null }
output "signing_key_versioned_id" { value = var.signing_key_enabled ? azurerm_key_vault_managed_hardware_security_module_key.signing[0].versioned_id : null }
