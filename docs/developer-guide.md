# Developer guide

## Ten-minute onboarding path

1. Copy `applications/registrations/demo-api.json` to `applications/registrations/<application>.json` and change the required fields: name, owner, namespace, image, resource profile, health path, ingress, Key Vault requirement, and workload identity setting. For Key Vault access, obtain an approved workload identity client ID, tenant ID, and Key Vault Private Endpoint host CIDR(s) from the platform team.
2. Keep the file name equal to `name`; use a non-`latest` image tag or digest.
3. Generate the workload:

```bash
python scripts/onboard_application.py generate \
  --config applications/registrations/<application>.json \
  --output applications/onboarded/<application>
```

4. Add `onboarded/<application>` to `applications/kustomization.yaml`, then validate:

```bash
python scripts/onboard_application.py check \
  --config applications/registrations/<application>.json \
  --output applications/onboarded/<application>
kubectl kustomize applications
```

5. Open a pull request. GitHub Actions tests the generator, verifies generated files, renders Kustomize, and applies mandatory Conftest policies. It does not deploy to Kubernetes.
6. After merge, Argo CD reconciles `applications/` to AKS. Confirm with `argocd app get applications` and `kubectl -n <namespace> get deploy,pods,hpa,pdb,networkpolicy`.
7. If Key Vault access is enabled, the generator requires Workload Identity and creates HTTPS egress only to the supplied private endpoint addresses. A platform operator creates or rotates the value in the private vault. External Secrets Operator creates `<application>-runtime`; values never enter Git or Terraform state.
8. Promote a new image by changing only `image` in the registration, regenerating the workload, and merging the reviewed pull request.

## Failed deployment and rollback

Check `kubectl -n <namespace> describe deployment <application>`, pod events, and `argocd app get applications`. Roll back by reverting the image-registration commit; Argo CD self-heals to the reverted desired state. Do not edit the live Deployment.

## Troubleshooting

- Registration error: run `python scripts/onboard_application.py validate --config <file>`; error messages identify the invalid field.
- Policy rejection: use the PR annotation and see `docs/policy-as-code.md`; change the generated configuration or request a documented, time-bound exception.
- Key Vault secret unavailable: see `docs/secret-management.md` and verify ExternalSecret status, private DNS, and the shared reader identity.
- Missing logs or metrics: see `docs/observability.md`; start with pod status, `ContainerLogV2`, and the Azure Monitor scrape configuration.
