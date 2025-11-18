variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ecommerce"
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be dev, stage, or prod."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

variable "team" {
  description = "Team responsible for the resources"
  type        = string
  default     = "platform"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

# EKS Configuration
variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_group_config" {
  description = "Configuration for EKS node group"
  type = object({
    desired_size   = number
    max_size       = number
    min_size       = number
    instance_types = list(string)
    capacity_type  = string
    disk_size      = number
  })
  default = {
    desired_size   = 2
    max_size       = 5
    min_size       = 2
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 50
  }
}

# Observability Configuration
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

# Additional Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
