terraform {
  backend "s3" {
    bucket = "ingesoftv-ecommerce-terraform-state"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
  }
}