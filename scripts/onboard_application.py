import argparse
import json
import re
import sys
from uuid import UUID
from pathlib import Path


PROFILES = {
    "small": {"request_cpu": "100m", "request_memory": "128Mi", "limit_cpu": "500m", "limit_memory": "256Mi"},
    "medium": {"request_cpu": "250m", "request_memory": "256Mi", "limit_cpu": "1", "limit_memory": "512Mi"},
}
NAME_PATTERN = re.compile(r"^[a-z][a-z0-9-]{1,30}$")
HOST_PATTERN = re.compile(r"^[a-z0-9](?:[a-z0-9.-]{0,251}[a-z0-9])?$")
SECRET_PATTERN = re.compile(r"^[a-z0-9-]{1,63}$")


def fail(message: str) -> None:
    raise ValueError(f"Application registration is invalid: {message}")


def read_registration(path: Path) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ValueError(f"registration file {path} does not exist") from error
    except json.JSONDecodeError as error:
        raise ValueError(f"registration file {path} contains invalid JSON: {error.msg}") from error

    if not isinstance(value, dict):
        fail("the document must be a JSON object")
    return value


def require_object(value: dict, key: str) -> dict:
    nested = value.get(key)
    if not isinstance(nested, dict):
        fail(f"{key} must be an object")
    return nested


def contains_placeholder(value: object) -> bool:
    if isinstance(value, str):
        return "REPLACE_WITH_" in value
    if isinstance(value, dict):
        return any(contains_placeholder(nested) for nested in value.values())
    if isinstance(value, list):
        return any(contains_placeholder(nested) for nested in value)
    return False


def valid_uuid(value: object) -> bool:
    if not isinstance(value, str):
        return False
    try:
        parsed = UUID(value)
    except ValueError:
        return False
    return parsed.int != 0 and str(parsed) == value.lower()


def validate_registration(value: dict) -> None:
    required = {"name", "owner", "environment", "namespace", "image", "resourceProfile", "healthCheckPath", "ingress", "keyVaultAccess", "workloadIdentity"}
    unknown = sorted(set(value) - required)
    missing = sorted(required - set(value))
    if unknown:
        fail(f"unsupported fields: {', '.join(unknown)}")
    if missing:
        fail(f"missing required fields: {', '.join(missing)}")
    if contains_placeholder(value):
        fail("placeholder values are not allowed; use an approved value or disable the optional capability")

    for key in ("name", "owner", "namespace"):
        if not isinstance(value[key], str) or not NAME_PATTERN.fullmatch(value[key]):
            fail(f"{key} must be a lowercase DNS label between 2 and 31 characters")

    if value["environment"] not in {"dev", "staging", "prod"}:
        fail("environment must be one of dev, staging, or prod")
    if not isinstance(value["image"], str) or not value["image"] or value["image"].endswith(":latest"):
        fail("image must be immutable and must not use the latest tag")
    if "@" not in value["image"] and ":" not in value["image"].rsplit("/", 1)[-1]:
        fail("image must include an immutable tag or digest")
    if value["resourceProfile"] not in PROFILES:
        fail(f"resourceProfile must be one of {', '.join(PROFILES)}")
    if not isinstance(value["healthCheckPath"], str) or not value["healthCheckPath"].startswith("/") or " " in value["healthCheckPath"]:
        fail("healthCheckPath must start with / and contain no spaces")

    ingress = require_object(value, "ingress")
    if not isinstance(ingress.get("enabled"), bool):
        fail("ingress.enabled must be true or false")
    if ingress["enabled"] and (not isinstance(ingress.get("host"), str) or not HOST_PATTERN.fullmatch(ingress["host"])):
        fail("ingress.host must be a valid DNS hostname when ingress is enabled")

    key_vault = require_object(value, "keyVaultAccess")
    if not isinstance(key_vault.get("enabled"), bool):
        fail("keyVaultAccess.enabled must be true or false")
    if key_vault["enabled"] and (not isinstance(key_vault.get("secretName"), str) or not SECRET_PATTERN.fullmatch(key_vault["secretName"])):
        fail("keyVaultAccess.secretName must be a lowercase Key Vault secret name when access is enabled")

    identity = require_object(value, "workloadIdentity")
    if not isinstance(identity.get("enabled"), bool):
        fail("workloadIdentity.enabled must be true or false")
    if identity["enabled"] and (not valid_uuid(identity.get("clientId")) or not valid_uuid(identity.get("tenantId"))):
        fail("workloadIdentity.clientId and workloadIdentity.tenantId must be non-zero canonical UUIDs when workload identity is enabled")


