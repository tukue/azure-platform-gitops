# ADR 0004: Federated identity for automation

## Status

Accepted.

## Context

Long-lived Azure client secrets in GitHub are high-value credentials with rotation and leakage risks.

## Decision

GitHub Actions authenticates to Azure with OpenID Connect federation. AKS enables OIDC and Workload Identity so future workloads can federate with Azure identities without stored cloud credentials. The sample API has no Azure data-plane permissions and does not receive a service account token.

## Consequences

An Entra application and federated credential must be bootstrapped outside this stack because Terraform cannot safely create the identity it needs to authenticate itself. Repository/environment claims must be restricted to the intended repository and branch or environment.
