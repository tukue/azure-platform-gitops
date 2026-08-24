variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tenant_id" { type = string }
variable "admin_object_ids" { type = set(string) }
variable "virtual_network_id" { type = string }
variable "private_endpoint_subnet_id" { type = string }
variable "tags" { type = map(string) }
