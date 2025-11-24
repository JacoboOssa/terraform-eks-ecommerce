# EKS Cluster Security Group
resource "aws_security_group" "cluster" {
  name        = "${var.project_name}-${var.environment}-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-cluster-sg"
    }
  )
}

# Allow cluster to communicate with worker nodes
resource "aws_security_group_rule" "cluster_egress_to_nodes" {
  description              = "Allow cluster to communicate with worker nodes"
  type                     = "egress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node_group.id
}

# Allow cluster to communicate with nodes on 443
resource "aws_security_group_rule" "cluster_egress_to_nodes_443" {
  description              = "Allow cluster to communicate with worker nodes on 443"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node_group.id
}

# Allow HTTPS traffic to cluster endpoint
resource "aws_security_group_rule" "cluster_ingress_https" {
  description       = "Allow HTTPS traffic to cluster endpoint"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# EKS Node Group Security Group
resource "aws_security_group" "node_group" {
  name        = "${var.project_name}-${var.environment}-eks-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name                                                            = "${var.project_name}-${var.environment}-eks-node-sg"
      "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "owned"
    }
  )
}

# Allow nodes to communicate with each other
resource "aws_security_group_rule" "node_ingress_self" {
  description              = "Allow nodes to communicate with each other"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.node_group.id
  source_security_group_id = aws_security_group.node_group.id
}

# Allow nodes to communicate with cluster
resource "aws_security_group_rule" "node_ingress_cluster" {
  description              = "Allow nodes to receive communication from cluster"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node_group.id
  source_security_group_id = aws_security_group.cluster.id
}

# Allow nodes to communicate with cluster on 443
resource "aws_security_group_rule" "node_ingress_cluster_443" {
  description              = "Allow nodes to receive communication from cluster on 443"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node_group.id
  source_security_group_id = aws_security_group.cluster.id
}

# Allow all egress from nodes
resource "aws_security_group_rule" "node_egress_all" {
  description       = "Allow all egress from nodes"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.node_group.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Permitir acceso externo a Eureka (8761)
resource "aws_security_group_rule" "node_ingress_eureka" {
  description       = "Allow external access to Eureka UI"
  type              = "ingress"
  from_port         = 8761
  to_port           = 8761
  protocol          = "tcp"
  security_group_id = aws_security_group.node_group.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Permitir acceso externo a Zipkin (9411)
resource "aws_security_group_rule" "node_ingress_zipkin" {
  description       = "Allow external access to Zipkin UI"
  type              = "ingress"
  from_port         = 9411
  to_port           = 9411
  protocol          = "tcp"
  security_group_id = aws_security_group.node_group.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Security Group para ALBs
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancers"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-alb-sg"
    }
  )
}

# Permitir tráfico HTTP desde Internet al ALB
resource "aws_security_group_rule" "alb_ingress_http" {
  description       = "Allow HTTP traffic from internet"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Permitir tráfico HTTPS desde Internet al ALB
resource "aws_security_group_rule" "alb_ingress_https" {
  description       = "Allow HTTPS traffic from internet"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Permitir todo el tráfico saliente del ALB
resource "aws_security_group_rule" "alb_egress_all" {
  description       = "Allow all outbound traffic from ALB"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Permitir que los nodos reciban tráfico del ALB en puerto 8081 (Nexus)
resource "aws_security_group_rule" "node_ingress_from_alb_nexus" {
  description              = "Allow traffic from ALB to Nexus"
  type                     = "ingress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node_group.id
  source_security_group_id = aws_security_group.alb.id
}

# Permitir que los nodos reciban tráfico del ALB en puertos de aplicación
resource "aws_security_group_rule" "node_ingress_from_alb_apps" {
  description              = "Allow traffic from ALB to application pods"
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 9500
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node_group.id
  source_security_group_id = aws_security_group.alb.id
}
