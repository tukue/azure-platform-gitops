# ADR 0009: Use Managed HSM for narrowly scoped signing-key custody

## Status

Accepted

## Context

The regulated profile needs a strong custody boundary for occasional high-value signing or bring-your-own-key workflows. A Standard Key Vault is appropriate for AKS disk encryption CMK but does not establish the same HSM custody pattern for a code-signing private key.

## Decision

Use an optional, private Azure Managed HSM with purge protection and local HSM RBAC. Terraform creates a non-exportable `RSA-HSM` signing key, a rotation policy, per-key Crypto User assignments for explicit signing identities, Crypto Auditor assignments for explicit audit identities, and `AuditEvent` diagnostic forwarding.

Terraform does not import BYOK private material, download a security-domain backup, or make HSM administrators broadly available to workloads. Those are controlled operational ceremonies with named custodians and separate approval.

## Consequences

The platform gains a managed HSM-backed signing-key pattern without adding an in-cluster CA or storing secrets in Git. It also adds cost, private-network dependencies, and recovery duties. Applications still need an approved signing client and artifact-signing process. Organizations that need issuing certificates, timestamping, or a full PKI must select and operate those components separately.
