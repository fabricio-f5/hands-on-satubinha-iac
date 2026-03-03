variable "ami_id" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "project_name" {
  type = string
  default = "satubinha"
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "key_name" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}
