variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "address_space" { type = string }
variable "aks_subnet_address_prefix" { type = string }
variable "private_endpoints_subnet_address_prefix" { type = string }
variable "tags" { type = map(string) }
