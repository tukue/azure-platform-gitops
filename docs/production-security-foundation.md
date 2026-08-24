# Production security foundation

## Scope

This platform uses Azure Private Link for Key Vault. Azure diagnostics forward Key Vault audit events, selected ACR events, and AKS control-plane events to Log Analytics. ACR Private Link is supported by the Terraform module but is not enabled in the Basic SKU profile.

## Production profile

Use the following values in a protected production `tfvars` file. Do not apply this profile to a development environment without ensuring that image publishing and operational access have a private network path.

```hcl
private_cluster_enabled                 = true
api_server_authorized_ip_ranges         = []
acr_sku                                 = "Basic"
acr_public_network_access_enabled       = true
acr_private_endpoint_enabled            = false
key_vault_purge_protection_enabled      = true
key_vault_soft_delete_retention_days    = 90
observability_public_network_access_enabled = false
grafana_public_network_access_enabled       = false
```

The Basic ACR profile keeps public registry access enabled so GitHub-hosted runners can publish images. Registry administrator credentials remain disabled and AKS pulls through its least-privilege kubelet identity with `AcrPull`. ACR Private Link remains an optional future upgrade because it requires Premium SKU and a private build path.

Key Vault public access is disabled. Purge protection makes permanent deletion impossible until soft-delete retention ends, which is expected production behavior and must be considered during environment teardown.

## DNS and access checks

From a private-network host, verify that the services resolve to private addresses:

```bash
nslookup <acr-name>.azurecr.io
nslookup <key-vault-name>.vault.azure.net
az acr check-health --name <acr-name> --yes
```

Use a private DNS resolver and links to every VNet that needs access. Do not manually create conflicting `privatelink.azurecr.io` or `privatelink.vaultcore.azure.net` zones.

## Operational controls

- Treat Key Vault `AuditEvent` logs as security evidence and alert on unexpected secret operations.
- Review ACR login and repository diagnostics for unauthorized image activity.
- Keep production Terraform state in a separate, RBAC-protected remote backend before applying this profile.
- Test private DNS resolution, image pulls, Key Vault secret synchronization, and cluster recovery in each production release.

## Deliberate exclusions

Azure Managed HSM, customer-managed keys, certificate authorities, Azure Firewall, and Azure Monitor Private Link Scope are not enabled in this iteration. They require workload-specific key ownership, network egress, compliance, and cost decisions. The Key Vault and Private Link patterns in this repository provide the foundation for adding them without changing Terraform or GitOps ownership boundaries.
