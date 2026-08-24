output "disk_encryption_set_id" { value = azurerm_disk_encryption_set.aks.id }
output "key_vault_id" { value = azurerm_key_vault.this.id }
output "key_vault_name" { value = azurerm_key_vault.this.name }
output "key_id" { value = azurerm_key_vault_key.platform_encryption.versionless_id }
