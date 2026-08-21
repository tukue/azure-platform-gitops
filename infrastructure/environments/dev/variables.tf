variable "subscription_id" { type = string }
variable "project" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "acr_name" { type = string }
variable "admin_group_object_ids" { type = set(string) }
variable "github_actions_principal_id" {
  type        = string
  default     = null
  nullable    = true
  description = "Object ID of the federated GitHub Actions service principal. Enables scoped ACR image publishing when set."
}
variable "kubernetes_version" {
  type        = string
  default     = null
  nullable    = true
  description = "A tested AKS version, or null to use Azure's currently supported default."
}
variable "vnet_address_space" { type = string }
variable "aks_subnet_address_prefix" { type = string }
variable "private_cluster_enabled" { type = bool }
variable "api_server_authorized_ip_ranges" { type = set(string) }
variable "acr_sku" {
  type    = string
  default = "Basic"
}
variable "acr_public_network_access_enabled" {
  type    = bool
  default = true
}
variable "system_node_vm_size" {
  type    = string
  default = "Standard_D4ds_v5"
}
variable "system_node_min_count" {
  type    = number
  default = 1
}
variable "system_node_max_count" {
  type    = number
  default = 3
}
variable "tags" {
  type    = map(string)
  default = {}
}
