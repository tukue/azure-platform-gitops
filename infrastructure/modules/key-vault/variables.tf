variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tenant_id" { type = string }
variable "private_endpoint_subnet_id" { type = string }
variable "private_dns_zone_id" { type = string }
variable "oidc_issuer_url" { type = string }
variable "purge_protection_enabled" {
  type    = bool
  default = false
}
variable "soft_delete_retention_days" {
  type    = number
  default = 7
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Key Vault soft-delete retention must be between 7 and 90 days."
  }
}
variable "tags" { type = map(string) }
