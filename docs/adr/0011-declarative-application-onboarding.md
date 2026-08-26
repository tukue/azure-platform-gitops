# ADR 0011: Use generated Kustomize workloads for application onboarding

## Context

Application teams need a small, reviewable interface for a secure AKS service. Directly copying Kubernetes YAML is error-prone, while a portal, operator, or additional deployment controller would exceed the MVP and overlap with Argo CD.

## Decision

Use a JSON registration validated and rendered by a Python-standard-library generator into committed Kustomize resources. Argo CD continues to reconcile the existing `applications/` path; GitHub Actions validates generation and policies but does not deploy workloads.

## Consequences

The interface is simple, version-controlled, locally testable, and compatible with existing Kustomize/Argo CD controls. Generated YAML remains inspectable in code review. It does not provide a web portal, automatic Azure identity provisioning, or environment promotion automation; those are future product capabilities after the golden path is operated.
