# Production Environment Configuration
# us-east-1 region

# General Configuration
project_name = "ecommerce"
environment  = "prod"
region       = "us-east-1"
cost_center  = "engineering"
team         = "platform"

# Network Configuration
vpc_cidr             = "10.2.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_subnet_cidrs = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]
enable_nat_gateway   = true

# EKS Configuration
cluster_version = "1.29"
node_group_config = {
  desired_size   = 6
  max_size       = 10 #CAMBIAR A 20
  min_size       = 5
  instance_types = ["m7i-flex.large", "c7i-flex.large", "t3.small"]  
  capacity_type  = "ON_DEMAND"
  disk_size      = 100
}

# Observability Configuration
prometheus_retention_days    = 30
prometheus_storage_size      = "100Gi"
elasticsearch_node_count     = 3      # 3 nodes for high availability
elasticsearch_storage_size   = "50Gi"
elasticsearch_retention_days = 30


additional_tags = {
  Terraform   = "true"
  Owner       = "platform-team"
  Criticality = "high"
  Compliance  = "required"
  Backup      = "daily"
}
