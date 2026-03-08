terraform {
  backend "s3" {
    bucket       = "satubinha-dev-state"
    key          = "environments/dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
