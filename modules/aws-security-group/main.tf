resource "aws_security_group" "this" {
  name        = var.name
  description = "Security group for EC2 with SSH and internal TLS"
  vpc_id      = var.vpc_id

  tags = {
    Name = var.name
  }

  # Entrada SSH pública (IPv4 e IPv6)
  ingress {
    description      = "SSH access from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Entrada TLS interno VPC IPv4
  ingress {
    description = "TLS from VPC IPv4"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }

  # Entrada TLS interno VPC IPv6
  ingress {
    description      = "TLS from VPC IPv6"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
  }

  # Saída completa IPv4
  egress {
    description = "All outbound IPv4 traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Saída completa IPv6
  egress {
    description      = "All outbound IPv6 traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
}