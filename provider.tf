provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = module.compute.cluster_endpoint
  cluster_ca_certificate = base64decode(module.compute.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.compute.cluster_name,
      "--region",
      var.region
    ]
  }
}

# Helm provider configuration
provider "helm" {
  kubernetes = {
    host                   = module.compute.cluster_endpoint
    cluster_ca_certificate = base64decode(module.compute.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.compute.cluster_name,
        "--region",
        var.region
      ]
    }
  }
}
