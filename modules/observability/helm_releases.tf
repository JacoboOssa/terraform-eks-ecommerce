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

resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    
    annotations = {
      "eks.amazonaws.com/role-arn" = var.alb_controller_role_arn
    }

    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
  }
}



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
      value = var.vpc_id
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
    },
    {
      name  = "replicaCount"
      value = var.environment == "prod" ? "2" : "1"
    },
    {
      name  = "resources.requests.cpu"
      value = "100m"
    },
    {
      name  = "resources.requests.memory"
      value = "200Mi"
    },
    {
      name  = "resources.limits.cpu"
      value = var.environment == "prod" ? "300m" : "200m"
    },
    {
      name  = "resources.limits.memory"
      value = "500Mi"
    },
    {
      name  = "logLevel"
      value = var.environment == "prod" ? "info" : "debug"
    },
    {
      name  = "enableServiceMutatorWebhook"
      value = "true"
    },
    {
      name  = "enableShield"
      value = "false"
    },
    {
      name  = "enableWaf"
      value = "false"
    },
    {
      name  = "enableWafv2"
      value = "false"
    }
  ]

  depends_on = [
    kubernetes_service_account.aws_load_balancer_controller
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
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      #!/bin/bash
      set -e
      
      echo "=== Starting Helm cleanup verification ==="
      
      # Configurar kubectl
      aws eks update-kubeconfig \
        --name ${self.triggers.cluster_name} \
        --region ${self.triggers.region} 2>/dev/null || true
      
      # Esperar a que Helm termine de eliminar recursos
      echo "Waiting for Helm releases to be fully removed..."
      sleep 120
      
      # Verificar y eliminar PVCs manualmente si aún existen
      for ns in monitoring logging; do
        if kubectl get namespace $ns &>/dev/null; then
          echo "Checking PVCs in namespace: $ns"
          
          PVCS=$(kubectl get pvc -n $ns --no-headers 2>/dev/null | awk '{print $1}' || echo "")
          if [ ! -z "$PVCS" ]; then
            echo "Deleting remaining PVCs in $ns..."
            kubectl delete pvc --all -n $ns --timeout=300s --wait=true || true
          fi
        fi
      done
      
      # Verificar LoadBalancers
      echo "Checking for LoadBalancer services..."
      LB_SERVICES=$(kubectl get svc --all-namespaces -o json 2>/dev/null | \
        jq -r '.items[] | select(.spec.type=="LoadBalancer") | "\(.metadata.namespace)/\(.metadata.name)"' || echo "")
      
      if [ ! -z "$LB_SERVICES" ]; then
        echo "Deleting LoadBalancer services..."
        echo "$LB_SERVICES" | while read svc; do
          NS=$(echo $svc | cut -d/ -f1)
          NAME=$(echo $svc | cut -d/ -f2)
          kubectl delete svc $NAME -n $NS --timeout=300s --wait=true || true
        done
      fi
      
      # Esperar adicional para que AWS libere ENIs
      echo "Waiting for AWS to release ENIs..."
      sleep 120
      
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