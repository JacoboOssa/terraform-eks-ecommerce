# Public Subnets
resource "aws_subnet" "public" {
  count                   = local.num_azs
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  depends_on = [
    module.eks,            # tu módulo de EKS
    module.observability   # módulos helm (CNI, LB, EBS CSI)
  ]

  tags = merge(
    var.tags,
    {
      Name                                                            = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
      "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
      "kubernetes.io/role/elb"                                        = "1"
    }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = local.num_azs
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  depends_on = [
    module.eks,
    module.observability
  ]

  tags = merge(
    var.tags,
    {
      Name                                                            = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
      "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
      "kubernetes.io/role/internal-elb"                               = "1"
    }
  )
}
