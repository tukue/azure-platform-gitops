# ADR 0005: Restrict Argo CD with a platform project

## Status

Accepted.

## Context

Argo CD's default project is broad enough to deploy arbitrary sources and resources. The reference platform needs a visible, small example of GitOps tenancy controls without introducing a multi-team access-management system.

## Decision

Use the `platform` AppProject for platform and application Applications. It restricts source repositories to this Git repository and the approved ingress Helm repository, allows only the platform namespaces as destinations, and permits only `Namespace` cluster-scoped resources.

## Consequences

New platform components must be deliberately added to the project's source and destination allowlists. The bootstrap root continues to use the default project because it creates the AppProject itself.
