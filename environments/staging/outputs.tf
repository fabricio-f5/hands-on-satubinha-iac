output "ec2_info" {
  description = "Informacoes da instancia EC2"
  value = {
    id         = module.ec2_instance.instance_id
    public_ip  = module.ec2_instance.public_ip
    private_ip = module.ec2_instance.private_ip
  }
}

output "security_group_id" {
  description = "ID do security group associado a instancia"
  value       = module.sg.sg_id
}

output "keypair_name" {
  description = "Nome do key pair utilizado na EC2"
  value       = module.keypair.key_name
}

output "environment" {
  description = "Ambiente do deploy"
  value       = var.environment
}

output "ssh_connection" {
  description = "Comando SSH para acessar a instância"
  value       = "ssh ec2-user@${module.ec2_instance.public_ip}"
}