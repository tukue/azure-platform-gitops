output "id" { value = azapi_resource.this.id }
output "name" { value = azapi_resource.this.name }
output "backup_identity_id" { value = azurerm_user_assigned_identity.backup.id }
output "backup_identity_principal_id" { value = azurerm_user_assigned_identity.backup.principal_id }
output "private_endpoint_id" { value = azurerm_private_endpoint.this.id }
