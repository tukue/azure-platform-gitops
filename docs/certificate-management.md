# Certificate management and PKI

## Implemented platform capability

Argo CD installs `cert-manager` from the Jetstack Helm repository in the dedicated `cert-manager` namespace. Certificate requests, issuers, and renewal state are therefore Kubernetes desired state; Argo CD reconciles the controller but does not store private keys in Git.

## Public ACME activation

Use DNS-01 for a private AKS platform. HTTP-01 would require exposing the ingress controller publicly, which conflicts with this platform's private-by-default posture. Before creating a production `ClusterIssuer`, provide:

- a delegated public DNS zone;
- an ACME registration email;
- a dedicated Workload Identity with only `DNS Zone Contributor` on that zone; and
- a controlled decision on where issued certificate private keys may be stored.

Create the issuer through a reviewed GitOps change after these values are available. Do not commit registrar credentials, ACME account keys, or certificate private keys.

## HSM and CA keys

The Terraform `managed-hsm` module creates a separate, private Azure Managed HSM for REST-based signing-key custody. It is not a certificate authority. The enterprise private PKI profile instead uses Azure Cloud HSM as the PKCS#11/CNG boundary for an externally governed AD CS issuing CA.

This separation is intentional. Application secrets remain in Azure Key Vault, AKS disk CMKs remain in the dedicated Standard CMK Key Vault, Managed HSM holds application signing keys, and Cloud HSM holds the issuing-CA key under distinct administrators and recovery procedures. See [enterprise private PKI](enterprise-private-pki.md).

## Certificate lifecycle controls

- Alert on renewal failures and certificates approaching expiry.
- Restrict read access to TLS Secrets in application namespaces.
- Rotate CA and signing keys according to the approved cryptographic policy.
- Test revocation, renewal, and disaster recovery before relying on a CA for production traffic.
