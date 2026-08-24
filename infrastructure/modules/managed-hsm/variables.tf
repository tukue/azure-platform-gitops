variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tenant_id" { type = string }
variable "admin_object_ids" { type = set(string) }
variable "virtual_network_id" { type = string }
variable "private_endpoint_subnet_id" { type = string }
variable "tags" { type = map(string) }
variable "signing_key_enabled" {
  type        = bool
  default     = false
  description = "Creates a non-exportable RSA-HSM signing key with a managed rotation policy."
}
variable "signing_key_name" {
  type        = string
  default     = null
  nullable    = true
  description = "Name of the signing key. Required when signing_key_enabled is true."
}
variable "signing_principal_ids" {
  type        = set(string)
  default     = []
  description = "Entra principal object IDs granted Managed HSM Crypto User on only the signing key."
}
variable "auditor_principal_ids" {
  type        = set(string)
  default     = []
  description = "Entra principal object IDs granted Managed HSM Crypto Auditor on only the signing key."
}
