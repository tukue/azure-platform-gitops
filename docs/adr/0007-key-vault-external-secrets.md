# ADR 0007: Use Azure Key Vault with External Secrets Operator

## Status

Accepted

## Context

The platform needs Kubernetes workloads to consume secrets without committing values, creating long-lived service-principal credentials, or placing secret values in Terraform state. AKS already enables OIDC and Workload Identity, while Argo CD owns Kubernetes desired state.

## Decision

Terraform provisions a private, RBAC-enabled Azure Key Vault, private endpoint/DNS, user-assigned managed identity, federated identity credential, and a Key Vault-scoped `Key Vault Secrets User` assignment. Argo CD deploys External Secrets Operator, a dedicated federated reader service account, `ClusterSecretStore`, and workload `ExternalSecret` resources. Values are populated directly in Key Vault through an approved operational process, outside Git and Terraform.

The operator uses a referenced service account rather than granting its controller pod direct Key Vault access. This gives the controller no standing Azure permission and makes the identity scope explicit.

## Consequences

The approach preserves GitOps for secret references and desired synchronization while keeping values out of Git. It does create Kubernetes Secret copies, so cluster RBAC, encryption, and rotation remain operational responsibilities. Private Key Vault access requires private DNS and a network path for both AKS and secret operators. For production, purge protection and retention should be increased, and secret rotation ownership must be defined.
