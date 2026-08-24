variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "firewall_subnet_id" { type = string }
variable "aks_subnet_address_prefix" { type = string }
variable "zones" {
  type    = list(string)
  default = []
}
variable "additional_allowed_fqdns" {
  type = list(string)
  default = [
    "*.azurecr.io",
    "*.data.mcr.microsoft.com",
    "mcr.microsoft.com",
    "login.microsoftonline.com",
    "management.azure.com",
  ]
}
variable "tags" { type = map(string) }
