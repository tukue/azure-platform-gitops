# Azure AKS GitOps reference platform

This repository is a focused reference implementation for an Azure platform delivery path: Terraform provisions Azure foundations, GitHub Actions validates changes, Argo CD reconciles Kubernetes desired state, and AKS runs observable workloads from ACR images.

## Implemented

- Modular Terraform for a resource group, VNet, AKS subnet, ACR, AKS, and AKS-kubelet `AcrPull` permission.
- AKS Microsoft Entra RBAC, managed identity, OIDC issuer, and Workload Identity.
- GitHub Actions Terraform formatting, initialization, validation, and OIDC-backed speculative plan.
- GitHub Actions API unit tests, container build validation, and Kustomize rendering for every Argo CD source tree.
- Argo CD app-of-apps hierarchy with a restricted AppProject, declarative ingress-nginx, and Prometheus/Grafana through pinned Helm releases.
- A minimal FastAPI `/health` service with probes, resource controls, hardened pod settings, and an internal ingress route.
- Architecture decision records and an explicit Argo CD bootstrap command.

## Architecture

```text
GitHub pull request -> GitHub Actions validation -> merge
                                               |
Terraform -> Azure resource group/VNet/ACR/AKS |
                                               v
Git repository <- Argo CD reconciliation <- clusters/dev
                                        |          |
                                  platform/   applications/
                                        |          |
                           ingress + monitoring   demo API in AKS
```

Terraform owns Azure resources and Azure RBAC. Argo CD owns Kubernetes resources. GitHub Actions builds and validates, but never deploys with `kubectl apply`.

## Repository layout

```text
infrastructure/modules/          Reusable Azure components
infrastructure/environments/dev/ Dev composition and outputs
clusters/dev/                    Argo CD app-of-apps entry point
platform/                        Namespaces and shared Helm releases
applications/demo-api/           API source, image build, and workload manifests
.github/workflows/               Infrastructure and application validation
docs/adr/                         Architecture decisions
```

## Prerequisites

- Azure CLI authenticated to the intended subscription.
- Terraform `>= 1.10`, `kubectl`, Docker, Git, and a `make` implementation.
- An explicit, supported Argo CD release for GitOps bootstrap.
- An Entra group for AKS administrators and an unused globally unique ACR name.
- A GitHub repository with a protected `main` branch and a `dev` environment.

On Windows, run the individual Terraform commands if `make` is unavailable, or install a compatible `make` tool.

## Azure foundation

Copy `infrastructure/environments/dev/dev.tfvars.example` to `dev.tfvars`, replace every placeholder, and keep that file uncommitted. Public AKS API access requires explicit administrator CIDRs. Leave `kubernetes_version = null` to accept Azure's currently supported default, or pin a version that has been tested in the target region. For production-like networking, set `private_cluster_enabled = true` and provide private connectivity before obtaining kubeconfig.

```bash
make init
make validate
make plan
make apply
make kubeconfig
kubectl get nodes
```

AKS uses its kubelet managed identity to pull images from ACR. No registry administrator credential is enabled.

## CI and identity

Follow [GitHub OIDC bootstrap](docs/github-oidc.md) before enabling Terraform plans. The workflow uses GitHub OIDC and does not require an Azure client secret. The `dev` Terraform state is local by default for a first deployment; use an Azure Storage backend with state locking and restricted access before shared or production use.

The application workflow runs tests and builds the container. The manual **Publish demo API** workflow uses OIDC and scoped `AcrPush` permission to publish an immutable image tag to ACR. After a successful publish, update the image tag in `applications/demo-api/deployment.yaml` through a pull request; that Git change is the deployment promotion consumed by Argo CD.

## GitOps workflow

After `kubectl get nodes` succeeds, bootstrap Argo CD from an administrator workstation:

```bash
export ARGOCD_VERSION="v<supported-version>"
export GIT_REPOSITORY_URL="https://github.com/your-org/azure-platform-gitops.git"
./scripts/bootstrap-argocd.sh
```

The bootstrap command is the one-time exception that installs Argo CD and creates the `platform-root` Application. From then on, Argo CD continuously reconciles `clusters/dev`, which creates the platform and application Applications. The `platform` AppProject restricts child Applications to approved repositories and namespaces. For a private repository, update `clusters/dev/repository-config.yaml` to its SSH URL, supply a read-only deploy key through `GIT_SSH_PRIVATE_KEY`, and commit the URL change before bootstrap. Before applying the demo workload, replace the ACR hostname placeholder in `applications/demo-api/deployment.yaml` with the Terraform `acr_login_server` output and commit the change.

Platform components are internal by default: ingress-nginx requests an internal Azure load balancer, Grafana is `ClusterIP`, and Alertmanager is disabled until a notification route exists. The demo is reachable at `demo-api.internal.example.com` after that name is mapped through private DNS to the ingress address. Retrieve Grafana credentials only from the cluster after Helm has generated them; do not add them to Git.

## Drift demonstration

After Argo CD reports the `applications` Application as healthy and synced, mutate a managed value:

```bash
kubectl -n demo scale deployment/demo-api --replicas=1
kubectl -n demo get deployment demo-api
argocd app get applications
kubectl -n demo get deployment demo-api
```

The deployment returns to the Git-declared two replicas. The manual change is intentionally not committed.

## Observability

`kube-prometheus-stack` provides Prometheus and Grafana in the `monitoring` namespace. The ingress controller exposes Prometheus metrics and a ServiceMonitor. Access Grafana through an approved private-network path or temporary port-forwarding; this reference does not expose an internet-facing dashboard.

## Cleanup

First remove Argo CD-managed resources if the cluster is reachable.

```bash
kubectl delete application --all --namespace argocd
kubectl delete namespace argocd
make destroy
```

Destroying AKS also removes Argo CD and all workloads. Review the Terraform plan before confirmation, especially if state has been moved to a shared backend.

## Limitations and future improvements

- Implemented state storage is local only; shared environments need a protected remote state backend.
- Image publishing and Git image-tag promotion are intentionally not automated yet.
- The sample uses one system node pool, Basic ACR, and no availability-zone strategy.
- Future work can add private ACR endpoints, dedicated workload node pools, backup/disaster recovery, alert routing, image scanning, and Git-based image promotion automation after operating requirements justify them.

See [the ADRs](docs/adr) for the reasoning behind AKS, Argo CD, ownership boundaries, and federated identity.
