# ADR 0010: Use Azure Cloud HSM for the private issuing-CA foundation

## Status

Accepted

## Context

Regulated internal certificate issuance requires a CA hierarchy, revocation services, and a protected issuing-CA private key. Azure Managed HSM is suitable for the repository's REST-based signing-key custody pattern, but a CA commonly requires PKCS#11, CNG, or KSP integration.

## Decision

Adopt a two-tier AD CS reference design: an offline root CA managed outside this repository and an online issuing CA hosted in a separately approved private network. Terraform provisions a private Azure Cloud HSM, its backup identity, Private Endpoint, and private DNS integration. AzAPI is pinned alongside AzureRM because AzureRM does not currently provide a first-class Cloud HSM resource.

The CA host, HSM initialization, CA key creation, certificate templates, CRL/OCSP publishing, and AKS enrollment connector are external operational deliverables. They must be implemented under a PKI change process after identity, domain, retention, and recovery decisions are approved.

## Consequences

This creates a defensible Azure boundary for enterprise PKI without putting CA material in Git, Terraform state, or Kubernetes. It adds a premium service, private-network dependencies, and substantial PKI operational responsibility. Public AKS TLS continues to use a separate DNS-01/ACME pattern.
