terraform {
  backend "s3" {
    bucket = "satubinha-prod-state"
    key = "dev/terraform-state"
    region = "us-east-1"
    use_lockfile = true
  }
}
