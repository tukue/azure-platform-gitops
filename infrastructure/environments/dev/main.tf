locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = merge({
    environment = var.environment
    managed-by  = "terraform"
    project     = var.project
  }, var.tags)
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}

module "networking" {
  source                    = "../../modules/networking"
  name                      = "vnet-${local.name_prefix}"
  location                  = azurerm_resource_group.this.location
  resource_group_name       = azurerm_resource_group.this.name
  address_space             = var.vnet_address_space
  aks_subnet_address_prefix = var.aks_subnet_address_prefix
  tags                      = local.common_tags
}

module "acr" {
  source                        = "../../modules/acr"
  name                          = var.acr_name
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  sku                           = var.acr_sku
  public_network_access_enabled = var.acr_public_network_access_enabled
  tags                          = local.common_tags
}

module "aks" {
  source                          = "../../modules/aks"
  name                            = "aks-${local.name_prefix}"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  dns_prefix                      = "aks-${local.name_prefix}"
  kubernetes_version              = var.kubernetes_version
  subnet_id                       = module.networking.aks_subnet_id
  admin_group_object_ids          = var.admin_group_object_ids
  private_cluster_enabled         = var.private_cluster_enabled
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
  system_node_vm_size             = var.system_node_vm_size
  system_node_min_count           = var.system_node_min_count
  system_node_max_count           = var.system_node_max_count
  tags                            = local.common_tags
}

resource "azurerm_role_assignment" "aks_kubelet_acr_pull" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}

resource "azurerm_role_assignment" "github_actions_acr_push" {
  count = var.github_actions_principal_id == null ? 0 : 1

  scope                = module.acr.id
  role_definition_name = "AcrPush"
  principal_id         = var.github_actions_principal_id
}
