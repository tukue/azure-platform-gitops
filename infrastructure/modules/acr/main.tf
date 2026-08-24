resource "azurerm_container_registry" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = false
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  lifecycle {
    precondition {
      condition     = !var.private_endpoint_enabled || (var.sku == "Premium" && !var.public_network_access_enabled)
      error_message = "ACR Private Link requires the Premium SKU and public network access disabled."
    }
    precondition {
      condition     = !var.private_endpoint_enabled || (var.private_endpoint_subnet_id != null && var.virtual_network_id != null)
      error_message = "ACR Private Link requires a private endpoint subnet and virtual network ID."
    }
  }
}

resource "azurerm_private_dns_zone" "acr" {
  count = var.private_endpoint_enabled ? 1 : 0

  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  count = var.private_endpoint_enabled ? 1 : 0

  name                  = "pdnslink-${var.name}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "acr" {
  count = var.private_endpoint_enabled ? 1 : 0

  name                = "pep-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.name}"
    private_connection_resource_id = azurerm_container_registry.this.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr[0].id]
  }
}
