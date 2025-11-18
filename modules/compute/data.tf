data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# Get OIDC provider thumbprint
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}
