variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "resource_group_id" { type = string }
variable "virtual_network_id" { type = string }
variable "private_endpoint_subnet_id" { type = string }
variable "tags" { type = map(string) }
variable "sku_capacity" {
  type        = number
  default     = 1
  description = "Azure Cloud HSM Standard_B1 capacity. Confirm regional quota and commercial terms before enabling."
  validation {
    condition     = var.sku_capacity >= 1
    error_message = "Cloud HSM SKU capacity must be at least 1."
  }
}
