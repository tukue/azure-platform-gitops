# Security posture assessment

**Assessment date:** 2026-08-25  
**Scope:** Repository configuration and local validation only. No Azure subscription, Kubernetes cluster, or CI environment was inspected. A control described as implemented in code must still be deployment-verified before it is treated as effective.

## Executive summary

The platform has a strong security-oriented architecture: Terraform and Argo CD have distinct ownership, Azure and Kubernetes identities avoid long-lived credentials, sensitive Azure services use private connectivity, and CI validates infrastructure and workload configuration. The repository is suitable as a secure reference foundation.

It is **not yet a production-ready deployment baseline**. The committed development profile deliberately trades some controls for cost and GitHub-hosted runner compatibility. Production use requires a protected remote Terraform backend, private AKS and ACR connectivity, reviewed egress, a hardened Kubernetes policy baseline, supply-chain controls, and Azure deployment verification.

## Control assessment

| Domain | Current posture | Evidence in repository | Production gap / action |
| --- | --- | --- | --- |
| Azure identity and access | Strong foundation | GitHub OIDC, AKS Entra RBAC, local accounts disabled, AKS Workload Identity, scoped ACR and Key Vault roles. | Protect the GitHub `dev` environment, review federated credential subjects, use Entra PIM for privileged roles, and perform periodic access reviews. |
| Terraform and change control | Moderate | Formatting, validation, required Checkov IaC scanning, speculative plan, modular IaC, Git history, PR-based workflows. | Move from local state to a private Azure Storage backend with state locking, restricted RBAC, versioning, and recovery procedures. |
| AKS control plane | Strong foundation / opt-in production profile | Entra RBAC, local account disabled, Azure Policy add-on, authorized IP ranges for public API, optional private cluster. | Set `private_cluster_enabled = true` for production; verify DNS, break-glass access, upgrade strategy, and node-pool availability. |
| Kubernetes workload security | Moderate | Pod Security Admission baseline labels, CI Rego checks for non-root, no privilege escalation, read-only filesystem, resources, probes, and non-`latest` tags. | Move production namespaces to Pod Security `restricted` where compatible; enforce seccomp, capability dropping, service-account-token minimization, and NetworkPolicies. |
| Network security | Strong foundation / opt-in production profile | Private endpoints for Key Vault, Managed HSM, Cloud HSM, and observability; firewall and UDR capability; internal ingress. | Enable private AKS, reviewed Azure Firewall egress, private DNS integration, and network policies. ACR remains public by default on Basic SKU. |
| Secrets and application credentials | Strong foundation | Private Key Vault, RBAC authorization, External Secrets Operator, AKS Workload Identity, no secret values in Git or Terraform state. | Enable Key Vault purge protection and 90-day retention in production; verify secret rotation and emergency-access procedures. |
| Cryptographic key custody | Strong foundation / external operations required | Separate Key Vaults, AKS disk CMK/DES option, Managed HSM signing key with per-key roles and rotation, Cloud HSM private foundation. | Define key owners, recovery custodians, backup targets, HSM initialization, CA ceremonies, and evidence retention. See [cryptographic platform and CA](cryptographic-platform.md). |
| Container supply chain | Foundational only | ACR administrator account disabled, immutable-tag promotion process, application test/build validation. | Add vulnerability scanning, SBOM generation, image signing/verification, digest-based promotion, and retention/quarantine policy. |
| Observability and audit | Strong foundation | Container Insights, Managed Prometheus, Grafana, selected AKS/ACR/Key Vault/HSM diagnostics, operational alerts. | Verify ingestion and alert routing in Azure; add action groups, dashboard access reviews, alert runbooks, and Cloud HSM/CA operational evidence. |
| PKI and certificate lifecycle | Foundation only | `cert-manager` controller, Cloud HSM boundary, PKI ADR and operational documentation. | Deploy and operate the offline root, AD CS issuing CA, CRL/OCSP, certificate templates, enrollment connector, and revocation tests through approved PKI governance. |

## Development versus production profile

The example variable file is intentionally a development profile. It keeps Basic ACR publicly reachable for GitHub-hosted image publishing, permits a public AKS API with explicit administrator CIDRs, leaves Key Vault purge protection disabled with seven-day retention, and disables Firewall, CMK, Managed HSM, and enterprise PKI by default.

For production, use a separate uncommitted variable file and change-controlled remote state. At a minimum:

```hcl
private_cluster_enabled                  = true
key_vault_purge_protection_enabled       = true
key_vault_soft_delete_retention_days     = 90
firewall_enabled                         = true
observability_public_network_access_enabled = false
grafana_public_network_access_enabled       = false
```

Enable CMK, Managed HSM, Cloud HSM, and ACR private connectivity only after their workload, recovery, regional, and cost requirements are approved. Basic ACR does not support the private-link and CMK capabilities required for a fully private registry design.

## Priority actions before production use

1. **Protect Terraform state:** create a private Azure Storage backend with RBAC, locking, versioning, recovery, and CI identity restrictions.
2. **Enable private networking:** use private AKS, private ACR-capable SKU and build runners, reviewed firewall egress, and tested private DNS.
3. **Harden Kubernetes runtime:** enforce restricted Pod Security where feasible, NetworkPolicies, seccomp, capability dropping, and admission/audit policy reporting.
4. **Harden software supply chain:** scan dependencies and images, generate SBOMs, sign images, verify signatures at admission, and promote immutable digests through Git.
5. **Operationalize access:** use Entra PIM, break-glass processes, access reviews, and alert action groups.
6. **Operationalize PKI:** complete the offline root and issuing-CA ceremonies, Cloud HSM initialization and recovery, CRL/OCSP, certificate profiles, enrollment, and revocation testing.
7. **Verify effectiveness:** deploy into a non-production subscription and test private DNS, identity federation, drift reconciliation, diagnostics, alerting, backup, restore, and incident runbooks.

## Explicit limitations

- No Azure deployment verification has been performed from this repository.
- No remote Terraform state backend is implemented.
- No image vulnerability scanner, SBOM generator, signing system, or admission signature verifier is implemented.
- No Kubernetes NetworkPolicy resources or restricted Pod Security labels are implemented.
- No enterprise CA, CA host, CRL/OCSP service, or certificate enrollment connector is deployed.

These are documented risks and planned hardening steps, not claims of implemented controls.
