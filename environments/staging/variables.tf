variable "region" {
  description = "AWS Region Deploy"
  type        = string
  default     = "us-east-1"
}

variable "ami_name" {
  description = "AMI name filter"
  type        = string
}

variable "ami_owner" {
  description = "AMI owner account id"
  type        = string
}

variable "public_key_path" {
  description = "Path to SSH public key"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}
