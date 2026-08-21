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

data "azurerm_client_config" "current" {}

module "networking" {
  source                                  = "../../modules/networking"
  name                                    = "vnet-${local.name_prefix}"
  location                                = azurerm_resource_group.this.location
  resource_group_name                     = azurerm_resource_group.this.name
  address_space                           = var.vnet_address_space
  aks_subnet_address_prefix               = var.aks_subnet_address_prefix
  private_endpoints_subnet_address_prefix = var.private_endpoints_subnet_address_prefix
  tags                                    = local.common_tags
}

module "key_vault" {
  source                     = "../../modules/key-vault"
  name                       = var.key_vault_name
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  virtual_network_id         = module.networking.vnet_id
  private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id
  oidc_issuer_url            = module.aks.oidc_issuer_url
  tags                       = local.common_tags
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

module "observability" {
  source                                = "../../modules/observability"
  aks_name                              = "aks-${local.name_prefix}"
  location                              = azurerm_resource_group.this.location
  resource_group_name                   = azurerm_resource_group.this.name
  log_analytics_workspace_name          = "law-${local.name_prefix}"
  monitor_workspace_name                = "amw-${local.name_prefix}"
  grafana_name                          = "amg-${local.name_prefix}"
  log_analytics_retention_in_days       = var.log_analytics_retention_in_days
  public_network_access_enabled         = var.observability_public_network_access_enabled
  grafana_public_network_access_enabled = var.grafana_public_network_access_enabled
  tags                                  = local.common_tags
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
  log_analytics_workspace_id      = module.observability.log_analytics_workspace_id
  prometheus_annotations_allowed  = null
  prometheus_labels_allowed       = null
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

resource "azurerm_monitor_data_collection_rule_association" "aks_prometheus" {
  name                    = "MSProm-${module.aks.name}"
  target_resource_id      = module.aks.id
  data_collection_rule_id = module.observability.prometheus_data_collection_rule_id
}

resource "azurerm_role_assignment" "aks_monitoring_metrics_publisher" {
  scope                = module.observability.prometheus_data_collection_rule_id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = module.aks.identity_principal_id
}

resource "azurerm_role_assignment" "grafana_monitor_workspace_reader" {
  scope                = module.observability.monitor_workspace_id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = module.observability.grafana_principal_id
}

resource "azurerm_role_assignment" "grafana_log_analytics_reader" {
  scope                = module.observability.log_analytics_workspace_id
  role_definition_name = "Log Analytics Reader"
  principal_id         = module.observability.grafana_principal_id
}

resource "azurerm_role_assignment" "grafana_aks_monitoring_reader" {
  scope                = module.aks.id
  role_definition_name = "Monitoring Reader"
  principal_id         = module.observability.grafana_principal_id
}

resource "azurerm_role_assignment" "grafana_admins" {
  count = var.grafana_admin_group_object_id == null ? 0 : 1

  scope                = module.observability.grafana_id
  role_definition_name = "Grafana Admin"
  principal_id         = var.grafana_admin_group_object_id
}

data "azurerm_monitor_diagnostic_categories" "aks" {
  resource_id = module.aks.id
}

data "azurerm_monitor_diagnostic_categories" "acr" {
  resource_id = module.acr.id
}

locals {
  aks_diagnostic_log_categories = setintersection(
    toset(data.azurerm_monitor_diagnostic_categories.aks.log_category_types),
    toset(["kube-apiserver", "kube-audit", "kube-audit-admin", "kube-controller-manager", "kube-scheduler", "cluster-autoscaler", "guard"])
  )
  acr_diagnostic_log_categories = setintersection(
    toset(data.azurerm_monitor_diagnostic_categories.acr.log_category_types),
    toset(["ContainerRegistryLoginEvents", "ContainerRegistryRepositoryEvents"])
  )
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "diag-${module.aks.name}"
  target_resource_id         = module.aks.id
  log_analytics_workspace_id = module.observability.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = local.aks_diagnostic_log_categories
    content {
      category = enabled_log.value
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "acr" {
  name                       = "diag-${module.acr.name}"
  target_resource_id         = module.acr.id
  log_analytics_workspace_id = module.observability.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = local.acr_diagnostic_log_categories
    content {
      category = enabled_log.value
    }
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "container_restarts" {
  name                 = "alert-${local.name_prefix}-container-restarts"
  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  display_name         = "Excessive container restarts"
  description          = "Detects containers with three or more restarts in the last 15 minutes. Investigate application failures, probe failures, and recent deployment changes."
  scopes               = [module.observability.log_analytics_workspace_id]
  severity             = 2
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  tags                 = local.common_tags

  criteria {
    query                   = <<-KQL
      KubePodInventory
      | where TimeGenerated > ago(15m)
      | summarize RestartCount = max(ContainerRestartCount) by ClusterName, Namespace, Name, ContainerName
      | where RestartCount >= 3
    KQL
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  dynamic "action" {
    for_each = length(var.alert_action_group_ids) > 0 ? [1] : []
    content {
      action_groups = var.alert_action_group_ids
    }
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "demo_availability" {
  name                 = "alert-${local.name_prefix}-demo-availability"
  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  display_name         = "Demo API has no running pods"
  description          = "Detects when no demo API pod is running. Investigate deployment status, scheduling, image pulls, and application startup failures."
  scopes               = [module.observability.log_analytics_workspace_id]
  severity             = 1
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  tags                 = local.common_tags

  criteria {
    query                   = <<-KQL
      KubePodInventory
      | where TimeGenerated > ago(15m)
      | where Namespace == "demo" and Name startswith "demo-api-"
      | summarize RunningPods = dcountif(Name, PodStatus == "Running") by ClusterName, Namespace
      | where RunningPods < 1
    KQL
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  dynamic "action" {
    for_each = length(var.alert_action_group_ids) > 0 ? [1] : []
    content {
      action_groups = var.alert_action_group_ids
    }
  }
}
