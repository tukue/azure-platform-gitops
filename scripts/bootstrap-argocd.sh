#!/usr/bin/env bash
set -euo pipefail

: "${ARGOCD_VERSION:?Set an explicit Argo CD release, for example v3.5.0.}"
: "${GIT_REPOSITORY_URL:?Set the HTTPS or SSH Git repository URL.}"

command -v kubectl >/dev/null || {
  echo "kubectl is required for the one-time Argo CD bootstrap." >&2
  exit 1
}

grep -q "replace-with-your-org" clusters/dev/repository-config.yaml && {
  echo "Set the real repository URL in clusters/dev/repository-config.yaml and commit it before bootstrap." >&2
  exit 1
}

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side --namespace argocd \
  --filename="https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

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
EOF
