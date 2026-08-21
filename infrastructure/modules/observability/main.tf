resource "azurerm_log_analytics_workspace" "this" {
  name                         = var.log_analytics_workspace_name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  sku                          = "PerGB2018"
  retention_in_days            = var.log_analytics_retention_in_days
  local_authentication_enabled = false
  tags                         = var.tags
}

resource "azurerm_monitor_workspace" "this" {
  name                          = var.monitor_workspace_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags
}

resource "azurerm_monitor_data_collection_endpoint" "prometheus" {
  name                          = "MSProm-${var.aks_name}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "Linux"
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags
}

resource "azurerm_monitor_data_collection_rule" "prometheus" {
  name                        = "MSProm-${var.aks_name}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  kind                        = "Linux"
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prometheus.id
  tags                        = var.tags

  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  destinations {
    monitor_account {
      name               = "AzureMonitorWorkspace"
      monitor_account_id = azurerm_monitor_workspace.this.id
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["AzureMonitorWorkspace"]
  }
}

resource "azurerm_dashboard_grafana" "this" {
  name                              = var.grafana_name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  api_key_enabled                   = false
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = var.grafana_public_network_access_enabled
  sku                               = "Standard"
  grafana_major_version             = 11
  tags                              = var.tags

  identity { type = "SystemAssigned" }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.this.id
  }
}
