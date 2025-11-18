# Staging Environment Configuration
# us-east-1 region

# General Configuration
project_name = "ecommerce"
environment  = "stage"
region       = "us-east-1"
cost_center  = "engineering"
team         = "platform"

# Network Configuration
vpc_cidr             = "10.1.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
enable_nat_gateway   = true

# EKS Configuration
cluster_version = "1.29"
node_group_config = {
  desired_size   = 3
  max_size       = 8
  min_size       = 3
  instance_types = ["t3.large"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 100
}

# Observability Configuration
prometheus_retention_days    = 30
prometheus_storage_size      = "50Gi"
elasticsearch_node_count     = 2
elasticsearch_storage_size   = "50Gi"
elasticsearch_retention_days = 15

# Note: grafana_admin_password should be provided via environment variables or secret management:
# export TF_VAR_grafana_admin_password="your-password"

additional_tags = {
  Terraform   = "true"
  Owner       = "platform-team"
  Criticality = "medium"
}
