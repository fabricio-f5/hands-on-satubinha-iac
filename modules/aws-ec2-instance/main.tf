resource "aws_instance" "main" {
  ami = var.ami_id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = var.security_group_ids

  tags = {
    Name = var.instance_name
    Owner = "${var.project_name}-app"
  }
}
