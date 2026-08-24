# Regulated security profile

## Purpose

This profile is an opt-in production design for regulated workloads. It adds encryption key separation, HSM custody, controlled egress, private monitoring connectivity, and a GitOps-managed certificate controller while preserving Terraform ownership of Azure resources and Argo CD ownership of Kubernetes resources.

## Activation values

Use these values only in a new or migration-planned production environment. Do not enable AKS disk CMK on an existing cluster without an approved replacement plan.

```hcl
private_cluster_enabled                     = true
cmk_enabled                                = true
cmk_key_vault_name                         = "kv-platform-prod-cmk"
acr_sku                                    = "Basic"
acr_public_network_access_enabled          = true
managed_hsm_enabled                        = true
managed_hsm_name                           = "mhsm-platform-prod"
managed_hsm_admin_object_ids               = ["<entra-group-object-id>"]
firewall_enabled                           = true
firewall_subnet_address_prefix             = "10.20.5.0/26"
availability_zones                         = ["1", "2", "3"]
observability_private_link_enabled         = true
observability_public_network_access_enabled = false
grafana_public_network_access_enabled       = false
key_vault_purge_protection_enabled         = true
key_vault_soft_delete_retention_days       = 90
```

## Key custody

- The dedicated Standard CMK Key Vault stores the RSA key used by the Disk Encryption Set.
- Application secrets remain in the separate private Key Vault consumed by External Secrets Operator.
- Managed HSM is reserved for CA, signing, or BYOK keys with a separately governed security domain and Entra administrator group.
- Basic ACR remains public for GitHub-hosted build runners. It does not use CMK or Private Link in this reference profile.

## Migration and recovery

AKS OS-disk CMK is a cluster-creation decision. Create a replacement private cluster, validate node encryption and workload recovery, migrate GitOps reconciliation, then retire the old cluster. Do not enable `cmk_enabled` against a running cluster without reviewing the Terraform plan for replacement.

Managed HSM security-domain backup and quorum recovery are security-owner responsibilities. Store recovery artifacts under approved offline controls and test recovery according to the organization’s cryptographic policy.

## Egress and monitoring

Azure Firewall routes the AKS subnet’s default route through a Standard Firewall policy. The included FQDN rules are a minimum platform baseline; review AKS-required endpoints, package repositories, SaaS dependencies, and private DNS before enabling it. Monitor denied flows during a staged rollout before switching the policy from alerting to blocking behavior.

AMPLS makes Log Analytics, Azure Monitor Workspace, and the metrics Data Collection Endpoint private. Managed Grafana uses a managed private endpoint to query the scope. Validate DNS from AKS and operational workstations before disabling any remaining public access paths.

## Certificates

`cert-manager` is installed through Argo CD. Public ACME requires a delegated DNS zone, an ACME registration email, and a dedicated DNS Workload Identity. Use DNS-01 for this private AKS architecture. See [certificate management](certificate-management.md) before adding an issuer.
