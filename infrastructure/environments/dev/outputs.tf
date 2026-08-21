output "resource_group_name" { value = azurerm_resource_group.this.name }
output "aks_name" { value = module.aks.name }
output "aks_fqdn" { value = module.aks.fqdn }
output "acr_name" { value = module.acr.name }
output "acr_login_server" { value = module.acr.login_server }
output "aks_oidc_issuer_url" { value = module.aks.oidc_issuer_url }
output "aks_kubelet_identity_object_id" { value = module.aks.kubelet_identity_object_id }
