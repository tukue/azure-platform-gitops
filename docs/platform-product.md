# Azure AKS platform product

## Users and problem

The platform serves application developers who need a secure, repeatable route from a container image to AKS, and platform engineers who operate the Azure, GitOps, identity, policy, and observability foundations. It removes the need for application teams to author or understand the full Azure, Terraform, Kubernetes, and Argo CD implementation for a standard service.

## Product contract

| Application team owns | Platform team owns |
| --- | --- |
| Source code, container image, health endpoint, registration, resource profile, and application-specific alert thresholds | Azure infrastructure, AKS, Argo CD, namespaces, shared identity/secrets delivery, policy, observability, upgrades, and operational runbooks |

The supported extension points are the application registration fields, immutable image promotion, optional internal ingress, optional External Secrets reference, and an approved workload identity. Requests outside that contract use a GitHub issue with the `platform-feedback` template and must state the user need, security impact, cost, and proposed expiry for any exception.

## Golden path

`applications/registrations/<name>.json` is the developer interface. The standard-library generator validates it and produces a committed Kustomize workload under `applications/onboarded/<name>`. Argo CD already reconciles `applications/`, so a merged registration and generated output become desired state without CI using `kubectl apply`.

The generated baseline contains a restricted namespace, consistent ownership/environment/cost labels, ServiceAccount, Deployment, Service, PDB, HPA, NetworkPolicy, probes, resource profile, pod security context, and Prometheus annotations. It can add internal ingress and an External Secrets reference. Azure Workload Identity annotations are generated only when an approved identity client and tenant ID are supplied.

The platform uses External Secrets Operator for Key Vault delivery. When an application registration requests Key Vault access, it must supply an approved workload identity and the Key Vault Private Endpoint host CIDR(s). The generated NetworkPolicy allows HTTPS only to those private addresses, in addition to cluster DNS. Secrets Store CSI is explicitly deferred: the repository does not yet provision a dedicated workload identity and Key Vault data-plane RBAC per self-service service, so adding a CSI manifest would be incomplete and misleading.

## Service objectives

The following are design objectives, not measured production SLO claims until Azure telemetry and alert routing are verified:

| SLI | Objective | Owner |
| --- | --- | --- |
| GitOps reconciliation health | 99% of managed Applications healthy during a calendar month | Platform team |
| Golden-path validation | 95% of valid registration pull requests receive CI feedback within 10 minutes | Platform team |
| Application availability | Team-defined; the baseline exposes readiness, liveness, availability, and restart signals | Application team |

## Scope and roadmap

**Implemented MVP:** Azure foundation, GitOps reconciliation, secure workload baseline, registration generator, policy checks, Key Vault references, and Azure-native observability configuration.

**Deferred:** self-service Azure identity provisioning, Key Vault CSI mounts, dashboards-as-code, automated environment promotion, multi-cluster tenancy, custom portal, and formal support/on-call tooling.

1. Measure golden-path adoption and CI feedback time; collect feedback through GitHub issues and quarterly developer reviews.
2. Add a reviewed identity-request workflow and workload-specific Key Vault RBAC.
3. Add versioned environment overlays, dashboard-as-code, and promotion evidence after the single-environment flow is deployed and operated.
