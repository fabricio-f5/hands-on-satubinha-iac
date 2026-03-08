data "aws_ami" "aws_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  owners = [var.ami_owner] # aws
}


module "ec2_instance" {
  source             = "../../modules/aws-ec2-instance"
  ami_id             = data.aws_ami.aws_linux.id
  instance_name      = "satubinha-${var.environment}-app"
  key_name           = module.keypair.key_name
  security_group_ids = [module.sg.sg_id]

}

module "keypair" {
  source          = "../../modules/aws-keypair"
  key_name        = "satubinha-${var.environment}-key"
  public_key_path = var.public_key_path
}

module "sg" {
  source = "../../modules/aws-security-group"
  name   = "satubinha-${var.environment}-sg"
  vpc_id = var.vpc_id
}



