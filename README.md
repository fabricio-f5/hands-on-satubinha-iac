# Hands-On Satubinha – Infraestrutura AWS com Terraform

Este projeto demonstra uma implementação prática (**Hands-On**) de **Infraestrutura como Código (IaC)** utilizando **Terraform** para provisionar recursos na AWS de forma modular e reutilizável.

A infraestrutura criada inclui:

* Instância **EC2**
* **Security Group**
* **SSH Key Pair**

O projeto segue boas práticas de **organização de código Terraform, modularização e versionamento com Git**.

---

## Objetivo do Projeto

Este projeto foi desenvolvido com os seguintes objetivos:

* Demonstrar conhecimentos em **Infrastructure as Code (IaC)**
* Provisionar infraestrutura na AWS usando **Terraform**
* Utilizar **arquitetura modular**
* Aplicar boas práticas de **Git para projetos de infraestrutura**
* Criar um ambiente **reproduzível e automatizado**

---

## Tecnologias Utilizadas

* Terraform
* AWS EC2
* AWS Security Groups
* SSH Key Pair
* Git / GitHub
* Linux

---

## Estrutura do Repositório

```id="pxn64o"
hands-on-satubinha-iac/
│
├── main.tf                # Módulo raiz que chama os módulos de infraestrutura
├── variables.tf           # Variáveis de entrada
├── terraform.tf           # Configuração do provider AWS
├── README.md
├── .gitignore
│
├── modules/
│   ├── aws-ec2-instance/
│   │   ├── main.tf
│   │   └── variables.tf
│   │
│   ├── aws-keypair/
│   │   ├── main.tf
│   │   └── variables.tf
│   │
│   └── aws-security-group/
│       ├── main.tf
│       └── variables.tf
```

---

## Componentes da Infraestrutura

### Instância EC2

Criada através de um módulo Terraform reutilizável.

Características:

* AMI configurável
* Tipo de instância configurável
* Acesso SSH via Key Pair
* Associação com Security Group

---

### Security Group

Controla o acesso à instância EC2.

Portas liberadas:

| Porta | Protocolo | Finalidade  |
| ----- | --------- | ----------- |
| 22    | TCP       | Acesso SSH  |
| 80    | TCP       | Acesso HTTP |

O tráfego de saída (**egress**) é permitido para todos os destinos.

---

### SSH Key Pair

Utilizado para acesso seguro à instância EC2.

O Terraform importa a **chave pública SSH da máquina local** e registra na AWS.

---

## Como Executar o Projeto

### 1. Clonar o repositório

```bash id="crd0ts"
git clone https://github.com/fabricio-f5/hands-on-satubinha-iac.git
cd hands-on-satubinha-iac
```

---

### 2. Inicializar o Terraform

```bash id="q9o4yb"
terraform init
```

Este comando baixa os providers necessários.

---

### 3. Visualizar o plano de execução

```bash id="rrkwyr"
terraform plan
```

---

### 4. Aplicar a infraestrutura

```bash id="x67n3p"
terraform apply
```

Confirme digitando **yes** quando solicitado.

---

## Acessando a Instância EC2

Após a criação da infraestrutura, conecte via SSH:

```bash id="t9is95"
ssh -i ~/.ssh/id_rsa ec2-user@<ip-publico>
```

Substitua `<ip-publico>` pelo IP público da instância criada.

---

## Boas Práticas Aplicadas

* Arquivos de estado do Terraform **não são versionados**
* Diretório `.terraform` **ignorado no Git**
* Estrutura modular para **reutilização de código**
* Separação clara entre **módulo raiz e módulos de infraestrutura**

---

## Possíveis Melhorias

Evoluções futuras para o projeto:

* Backend remoto do Terraform (S3 + DynamoDB)
* Suporte a múltiplos ambientes (dev / staging / prod)
* Pipeline CI/CD para Terraform
* Integração com módulo de VPC
* Deploy de Auto Scaling Group

---

## Autor

**Fabricio F**

Interessado em Cloud Computing, DevOps e automação de infraestrutura.

GitHub:
https://github.com/fabricio-f5

