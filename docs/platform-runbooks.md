# Platform runbooks

## Argo CD application out of sync

Run `argocd app get applications` and `argocd app diff applications`. Review the Git revision, Application events, and repository-server/controller logs. Correct Git desired state or revert the change; do not manually apply a permanent fix.

## Workload identity or Key Vault failure

Inspect the ServiceAccount annotations, workload identity pod label, ExternalSecret status, private DNS resolution, and Key Vault `AuditEvent` logs. Verify the federated credential subject and least-privilege role assignment. See `docs/secret-management.md` for the exact expected identity flow.

## Failed rollout

Use `kubectl -n <namespace> rollout status deployment/<application>`, inspect events, probes, image pull status, and resource pressure. Revert the registration/image commit to initiate an Argo CD rollback.

## Policy rejection

Read the Conftest pull-request annotation. Mandatory policies block insecure workload declarations; correct the registration/template output. Advisory Azure Policy should begin in audit mode. Exceptions must be narrow, time-bound, and documented in the pull request.

## Terraform deployment failure

Run `terraform -chdir=infrastructure/environments/dev validate` and reproduce a reviewed plan with the protected environment inputs. Inspect Azure activity logs and provider errors. Do not change Azure resources manually to bypass Terraform state.

## Observability data missing

Confirm the workload is running, Container Insights and Azure Monitor agent pods are healthy, the pod has scrape annotations, and AKS has the data collection rule association. Then query `ContainerLogV2` and the Azure Monitor workspace. See `docs/observability.md` for KQL and network prerequisites.

## Safe rollback

Revert the Git commit that changed the registration or generated workload. Verify Argo CD sync, rollout completion, and alerts returning to normal. Record the trigger and corrective action in the pull request or incident record.
