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
    condition     = var.sku == "Basic"
    error_message = "This reference platform uses the Basic ACR SKU."
  }
}
variable "public_network_access_enabled" { type = bool }
variable "tags" { type = map(string) }
