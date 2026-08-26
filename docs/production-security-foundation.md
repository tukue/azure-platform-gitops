# Production security foundation

## Scope

This platform uses Azure Private Link for Key Vault. Azure diagnostics forward Key Vault audit events, selected ACR events, and AKS control-plane events to Log Analytics. ACR remains on the Basic SKU for a low-cost registry and GitHub-hosted build compatibility.

## Production profile

Use the following values in a protected production `tfvars` file. Do not apply this profile to a development environment without ensuring that image publishing and operational access have a private network path.

```hcl
private_cluster_enabled                 = true
api_server_authorized_ip_ranges         = []
acr_sku                                 = "Basic"
acr_public_network_access_enabled       = true
key_vault_purge_protection_enabled      = true
key_vault_soft_delete_retention_days    = 90
production_security_profile_enabled     = true
observability_public_network_access_enabled = false
observability_private_link_enabled          = true
grafana_public_network_access_enabled       = false
```

The Basic ACR profile keeps public registry access enabled so GitHub-hosted runners can publish images. Registry administrator credentials remain disabled and AKS pulls through its least-privilege kubelet identity with `AcrPull`.

Key Vault public access and the Azure-services bypass are disabled. Access must use the private endpoint, private DNS, and Azure RBAC. Purge protection makes permanent deletion impossible until soft-delete retention ends, which is expected production behavior and must be considered during environment teardown.

`production_security_profile_enabled` is a Terraform guardrail, not a second environment implementation. It fails planning if the private AKS, Key Vault recovery, and observability private-access controls above are not enabled together. The Basic ACR public publishing exception remains explicit because GitHub-hosted runners cannot access an ACR private endpoint.

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

Azure Managed HSM, customer-managed keys, Azure Firewall, Azure Monitor Private Link Scope, and `cert-manager` are implemented as opt-in capabilities in the regulated security profile. They remain disabled by default because CMK can require AKS replacement, Firewall requires a reviewed egress allowlist, Managed HSM requires security-domain recovery ownership, and public ACME requires a delegated DNS zone. The Key Vault and Private Link patterns preserve Terraform ownership of Azure resources and Argo CD ownership of Kubernetes configuration.
