terraform {
  backend "s3" {
    bucket       = "pge-dev-terraform-state-bucket"
    key          = "infrastructure/dev/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
