variable "ami_id" {
  description = "ID da AMI a usar na instância"
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância EC2. Ex: t3.micro, t3.small"
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "Nome da instância — aplicado na tag Name"
  type        = string
}

variable "key_name" {
  description = "Nome do Key Pair para acesso SSH"
  type        = string
}

variable "subnet_id" {
  description = "ID da subnet onde a instância será criada"
  type        = string
}

variable "security_group_ids" {
  description = "Lista de IDs de Security Groups a associar à instância"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "Nome do Instance Profile a associar à EC2. Recebido do módulo aws-iam-ec2. Null = sem role IAM."
  type        = string
  default     = null
}
