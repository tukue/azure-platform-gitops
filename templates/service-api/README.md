# Service API golden path

Use this template through `scripts/onboard_application.py`; do not copy its generated YAML into a new service. The generator validates a small registration file against `application.schema.json` and writes a Kustomize workload under `applications/onboarded/<application>`.

The baseline creates a Namespace, ServiceAccount, Deployment, Service, PodDisruptionBudget, HorizontalPodAutoscaler, NetworkPolicy, and optional Ingress and ExternalSecret. It uses the repository's existing External Secrets Operator integration. A registration that enables Key Vault access must also supply an approved workload identity and the Key Vault Private Endpoint host CIDR(s); the generated NetworkPolicy permits HTTPS only to those addresses. This avoids broad outbound HTTPS rules. Direct Key Vault CSI mounts are intentionally not generated because this repository does not yet provision a workload identity and data-plane RBAC per self-service application.
