# General Outputs
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

# Network Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.network.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.network.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = module.network.nat_gateway_ids
}

# EKS Outputs
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.compute.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.compute.cluster_endpoint
}

output "eks_cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = module.compute.cluster_version
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.compute.cluster_security_group_id
}

output "eks_node_security_group_id" {
  description = "EKS node security group ID"
  value       = module.compute.node_security_group_id
}

output "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = module.compute.oidc_provider_arn
}

# Observability Outputs - TEMPORARILY DISABLED
# output "monitoring_namespace" {
#   description = "Kubernetes namespace for monitoring"
#   value       = module.observability.monitoring_namespace
# }
#
# output "logging_namespace" {
#   description = "Kubernetes namespace for logging"
#   value       = module.observability.logging_namespace
# }
#
# output "grafana_service" {
#   description = "Grafana service name"
#   value       = module.observability.grafana_service
# }
#
# output "prometheus_service" {
#   description = "Prometheus service name"
#   value       = module.observability.prometheus_service
# }
#
# output "kibana_service" {
#   description = "Kibana service name"
#   value       = module.observability.kibana_service
# }
#
# output "elasticsearch_service" {
#   description = "Elasticsearch service name"
#   value       = module.observability.elasticsearch_service
# }

# Connection Commands
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.compute.cluster_name}"
}

# output "grafana_port_forward" {
#   description = "Command to port-forward to Grafana"
#   value       = "kubectl port-forward -n ${module.observability.monitoring_namespace} svc/${module.observability.grafana_service} 3000:80"
# }
#
# output "kibana_port_forward" {
#   description = "Command to port-forward to Kibana"
#   value       = "kubectl port-forward -n ${module.observability.logging_namespace} svc/${module.observability.kibana_service} 5601:5601"
# }
#
# output "prometheus_port_forward" {
#   description = "Command to port-forward to Prometheus"
#   value       = "kubectl port-forward -n ${module.observability.monitoring_namespace} svc/${module.observability.prometheus_service} 9090:9090"
# }
