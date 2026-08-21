# ADR 0003: Terraform and Argo CD ownership boundaries

## Status

Accepted.

## Context

Two declarative systems can conflict when they manage the same resources.

## Decision

Terraform owns Azure resources and Azure RBAC: resource group, virtual network, AKS subnet, ACR, AKS, identities exposed by AKS, and the AKS kubelet `AcrPull` role assignment. Argo CD owns all Kubernetes API resources after AKS exists: namespaces, Helm-backed platform components, workloads, and configuration.

## Consequences

Terraform does not use the Kubernetes provider and GitHub Actions does not use `kubectl apply` for deployment. Each Kubernetes object has one reconciler, avoiding competing state and unclear rollback paths.
