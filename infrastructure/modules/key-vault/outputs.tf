output "id" { value = azurerm_key_vault.this.id }
output "name" { value = azurerm_key_vault.this.name }
output "vault_uri" { value = azurerm_key_vault.this.vault_uri }
output "external_secrets_client_id" { value = azurerm_user_assigned_identity.external_secrets.client_id }
output "external_secrets_principal_id" { value = azurerm_user_assigned_identity.external_secrets.principal_id }
