resource "azurerm_container_registry" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = false
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  dynamic "identity" {
    for_each = var.customer_managed_key_enabled ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.encryption_identity_id]
    }
  }

  dynamic "encryption" {
    for_each = var.customer_managed_key_enabled ? [1] : []
    content {
      identity_client_id = var.encryption_identity_client_id
      key_vault_key_id   = var.customer_managed_key_id
    }
  }

  lifecycle {
    precondition {
      condition     = !var.private_endpoint_enabled || (var.sku == "Premium" && !var.public_network_access_enabled)
      error_message = "ACR Private Link requires the Premium SKU and public network access disabled."
    }
    precondition {
      condition     = !var.private_endpoint_enabled || (var.private_endpoint_subnet_id != null && var.virtual_network_id != null)
      error_message = "ACR Private Link requires a private endpoint subnet and virtual network ID."
    }
    precondition {
      condition     = !var.customer_managed_key_enabled || var.sku == "Premium"
      error_message = "ACR customer-managed keys require the Premium SKU."
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
