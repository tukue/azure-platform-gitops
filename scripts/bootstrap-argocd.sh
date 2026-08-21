#!/usr/bin/env bash
set -euo pipefail

: "${ARGOCD_VERSION:?Set an explicit Argo CD release, for example v3.5.0.}"
: "${GIT_REPOSITORY_URL:?Set the HTTPS or SSH Git repository URL.}"
: "${ARGOCD_INSTALL_PROFILE:=ha}"

command -v kubectl >/dev/null || {
  echo "kubectl is required for the one-time Argo CD bootstrap." >&2
  exit 1
}

grep -q "replace-with-your-org" clusters/dev/repository-config.yaml && {
  echo "Set the real repository URL in clusters/dev/repository-config.yaml and commit it before bootstrap." >&2
  exit 1
}

case "$ARGOCD_INSTALL_PROFILE" in
  ha)
    node_count=$(kubectl get nodes --no-headers | wc -l)
    if (( node_count < 3 )); then
      echo "Argo CD HA requires at least three schedulable nodes; found ${node_count}. Scale AKS before bootstrap or explicitly set ARGOCD_INSTALL_PROFILE=standard for non-production use." >&2
      exit 1
    fi
    argocd_manifest_path="manifests/ha/install.yaml"
    ;;
  standard)
    argocd_manifest_path="manifests/install.yaml"
    ;;
  *)
    echo "ARGOCD_INSTALL_PROFILE must be ha or standard." >&2
    exit 1
    ;;
esac

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side --force-conflicts --namespace argocd \
  --filename="https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/${argocd_manifest_path}"

if [[ -n "${GIT_SSH_PRIVATE_KEY:-}" ]]; then
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: platform-gitops-repository
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: ${GIT_REPOSITORY_URL}
  sshPrivateKey: |
$(sed 's/^/    /' <<<"${GIT_SSH_PRIVATE_KEY}")
EOF
fi

kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: platform-root
  namespace: argocd
spec:
  project: default
  source:
    path: clusters/dev
    repoURL: ${GIT_REPOSITORY_URL}
    targetRevision: main
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
      refresh: true
EOF
