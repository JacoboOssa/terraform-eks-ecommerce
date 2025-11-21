locals {
  num_azs = length(var.availability_zones)
  
  nat_gateway_count = var.enable_nat_gateway ? 1 : 0
  
  vpc_name = "${var.project_name}-${var.environment}-vpc"
}

