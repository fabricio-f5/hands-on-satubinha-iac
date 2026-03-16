data "aws_ami" "aws_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  owners = [var.ami_owner]
}

# IAM: Role do GitHub Actions (OIDC)
# Permite que o pipeline assuma credenciais temporárias na AWS
# Output role_arn → adicionar como secret AWS_ROLE_ARN no repositório GitHub
module "github_oidc" {
  source = "../../modules/aws-iam-oidc-github"

  github_repo = "fabricio-f5/hands-on-satubinha-iac"
  github_ref  = "ref:refs/heads/main" # prod: apenas a branch main pode assumir essa role
  role_name   = "github-actions-prod-role"

  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser", # push de imagens no ECR
  ]
}

# IAM: Role da EC2
# Permite que a instância faça pull de imagens no ECR via Instance Profile
# O instance_profile_name é passado para o módulo ec2_instance abaixo
module "ec2_iam" {
  source = "../../modules/aws-iam-ec2"

  instance_name = "satubinha-${var.environment}-app"

  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", # pull de imagens no ECR
    #"arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",       # acesso via SSM (sem abrir porta SSH)
  ]
}

# EC2 Instance 
# A instância não sabe nada sobre IAM — só recebe o profile pronto
module "ec2_instance" {
  source = "../../modules/aws-ec2-instance"

  ami_id               = data.aws_ami.aws_linux.id
  instance_name        = "satubinha-${var.environment}-app"
  instance_type        = var.instance_type
  key_name             = module.keypair.key_name
  subnet_id            = var.subnet_id
  security_group_ids   = [module.sg.sg_id]
  iam_instance_profile = module.ec2_iam.instance_profile_name # <- conexão entre módulos
}

# Key Pair
module "keypair" {
  source          = "../../modules/aws-keypair"
  key_name        = "satubinha-${var.environment}-key"
  public_key_path = var.public_key_path
}

# Security Group
module "sg" {
  source = "../../modules/aws-security-group"
  name   = "satubinha-${var.environment}-sg"
  vpc_id = var.vpc_id
}



