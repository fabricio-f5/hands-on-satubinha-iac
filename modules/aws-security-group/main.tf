resource "aws_security_group" "this" {
  name        = var.name
  description = "Security group for EC2"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

output "sg_id" {
  value = aws_security_group.this.id
}
