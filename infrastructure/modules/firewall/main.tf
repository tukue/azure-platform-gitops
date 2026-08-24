resource "azurerm_public_ip" "this" {
  name                = "pip-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.zones
  tags                = var.tags
}

resource "azurerm_firewall_policy" "this" {
  name                     = "afwp-${var.name}"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  sku                      = "Standard"
  threat_intelligence_mode = "Alert"
  tags                     = var.tags

  dns {
    proxy_enabled = true
  }
}

resource "azurerm_firewall" "this" {
  name                = "afw-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.this.id
  dns_proxy_enabled   = true
  zones               = var.zones
  tags                = var.tags

  ip_configuration {
    name                 = "primary"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.this.id
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "egress" {
  name               = "platform-egress"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 100

  application_rule_collection {
    name     = "allow-required-platform-egress"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "allow-aks-control-plane"
      source_addresses      = [var.aks_subnet_address_prefix]
      destination_fqdn_tags = ["AzureKubernetesService"]

      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "allow-platform-dependencies"
      source_addresses  = [var.aks_subnet_address_prefix]
      destination_fqdns = var.additional_allowed_fqdns

      protocols {
        type = "Https"
        port = 443
      }
    }
  }
}

resource "azurerm_route_table" "aks" {
  name                          = "rt-${var.name}-aks-egress"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = false
  tags                          = var.tags
}
