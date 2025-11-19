# Metrics Server
resource "helm_release" "metrics_server" {
  count      = var.enable_metrics_server ? 1 : 0
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.11.0"
  namespace  = "kube-system"
  set = [
    {
      name  = "replicas"
      value = var.environment == "prod" ? "2" : "1"
    },
    {
      name  = "args[0]"
      value = "--kubelet-insecure-tls"
    }
  ]
}

# Prometheus Stack (includes Prometheus, Grafana, AlertManager)
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "54.0.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  
  timeout          = 1800
  wait             = false
  atomic           = false
  cleanup_on_fail  = true
  replace          = true
  disable_webhooks = true


  values = [
    file("${path.module}/../../kubernetes-manifests/monitoring/prometheus-values.yaml")
  ]
  set = [
    {
      name  = "prometheus.prometheusSpec.retention"
      value = "${var.prometheus_retention_days}d"
    },
    {
      name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
      value = var.prometheus_storage_size
    },
    {
      name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
      value = kubernetes_storage_class.monitoring.metadata[0].name
    },
    # adminPassword se define directamente en el values.yaml como "12345678"
    {
      name  = "grafana.adminUser"
      value = "admin"
    },
    {
      name  = "grafana.persistence.enabled"
      value = "true"
    },
    {
      name  = "grafana.persistence.size"
      value = "10Gi"
    },
    {
      name  = "grafana.persistence.storageClassName"
      value = kubernetes_storage_class.monitoring.metadata[0].name
    },
    {
      name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage"
      value = "10Gi"
    },
    {
      name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName"
      value = kubernetes_storage_class.monitoring.metadata[0].name
    },
    {
      name  = "prometheusOperator.admissionWebhooks.enabled"
      value = "false"
    },
    {
      name  = "prometheusOperator.tls.enabled"
      value = "false"
    }
  ]

  depends_on = [
    kubernetes_namespace.monitoring,
    kubernetes_storage_class.monitoring
  ]
}

# Elasticsearch
resource "helm_release" "elasticsearch" {
  name       = "elasticsearch"
  repository = "https://helm.elastic.co"
  chart      = "elasticsearch"
  version    = "8.5.1"
  namespace  = kubernetes_namespace.logging.metadata[0].name

  timeout = 600
  
  values = [
    file("${path.module}/../../kubernetes-manifests/logging/elasticsearch-values.yaml")
  ]

  depends_on = [
    kubernetes_namespace.logging,
    kubernetes_storage_class.logging
  ]
}


# Kibana
resource "helm_release" "kibana" {
  name       = "kibana"
  repository = "https://helm.elastic.co"
  chart      = "kibana"
  version    = "8.5.1"
  namespace  = kubernetes_namespace.logging.metadata[0].name

  timeout         = 1200
  cleanup_on_fail = true
  replace         = true
  atomic          = true
  disable_openapi_validation = true

  values = [
    file("${path.module}/../../kubernetes-manifests/logging/kibana-values.yaml")
  ]

  depends_on = [
    helm_release.elasticsearch
  ]
}



# Logstash
resource "helm_release" "logstash" {
  name       = "logstash"
  repository = "https://helm.elastic.co"
  chart      = "logstash"
  version    = "8.5.1"
  namespace  = kubernetes_namespace.logging.metadata[0].name

  values = [
    file("${path.module}/../../kubernetes-manifests/logging/logstash-values.yaml")
  ]

  depends_on = [
    helm_release.elasticsearch
  ]
}


# Filebeat (DaemonSet for log collection)
resource "helm_release" "filebeat" {
  name       = "filebeat"
  repository = "https://helm.elastic.co"
  chart      = "filebeat"
  version    = "8.5.1"
  namespace  = kubernetes_namespace.logging.metadata[0].name

  values = [
    file("${path.module}/../../kubernetes-manifests/logging/filebeat-daemonset.yaml")
  ]

  depends_on = [
    helm_release.logstash
  ]
}


# AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.2"
  namespace  = "kube-system"
  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "region"
      value = var.region
    },
    {
      name  = "vpcId"
      value = ""  # Auto-detected by the controller
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = var.oidc_provider_arn  # Note: This should reference the actual IAM role ARN from compute module
    }
  ]
}

# AWS EBS CSI Driver
resource "helm_release" "aws_ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  version    = "2.30.0"
  namespace  = "kube-system"

  set = [
    {
      name  = "controller.serviceAccount.create"
      value = "true"
    },
    {
      name  = "controller.serviceAccount.name"
      value = "ebs-csi-controller-sa"
    }
  ]
}

