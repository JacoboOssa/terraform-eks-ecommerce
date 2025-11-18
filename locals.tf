locals {
  # Common identifiers
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Network configuration
  num_azs = length(var.availability_zones)
  
  # Tags merged from tagging module
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Region      = var.region
      Team        = var.team
      CostCenter  = var.cost_center
    },
    var.additional_tags
  )
}
