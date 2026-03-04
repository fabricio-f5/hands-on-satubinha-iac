variable "region" {
  type    = string
  default = "us-east-1"
}

variable "ami_name" {
  type    = string
}

variable "ami_owner" {
  type    = string
}

variable "public_key_path" {
  type    = string
}

variable "vpc_id" {
  type    = string
}

variable "env" {
  type    = string
}
