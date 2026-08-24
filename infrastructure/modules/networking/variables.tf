variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "address_space" { type = string }
variable "aks_subnet_address_prefix" { type = string }
variable "private_endpoints_subnet_address_prefix" { type = string }
variable "firewall_enabled" {
  type    = bool
  default = false
}
variable "firewall_subnet_address_prefix" {
  type     = string
  default  = null
  nullable = true
}
variable "tags" { type = map(string) }
