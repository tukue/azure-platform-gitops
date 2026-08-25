resource "azurerm_key_vault_managed_hardware_security_module" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = "Standard_B1"
  admin_object_ids              = var.admin_object_ids
  public_network_access_enabled = false
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  tags                          = var.tags

  network_acls {
    bypass         = "None"
    default_action = "Deny"
  }
}

resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.managedhsm.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "pdnslink-${var.name}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "this" {
  name                = "pep-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.name}"
    private_connection_resource_id = azurerm_key_vault_managed_hardware_security_module.this.id
    subresource_names              = ["managedhsm"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
  }
}

resource "azurerm_key_vault_managed_hardware_security_module_key" "signing" {
  count = var.signing_key_enabled ? 1 : 0

  name           = var.signing_key_name
  managed_hsm_id = azurerm_key_vault_managed_hardware_security_module.this.id
  key_type       = "RSA-HSM"
  key_size       = 3072
  key_opts       = ["sign", "verify"]
  tags           = merge(var.tags, { purpose = "code-signing" })
}

resource "azurerm_key_vault_managed_hardware_security_module_key_rotation_policy" "signing" {
  count = var.signing_key_enabled ? 1 : 0

  managed_hsm_key_id = azurerm_key_vault_managed_hardware_security_module_key.signing[0].id
  expire_after       = "P2Y"
  time_before_expiry = "P90D"
}

resource "azurerm_key_vault_managed_hardware_security_module_role_definition" "signing_client" {
  count = var.signing_key_enabled && length(var.signing_principal_ids) > 0 ? 1 : 0

  managed_hsm_id = azurerm_key_vault_managed_hardware_security_module.this.id
  name           = uuidv5("url", "${azurerm_key_vault_managed_hardware_security_module.this.id}/roles/signing-client")
  role_name      = "Platform signing client"
  description    = "Reads metadata and signs or verifies with the explicitly assigned Managed HSM key."

  permission {
    data_actions = [
      "Microsoft.KeyVault/managedHsm/keys/read/action",
      "Microsoft.KeyVault/managedHsm/keys/sign/action",
      "Microsoft.KeyVault/managedHsm/keys/verify/action",
    ]
  }
}

data "azurerm_key_vault_managed_hardware_security_module_role_definition" "crypto_auditor" {
  count = var.signing_key_enabled && length(var.auditor_principal_ids) > 0 ? 1 : 0

  managed_hsm_id = azurerm_key_vault_managed_hardware_security_module.this.id
  name           = "2c18b078-7c48-4d3a-af88-5a3a1b3f82b3"
}

resource "azurerm_key_vault_managed_hardware_security_module_role_assignment" "signing_user" {
  for_each = var.signing_key_enabled ? var.signing_principal_ids : toset([])

  name               = uuidv5("url", "${azurerm_key_vault_managed_hardware_security_module.this.id}/keys/${var.signing_key_name}/${each.value}/crypto-user")
  managed_hsm_id     = azurerm_key_vault_managed_hardware_security_module.this.id
  scope              = "/keys/${var.signing_key_name}"
  role_definition_id = azurerm_key_vault_managed_hardware_security_module_role_definition.signing_client[0].resource_manager_id
  principal_id       = each.value
}

resource "azurerm_key_vault_managed_hardware_security_module_role_assignment" "signing_auditor" {
  for_each = var.signing_key_enabled ? var.auditor_principal_ids : toset([])

  name               = uuidv5("url", "${azurerm_key_vault_managed_hardware_security_module.this.id}/keys/${var.signing_key_name}/${each.value}/crypto-auditor")
  managed_hsm_id     = azurerm_key_vault_managed_hardware_security_module.this.id
  scope              = "/keys/${var.signing_key_name}"
  role_definition_id = data.azurerm_key_vault_managed_hardware_security_module_role_definition.crypto_auditor[0].resource_manager_id
  principal_id       = each.value
}