def yaml_string(value: str) -> str:
    return json.dumps(value)


def render(value: dict) -> dict[str, str]:
    profile = PROFILES[value["resourceProfile"]]
    labels = {
        "app_name": value["name"],
        "owner": value["owner"],
        "environment": value["environment"],
        "namespace": value["namespace"],
        "image": value["image"],
        "health_path": value["healthCheckPath"],
        "request_cpu": profile["request_cpu"],
        "request_memory": profile["request_memory"],
        "limit_cpu": profile["limit_cpu"],
        "limit_memory": profile["limit_memory"],
    }
    app = yaml_string(labels["app_name"])
    app_name = labels["app_name"]
    owner = yaml_string(labels["owner"])
    environment = yaml_string(labels["environment"])
    namespace = yaml_string(labels["namespace"])
    image = yaml_string(labels["image"])
    health_path = yaml_string(labels["health_path"])
    workload_identity = value["workloadIdentity"]
    pod_identity_label = "        azure.workload.identity/use: \"true\"\n" if workload_identity["enabled"] else ""
    service_account_annotations = ""
    if workload_identity["enabled"]:
        service_account_annotations = (
            "  annotations:\n"
            f"    azure.workload.identity/client-id: {yaml_string(workload_identity['clientId'])}\n"
            f"    azure.workload.identity/tenant-id: {yaml_string(workload_identity['tenantId'])}\n"
        )

    secret_environment = ""
    if value["keyVaultAccess"]["enabled"]:
        secret_environment = (
            "          envFrom:\n"
            "            - secretRef:\n"
            f"                name: {app_name}-runtime\n"
        )

    files = {
        "namespace.yaml": f"""apiVersion: v1
kind: Namespace
metadata:
  name: {namespace}
  labels:
    app.kubernetes.io/managed-by: \"platform-golden-path\"
    platform.example.com/owner: {owner}
    platform.example.com/environment: {environment}
    platform.example.com/cost-center: {owner}
    pod-security.kubernetes.io/enforce: \"restricted\"
""",
        "service-account.yaml": f"""apiVersion: v1
kind: ServiceAccount
metadata:
  name: {app}
  namespace: {namespace}
  labels:
    app.kubernetes.io/name: {app}
    app.kubernetes.io/managed-by: \"platform-golden-path\"
{service_account_annotations}automountServiceAccountToken: false
""",
        "deployment.yaml": f"""apiVersion: apps/v1
kind: Deployment
metadata:
  name: {app}
  namespace: {namespace}
  labels:
    app.kubernetes.io/name: {app}
    app.kubernetes.io/part-of: \"azure-aks-platform\"
    app.kubernetes.io/managed-by: \"platform-golden-path\"
    platform.example.com/owner: {owner}
    platform.example.com/environment: {environment}
    platform.example.com/cost-center: {owner}
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: {app}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {app}
        app.kubernetes.io/part-of: \"azure-aks-platform\"
        platform.example.com/owner: {owner}
        platform.example.com/environment: {environment}
{pod_identity_label}      annotations:
        prometheus.io/scrape: \"true\"
        prometheus.io/path: \"/metrics\"
        prometheus.io/port: \"8080\"
    spec:
      serviceAccountName: {app}
      automountServiceAccountToken: false
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: app
          image: {image}
          imagePullPolicy: IfNotPresent
{secret_environment}          ports:
            - name: http
              containerPort: 8080
          startupProbe:
            httpGet:
              path: {health_path}
              port: http
            periodSeconds: 5
            failureThreshold: 30
          readinessProbe:
            httpGet:
              path: {health_path}
              port: http
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: {health_path}
              port: http
            periodSeconds: 20
          resources:
            requests:
              cpu: {labels['request_cpu']}
              memory: {labels['request_memory']}
            limits:
              cpu: {labels['limit_cpu']}
              memory: {labels['limit_memory']}
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop: [\"ALL\"]
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            runAsUser: 10001
""",
        "service.yaml": f"""apiVersion: v1
kind: Service
metadata:
  name: {app}
  namespace: {namespace}
  labels:
    app.kubernetes.io/name: {app}
    platform.example.com/owner: {owner}
spec:
  selector:
    app.kubernetes.io/name: {app}
  ports:
    - name: http
      port: 80
      targetPort: http
  type: ClusterIP
""",
        "pdb.yaml": f"""apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {app}
  namespace: {namespace}
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: {app}
""",
        "hpa.yaml": f"""apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {app}
  namespace: {namespace}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {app}
  minReplicas: 2
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
""",
        "network-policy.yaml": f"""apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {app}
  namespace: {namespace}
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: {app}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
""",
    }

    if value["ingress"]["enabled"]:
        files["ingress.yaml"] = f"""apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {app}
  namespace: {namespace}
  labels:
    app.kubernetes.io/name: {app}
    platform.example.com/owner: {owner}
spec:
  ingressClassName: nginx
  rules:
    - host: {yaml_string(value['ingress']['host'])}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {app}
                port:
                  number: 80
"""

    if value["keyVaultAccess"]["enabled"]:
        files["external-secret.yaml"] = f"""apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: {app_name}-runtime
  namespace: {namespace}
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: azure-key-vault
  target:
    name: {app_name}-runtime
    creationPolicy: Owner
  data:
    - secretKey: runtime-token
      remoteRef:
        key: {yaml_string(value['keyVaultAccess']['secretName'])}
"""
    resources = ["namespace.yaml", "service-account.yaml", "deployment.yaml", "service.yaml", "pdb.yaml", "hpa.yaml", "network-policy.yaml"]
    if "ingress.yaml" in files:
        resources.append("ingress.yaml")
    if "external-secret.yaml" in files:
        resources.append("external-secret.yaml")
    files["kustomization.yaml"] = "apiVersion: kustomize.config.k8s.io/v1beta1\nkind: Kustomization\nresources:\n" + "".join(f"  - {resource}\n" for resource in resources)
    return files


def generate(config: Path, output: Path, check: bool) -> None:
    registration = read_registration(config)
    validate_registration(registration)
    if config.stem != registration["name"]:
        fail("the registration filename must match the application name")
    files = render(registration)
    if check:
        differences = [name for name, contents in files.items() if not (output / name).is_file() or (output / name).read_text(encoding="utf-8") != contents]
        unexpected = [path.name for path in output.glob("*.yaml")] if output.exists() else []
        unexpected = sorted(set(unexpected) - set(files))
        if differences or unexpected:
            details = ", ".join(sorted(differences + unexpected))
            raise ValueError(f"generated workload at {output} is out of date: {details}. Run onboard_application.py generate --config {config} --output {output}")
        return

    output.mkdir(parents=True, exist_ok=True)
    for existing in output.glob("*.yaml"):
        if existing.name not in files:
            existing.unlink()
    for name, contents in files.items():
        (output / name).write_text(contents, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate or generate a platform golden-path application.")
    parser.add_argument("command", choices=("validate", "generate", "check"))
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        if args.command == "validate":
            validate_registration(read_registration(args.config))
        else:
            if args.output is None:
                parser.error("--output is required for generate and check")
            generate(args.config, args.output, args.command == "check")
    except ValueError as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
