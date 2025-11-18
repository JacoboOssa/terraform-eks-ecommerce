# Development Environment Configuration
# us-east-1 region

# General Configuration
project_name = "ecommerce"
environment  = "dev"
region       = "us-east-1"
cost_center  = "engineering"
team         = "platform"

# Network Configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
enable_nat_gateway   = true

# EKS Configuration
cluster_version = "1.29"
node_group_config = {
  desired_size   = 2
  max_size       = 4
  min_size       = 2
  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
}

# Observability Configuration
prometheus_retention_days    = 15
prometheus_storage_size      = "30Gi"
elasticsearch_node_count     = 1
elasticsearch_storage_size   = "20Gi"
elasticsearch_retention_days = 7

# Note: grafana_admin_password should be provided via environment variables or secret management:
# export TF_VAR_grafana_admin_password="your-password"

additional_tags = {
  Terraform   = "true"
  Owner       = "platform-team"
  CostOptimization = "enabled"
}