resource "null_resource" "ensure_helm_cleanup" {
  triggers = {
    cluster_name = var.cluster_name
    region       = var.region
    vpc_id       = var.vpc_id != null ? var.vpc_id : ""
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

CLUSTER="${self.triggers.cluster_name}"
REGION="${self.triggers.region}"
VPC_ID="${self.triggers.vpc_id}"

echo "=== Helm cleanup verification (robust) starting ==="

# configure kubeconfig
aws eks update-kubeconfig --name "${CLUSTER}" --region "${REGION}" 2>/dev/null || true

# helper waits
wait_for_no_pvcs_in_ns() {
  ns="$1"
  timeout=${2:-600}   # seconds
  echo "Waiting up to ${timeout}s for PVCs in namespace '$ns' to disappear..."
  start=$(date +%s)
  while true; do
    if ! kubectl get ns "$ns" >/dev/null 2>&1; then
      echo "Namespace $ns not present; OK"
      return 0
    fi
    pvcs=$(kubectl get pvc -n "$ns" --no-headers 2>/dev/null | wc -l || echo 0)
    if [ "$pvcs" -eq 0 ]; then
      echo "No PVCs in $ns"
      return 0
    fi
    now=$(date +%s)
    if [ $((now - start)) -gt "$timeout" ]; then
      echo "Timeout waiting for PVCs in $ns"
      return 1
    fi
    sleep 5
  done
}

wait_for_no_lb_services() {
  timeout=${1:-600}
  echo "Waiting up to ${timeout}s for LoadBalancer services to disappear..."
  start=$(date +%s)
  while true; do
    lbs=$(kubectl get svc --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.spec.type=="LoadBalancer") | "\(.metadata.namespace)/\(.metadata.name)"' || echo "")
    if [ -z "$lbs" ]; then
      echo "No LoadBalancer services found"
      return 0
    fi
    now=$(date +%s)
    if [ $((now - start)) -gt "$timeout" ]; then
      echo "Timeout waiting for LoadBalancer services to disappear (still:)"
      echo "$lbs"
      return 1
    fi
    echo "LoadBalancer services still present (count: $(echo "$lbs" | wc -l)). Waiting..."
    sleep 5
  done
}

remove_namespace_finalizers() {
  ns="$1"
  if kubectl get ns "$ns" >/dev/null 2>&1; then
    echo "Removing finalizers from namespace $ns if any..."
    kubectl get ns "$ns" -o json \
      | jq '.spec.finalizers = []' \
      | kubectl replace --raw "/api/v1/namespaces/${ns}/finalize" -f - || true
  fi
}

delete_prometheus_crds() {
  echo "Deleting known Prometheus CRDs (ignore not-found)..."
  kubectl delete crd --ignore-not-found \
    alertmanagerconfigs.monitoring.coreos.com \
    alertmanagers.monitoring.coreos.com \
    podmonitors.monitoring.coreos.com \
    probes.monitoring.coreos.com \
    prometheuses.monitoring.coreos.com \
    prometheusrules.monitoring.coreos.com \
    servicemonitors.monitoring.coreos.com \
    thanosrulers.monitoring.coreos.com || true
}

delete_elasticsearch_crds() {
  echo "Deleting known Elasticsearch CRDs (ignore not-found)..."
  kubectl delete crd --ignore-not-found \
    elasticsearches.logging.k8s.elastic.co \
    kibanas.logging.k8s.elastic.co \
    beats.logging.k8s.elastic.co || true
}

wait_for_no_enis_in_vpc() {
  if [ -z "$VPC_ID" ]; then
    echo "No VPC_ID provided; skipping ENI check."
    return 0
  fi
  echo "Waiting for ENIs in VPC ${VPC_ID} to be 0 (timeout 900s)..."
  start=$(date +%s)
  timeout=900
  while true; do
    count=$(aws ec2 describe-network-interfaces --filters Name=vpc-id,Values="${VPC_ID}" --query 'length(NetworkInterfaces)' --output text 2>/dev/null || echo "0")
    echo "ENIs left in VPC ${VPC_ID}: ${count}"
    if [ "${count}" -eq "0" ]; then
      echo "No ENIs left in VPC ${VPC_ID}"
      return 0
    fi
    now=$(date +%s)
    if [ $((now - start)) -gt "$timeout" ]; then
      echo "Timeout waiting for ENIs to drain (left: ${count})"
      return 1
    fi
    sleep 10
  done
}

# --- main cleanup flow ---

# 1) wait for Helm releases to be removed by the provider (we rely on helm_release wait=true above)
echo "Allowing Kubernetes time to finalize release deletions..."
# small initial pause to let Helm start deletions
sleep 10

# 2) for each namespace try to wait for PVCs to go away; if blocked, remove finalizers & CRDs and try again
for ns in monitoring logging; do
  echo "Processing namespace: $ns"

  # attempt graceful wait for PVCs
  if ! wait_for_no_pvcs_in_ns "$ns" 600; then
    echo "PVCs did not disappear in namespace $ns; trying to remove finalizers and CRDs..."
    remove_namespace_finalizers "$ns"
    delete_prometheus_crds
    delete_elasticsearch_crds

    # give some time
    sleep 10
    # attempt wait again (shorter)
    wait_for_no_pvcs_in_ns "$ns" 300 || true
  fi
done

# 3) wait for all LoadBalancer services to be gone; if still present, attempt to delete them
if ! wait_for_no_lb_services 600; then
  echo "Forcing deletion of remaining LoadBalancer services..."
  kubectl get svc --all-namespaces -o json \
    | jq -r '.items[] | select(.spec.type=="LoadBalancer") | "\(.metadata.namespace)/\(.metadata.name)"' \
    | while read line; do
        ns=$(echo "$line" | cut -d'/' -f1)
        name=$(echo "$line" | cut -d'/' -f2)
        echo "Deleting svc $ns/$name"
        kubectl delete svc "$name" -n "$ns" --wait --timeout=300s || true
      done
fi

# 4) wait for ENIs in VPC to drain (if vpc_id provided)
wait_for_no_enis_in_vpc || {
  echo "ENIs still present after wait — printing current ENIs for diagnosis:"
  aws ec2 describe-network-interfaces --filters Name=vpc-id,Values="${VPC_ID}" --query 'NetworkInterfaces[*].{ID:NetworkInterfaceId,Desc:Description,Status:Status,Attach:Attachment.AttachmentId,InstanceId:Attachment.InstanceId}' --output table || true
  # don't fail the destroy hard — just warn and continue
  echo "Warning: ENIs remain in VPC ${VPC_ID}. Terraform may still fail deleting subnets."
}

echo "=== Helm cleanup verification completed ==="
EOF
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    helm_release.kube_prometheus_stack,
    helm_release.elasticsearch,
    helm_release.kibana,
    helm_release.logstash,
    helm_release.filebeat,
    helm_release.aws_load_balancer_controller,
    helm_release.aws_ebs_csi_driver
  ]
}
