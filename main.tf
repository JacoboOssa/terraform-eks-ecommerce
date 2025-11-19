# Network Module
module "network" {
  source = "./modules/network"

  project_name         = var.project_name
  environment          = var.environment
  region               = var.region
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway

  tags = local.common_tags
}

# Compute Module (EKS)
module "compute" {
  source = "./modules/compute"

  project_name        = var.project_name
  environment         = var.environment
  region              = var.region
  vpc_id              = module.network.vpc_id
  private_subnet_ids  = module.network.private_subnet_ids
  public_subnet_ids   = module.network.public_subnet_ids
  cluster_version     = var.cluster_version
  node_group_config   = var.node_group_config

  tags = local.common_tags

  depends_on = [module.network]
}

# Observability Module - TEMPORARILY DISABLED DUE TO HELM SYNTAX ISSUES
module "observability" {
  source = "./modules/observability"
  
  project_name                        = var.project_name
  environment                         = var.environment
  region                              = var.region
  cluster_name                        = module.compute.cluster_name
  cluster_endpoint                    = module.compute.cluster_endpoint
  cluster_certificate_authority_data  = module.compute.cluster_certificate_authority_data
  oidc_provider_arn                   = module.compute.oidc_provider_arn
  prometheus_retention_days           = var.prometheus_retention_days
  prometheus_storage_size             = var.prometheus_storage_size
  elasticsearch_node_count            = var.elasticsearch_node_count
  elasticsearch_storage_size          = var.elasticsearch_storage_size
  elasticsearch_retention_days        = var.elasticsearch_retention_days
  
  tags = local.common_tags
  
  depends_on = [module.compute]
}
