variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for EKS"
  type        = string
}

variable "prometheus_retention_days" {
  description = "Retention period for Prometheus metrics in days"
  type        = number
  default     = 15
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "50Gi"
}


variable "elasticsearch_node_count" {
  description = "Number of Elasticsearch nodes"
  type        = number
  default     = 1
}

variable "elasticsearch_storage_size" {
  description = "Storage size for each Elasticsearch node"
  type        = string
  default     = "30Gi"
}

variable "elasticsearch_retention_days" {
  description = "Retention period for Elasticsearch indices in days"
  type        = number
  default     = 7
}

variable "enable_metrics_server" {
  description = "Enable metrics server installation"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "alb_controller_role_arn" {
  description = "IAM Role ARN for AWS Load Balancer Controller"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde está desplegado el cluster EKS"
  type        = string
}


