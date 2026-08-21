package kubernetes.security

workload_kinds := {"Deployment", "StatefulSet", "DaemonSet"}

is_workload if {
  input.kind in workload_kinds
}

pod_spec := input.spec.template.spec if {
  is_workload
}

deny contains msg if {
  is_workload
  not pod_spec.securityContext.runAsNonRoot
  msg := sprintf("%s %s must set pod securityContext.runAsNonRoot to true", [input.kind, input.metadata.name])
}

deny contains msg if {
  is_workload
  container := pod_spec.containers[_]
  container.securityContext.privileged == true
  msg := sprintf("%s %s container %s must not be privileged", [input.kind, input.metadata.name, container.name])
}

deny contains msg if {
  is_workload
  container := pod_spec.containers[_]
  container.securityContext.allowPrivilegeEscalation != false
  msg := sprintf("%s %s container %s must disable privilege escalation", [input.kind, input.metadata.name, container.name])
}

deny contains msg if {
  is_workload
  container := pod_spec.containers[_]
  container.securityContext.readOnlyRootFilesystem != true
  msg := sprintf("%s %s container %s must use a read-only root filesystem", [input.kind, input.metadata.name, container.name])
}

deny contains msg if {
  is_workload
  container := pod_spec.containers[_]
  not container.resources.requests.cpu
  msg := sprintf("%s %s container %s must set a CPU request", [input.kind, input.metadata.name, container.name])
}

deny contains msg if {
  is_workload
  container := pod_spec.containers[_]
  not container.resources.requests.memory
  msg := sprintf("%s %s container %s must set a memory request", [input.kind, input.metadata.name, container.name])
}

deny contains msg if {
  is_workload
  container := pod_spec.containers[_]
  not container.resources.limits.cpu
  msg := sprintf("%s %s container %s must set a CPU limit", [input.kind, input.metadata.name, container.name])
}

deny contains msg if {
  is_workload
  container := pod_spec.containers[_]
  not container.resources.limits.memory
  msg := sprintf("%s %s container %s must set a memory limit", [input.kind, input.metadata.name, container.name])
}

deny contains msg if {
  is_workload
  container := pod_spec.containers[_]
  endswith(container.image, ":latest")
  msg := sprintf("%s %s container %s must not use the latest image tag", [input.kind, input.metadata.name, container.name])
}

deny contains msg if {
  is_workload
  container := pod_spec.containers[_]
  not container.readinessProbe
  msg := sprintf("%s %s container %s must define a readiness probe", [input.kind, input.metadata.name, container.name])
}

deny contains msg if {
  is_workload
  container := pod_spec.containers[_]
  not container.livenessProbe
  msg := sprintf("%s %s container %s must define a liveness probe", [input.kind, input.metadata.name, container.name])
}
