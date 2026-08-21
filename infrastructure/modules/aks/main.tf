resource "azurerm_kubernetes_cluster" "this" {
  name                              = var.name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  dns_prefix                        = var.dns_prefix
  kubernetes_version                = var.kubernetes_version
  role_based_access_control_enabled = true
  local_account_disabled            = true
  azure_policy_enabled              = false
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  private_cluster_enabled           = var.private_cluster_enabled
  tags                              = var.tags

  identity { type = "SystemAssigned" }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  api_server_access_profile {
    authorized_ip_ranges = var.private_cluster_enabled ? [] : var.api_server_authorized_ip_ranges
  }

  default_node_pool {
    name                 = "system"
    vm_size              = var.system_node_vm_size
    vnet_subnet_id       = var.subnet_id
    auto_scaling_enabled = true
    min_count            = var.system_node_min_count
    max_count            = var.system_node_max_count
    max_pods             = 30
    os_disk_type         = "Managed"
    os_disk_size_gb      = 128
    upgrade_settings { max_surge = "33%" }
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
  }

  lifecycle {
    precondition {
      condition     = var.private_cluster_enabled || length(var.api_server_authorized_ip_ranges) > 0
      error_message = "Public AKS API access requires one or more authorized IP ranges."
    }
  }
}
