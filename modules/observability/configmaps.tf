# Kubernetes namespace for monitoring
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name        = "monitoring"
      environment = var.environment
    }
  }
}

# Kubernetes namespace for logging
resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
    labels = {
      name        = "logging"
      environment = var.environment
    }
  }
}

# StorageClass for monitoring (gp3)
resource "kubernetes_storage_class" "monitoring" {
  metadata {
    name = "monitoring-gp3"
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type      = "gp3"
    encrypted = "true"
    iops      = "3000"
    throughput = "125"
  }

  allow_volume_expansion = true
}

# StorageClass for logging (gp3)
resource "kubernetes_storage_class" "logging" {
  metadata {
    name = "logging-gp3"
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type      = "gp3"
    encrypted = "true"
    iops      = "3000"
    throughput = "125"
  }

  allow_volume_expansion = true
}
