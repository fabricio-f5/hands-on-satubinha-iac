terraform {
  backend "s3" {
    bucket       = "satubinha-foundation-state"
    key          = "foundation/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}