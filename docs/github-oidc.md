# GitHub Actions OIDC bootstrap

Create the GitHub Actions Entra application and its federated identity once, using a secured administrator session. This bootstrap identity is intentionally not created by the workload Terraform configuration.

Restrict the federated credential subject to the `dev` GitHub environment (recommended) or the protected `main` branch. Grant the identity `Contributor` and `Role Based Access Control Administrator` only at the reference platform resource-group scope. The latter is needed solely because Terraform assigns `AcrPull` to the AKS kubelet identity.

Configure these GitHub **environment variables** for the `dev` environment. They are identifiers and configuration, not secrets:

| Variable | Purpose |
| --- | --- |
| `AZURE_CLIENT_ID` | Federated Entra application client ID |
| `AZURE_TENANT_ID` | Entra tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `AZURE_PRINCIPAL_ID` | Service-principal object ID, used for scoped ACR push access |
| `ACR_NAME` | Globally unique registry name |
| `TF_ADMIN_GROUP_OBJECT_IDS` | JSON list of Entra group object IDs allowed AKS admin access |
| `AKS_API_SERVER_AUTHORIZED_IP_RANGES` | JSON list of public API CIDRs when AKS is not private |

The plan job is deliberately skipped until all required values exist. It performs a speculative plan only; applying infrastructure is an operator-controlled workflow. Set `AZURE_PRINCIPAL_ID` before the first apply to allow the same federated identity to publish images, scoped only to this ACR.
