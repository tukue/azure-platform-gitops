variable "name_prefix" { type = string }
variable "key_vault_name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tenant_id" { type = string }
variable "private_endpoint_subnet_id" { type = string }
variable "key_vault_private_dns_zone_id" { type = string }
variable "tags" { type = map(string) }
