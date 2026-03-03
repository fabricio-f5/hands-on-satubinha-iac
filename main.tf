provider "aws" {
  region = var.region
}

data "aws_ami" "aws" {
  most_recent = true

  filter {
    name = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.20260120.1-x86_64-ebs"]
  }

  owners = ["137112412989"] # aws
}

resource "random_pet" "instance" {
  length = 2
}

module "ec2-instance" {
  source = "./modules/aws-ec2-instance"
  ami_id        = data.aws_ami.aws.id
  instance_name = "satubinha-${random_pet.instance.id}"
  key_name = module.keypair.key_name
  security_group_ids = [module.sg.sg_id]

}

module "keypair" {
  source = "./modules/aws-keypair"
  key_name = "satubinha-key"
  public_key_path = "~/.ssh/id_ed25519.pub"
}

module "sg" {
  source = "./modules/aws-security-group"
  name = "satubinha-sg"
  vpc_id = "vpc-0c12d58c505cefcf3"
}

