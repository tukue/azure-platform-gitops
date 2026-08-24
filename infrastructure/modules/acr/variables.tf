variable "name" {
  type = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.name))
    error_message = "ACR name must be globally unique and 5-50 alphanumeric characters."
  }
}
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "sku" {
  type    = string
  default = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}
variable "public_network_access_enabled" { type = bool }
variable "private_endpoint_enabled" {
  type    = bool
  default = false
}
variable "private_endpoint_subnet_id" {
  type     = string
  default  = null
  nullable = true
}
variable "virtual_network_id" {
  type     = string
  default  = null
  nullable = true
}
variable "customer_managed_key_enabled" {
  type    = bool
  default = false
}
variable "customer_managed_key_id" {
  type     = string
  default  = null
  nullable = true
}
variable "encryption_identity_id" {
  type     = string
  default  = null
  nullable = true
}
variable "encryption_identity_client_id" {
  type     = string
  default  = null
  nullable = true
}
variable "tags" { type = map(string) }
