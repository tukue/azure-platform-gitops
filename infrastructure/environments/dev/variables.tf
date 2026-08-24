variable "subscription_id" { type = string }
variable "project" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "acr_name" { type = string }
variable "key_vault_name" {
  type        = string
  description = "Globally unique Azure Key Vault name used by External Secrets Operator."
}
variable "admin_group_object_ids" { type = set(string) }
variable "grafana_admin_group_object_id" {
  type        = string
  default     = null
  nullable    = true
  description = "Entra group object ID granted Grafana Admin. Leave null to assign access outside Terraform."
}
variable "github_actions_principal_id" {
  type        = string
  default     = null
  nullable    = true
  description = "Object ID of the federated GitHub Actions service principal. Enables scoped ACR image publishing when set."
}
variable "kubernetes_version" {
  type        = string
  default     = null
  nullable    = true
  description = "A tested AKS version, or null to use Azure's currently supported default."
}
variable "vnet_address_space" { type = string }
variable "aks_subnet_address_prefix" { type = string }
variable "private_endpoints_subnet_address_prefix" { type = string }
variable "private_cluster_enabled" { type = bool }
variable "cmk_enabled" {
  type        = bool
  default     = false
  description = "Enables AKS disk and ACR customer-managed key resources. Enabling AKS disk encryption on an existing cluster requires replacement planning."
}
variable "cmk_key_vault_name" {
  type        = string
  default     = null
  nullable    = true
  description = "Globally unique name for the dedicated Standard Key Vault that stores AKS disk CMK material. Required when cmk_enabled is true."
}
variable "managed_hsm_enabled" {
  type        = bool
  default     = false
  description = "Creates a private Azure Managed HSM for CA or signing-key workloads after explicit cost and administrator approval."
}
variable "managed_hsm_name" {
  type        = string
  default     = null
  nullable    = true
  description = "Globally unique Azure Managed HSM name. Required when managed_hsm_enabled is true."
}
variable "managed_hsm_admin_object_ids" {
  type        = set(string)
  default     = []
  description = "Trusted Entra object IDs that administer the Managed HSM security domain."
}
variable "managed_hsm_signing_key_enabled" {
  type        = bool
  default     = false
  description = "Creates a non-exportable HSM signing key and grants per-key local RBAC to the configured principals."
}
variable "managed_hsm_signing_key_name" {
  type        = string
  default     = null
  nullable    = true
  description = "Name of the HSM signing key. Required when managed_hsm_signing_key_enabled is true."
}
variable "managed_hsm_signing_principal_ids" {
  type        = set(string)
  default     = []
  description = "Entra principal object IDs allowed to sign and verify with the dedicated signing key."
}
variable "managed_hsm_auditor_principal_ids" {
  type        = set(string)
  default     = []
  description = "Entra principal object IDs allowed to inspect the dedicated signing key without using it."
}
variable "enterprise_pki_enabled" {
  type        = bool
  default     = false
  description = "Creates the private Azure Cloud HSM foundation for an externally governed AD CS issuing CA."
}
variable "cloud_hsm_name" {
  type        = string
  default     = null
  nullable    = true
  description = "Globally unique Azure Cloud HSM name. Required when enterprise_pki_enabled is true."
}
variable "cloud_hsm_sku_capacity" {
  type        = number
  default     = 1
  description = "Azure Cloud HSM Standard_B1 capacity. Confirm regional quota and cost before enabling."
}
variable "firewall_enabled" {
  type        = bool
  default     = false
  description = "Routes AKS egress through Azure Firewall and requires a reviewed FQDN allowlist before production use."
}
variable "firewall_subnet_address_prefix" {
  type        = string
  default     = null
  nullable    = true
  description = "CIDR for AzureFirewallSubnet. Azure Firewall requires a dedicated /26 or larger subnet."
}
variable "availability_zones" {
  type        = list(string)
  default     = []
  description = "Availability zones for supported production resources, for example [\"1\", \"2\", \"3\"]."
}
variable "api_server_authorized_ip_ranges" { type = set(string) }
variable "azure_policy_enabled" {
  type        = bool
  default     = true
  description = "Enables the AKS Azure Policy add-on. Assign built-in policies in audit mode before enforcing them."
}
variable "log_analytics_retention_in_days" {
  type    = number
  default = 30
  validation {
    condition     = var.log_analytics_retention_in_days >= 30 && var.log_analytics_retention_in_days <= 730
    error_message = "Log Analytics retention must be between 30 and 730 days."
  }
}
variable "observability_public_network_access_enabled" {
  type    = bool
  default = false
}
variable "observability_private_link_enabled" {
  type        = bool
  default     = true
  description = "Creates Azure Monitor Private Link Scope, private DNS zones, and a Managed Grafana private endpoint."
}
variable "grafana_public_network_access_enabled" {
  type    = bool
  default = false
}
variable "alert_action_group_ids" {
  type        = set(string)
  default     = []
  description = "Existing action group resource IDs to notify for Azure Monitor alerts."
}
variable "acr_sku" {
  type    = string
  default = "Basic"
}
variable "acr_public_network_access_enabled" {
  type    = bool
  default = true
}
variable "key_vault_purge_protection_enabled" {
  type        = bool
  default     = false
  description = "Enable for production. It prevents purging deleted Key Vaults until the retention period expires."
}
variable "key_vault_soft_delete_retention_days" {
  type        = number
  default     = 7
  description = "Use 90 days for production Key Vaults."
  validation {
    condition     = var.key_vault_soft_delete_retention_days >= 7 && var.key_vault_soft_delete_retention_days <= 90
    error_message = "Key Vault soft-delete retention must be between 7 and 90 days."
  }
}
variable "system_node_vm_size" {
  type    = string
  default = "Standard_D4ds_v5"
}
variable "system_node_min_count" {
  type    = number
  default = 1
}
variable "system_node_max_count" {
  type    = number
  default = 3
}
variable "tags" {
  type    = map(string)
  default = {}
}
