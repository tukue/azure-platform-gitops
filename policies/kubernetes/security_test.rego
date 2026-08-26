package kubernetes.security

secure_deployment := {
  "apiVersion": "apps/v1",
  "kind": "Deployment",
  "metadata": {
    "name": "secure-api",
    "labels": {
      "platform.example.com/owner": "platform-team",
      "platform.example.com/environment": "dev"
    }
  },
  "spec": {
    "template": {
      "spec": {
        "securityContext": {"runAsNonRoot": true},
        "containers": [{
          "name": "api",
          "image": "registry.example/api:1.0.0",
          "securityContext": {
            "allowPrivilegeEscalation": false,
            "readOnlyRootFilesystem": true
          },
          "resources": {
            "requests": {"cpu": "100m", "memory": "128Mi"},
            "limits": {"cpu": "500m", "memory": "256Mi"}
          },
          "readinessProbe": {"httpGet": {"path": "/health", "port": 8080}},
          "livenessProbe": {"httpGet": {"path": "/health", "port": 8080}},
          "startupProbe": {"httpGet": {"path": "/health", "port": 8080}}
        }]
      }
    }
  }
}

test_secure_deployment_is_allowed if {
  result := deny with input as secure_deployment
  count(result) == 0
}

test_latest_image_is_denied if {
  insecure := object.union(secure_deployment, {"spec": {"template": {"spec": {"containers": [{"name": "api", "image": "registry.example/api:latest"}]}}}})
  result := deny with input as insecure
  result[_] == "Deployment secure-api container api must not use the latest image tag"
}
