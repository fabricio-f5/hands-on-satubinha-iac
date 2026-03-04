# Hands-On Satubinha – Infraestrutura AWS com Terraform

Este projeto demonstra uma implementação prática (**Hands-On**) de **Infraestrutura como Código (IaC)** utilizando **Terraform** para provisionar recursos na AWS de forma modular e reutilizável.

A infraestrutura criada inclui:

* Instância **EC2**
* **Security Group**
* **SSH Key Pair**
* Armazenamento de **state remoto em S3** com **lockfile local**
* Ambientes separados: **dev**, **staging**, **prod**

O projeto segue boas práticas de **organização de código Terraform, modularização, outputs de módulos e versionamento com Git**.

---

## Objetivo do Projeto

Este projeto foi desenvolvido com os seguintes objetivos:

* Demonstrar conhecimentos em **Infrastructure as Code (IaC)**
* Provisionar infraestrutura na AWS usando **Terraform**
* Utilizar **arquitetura modular com outputs**
* Aplicar boas práticas de **Git e versionamento seguro**
* Criar ambientes **dev, staging e prod** isolados e reproduzíveis
* Integrar backend remoto seguro para manter **state compartilhado e bloqueios**

---

## Tecnologias Utilizadas

* Terraform
* AWS EC2
* AWS Security Groups
* SSH Key Pair
* AWS S3 para backend remoto
* Git / GitHub
* Linux

---

## Estrutura do Repositório

```text
hands-on-satubinha-iac/
│
├── environments/
│   ├── dev/
│   │   ├── backend.tf           # Configuração do backend S3 para dev
│   │   ├── main.tf              # Módulo raiz do ambiente dev
│   │   ├── variables.tf         # Variáveis do ambiente dev
│   │   └── terraform.tfvars     # Valores de variáveis (não versionar)
│   ├── staging/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── backend.tf
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
│
├── modules/
│   ├── aws-ec2-instance/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── aws-keypair/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── aws-security-group/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── README.md
└── .gitignore
````

---

## Separação de Ambientes por Pasta

**Decisão de design:** o projeto usa **pastas separadas para cada ambiente** (`dev`, `staging`, `prod`) em vez de **workspaces do Terraform**.

**Vantagens de pastas por ambiente:**

1. **Isolamento total:** cada ambiente tem seu próprio backend e state, evitando conflitos acidentais.
2. **Naming dinâmico mais simples:** nomes de recursos podem ser construídos usando `${var.env}` sem risco de duplicação.
3. **Mais alinhado ao mercado:** em empresas, pipelines CI/CD apontam para pastas específicas, simplificando testes e deploys.
4. **Menor risco de erro humano:** workspaces compartilham os mesmos arquivos `.tf`, aumentando chances de alterar o ambiente errado.
5. **Versionamento Git mais claro:** cada ambiente tem sua própria configuração e variáveis, fácil de auditar.

> Resumindo: **pastas = isolamento + segurança + facilidade de manutenção**, enquanto workspaces são mais úteis em projetos experimentais ou pequenos.

---

## Componentes da Infraestrutura

### Instância EC2

Criada através de um módulo Terraform reutilizável.

Características:

* AMI configurável
* Tipo de instância configurável
* Acesso SSH via Key Pair
* Associação com Security Group
* Outputs disponíveis: `instance_id`, `public_ip`, `private_ip`

---

### Security Group

Controla o acesso à instância EC2.

Portas liberadas:

| Porta | Protocolo | Finalidade  |
| ----- | --------- | ----------- |
| 22    | TCP       | Acesso SSH  |
| 80    | TCP       | Acesso HTTP |

O tráfego de saída (**egress**) é permitido para todos os destinos.
Outputs disponíveis: `sg_id`

---

### SSH Key Pair

Utilizado para acesso seguro à instância EC2.

O Terraform importa a **chave pública SSH da máquina local** e registra na AWS.
Output disponível: `key_name`

---

### Backend Remoto

O Terraform usa **S3 para armazenar o state** e **lockfile local (`use_lockfile = true`)** para evitar alterações simultâneas, garantindo:

* Colaboração segura entre múltiplos desenvolvedores
* Proteção contra alterações concorrentes
* Histórico de estado armazenado no S3

> ⚠️ Observação: o uso do DynamoDB para locks está sendo descontinuado; por isso utilizamos o lockfile local do Terraform.

---

## Como Executar o Projeto

### 1. Clonar o repositório

```bash
git clone https://github.com/fabricio-f5/hands-on-satubinha-iac.git
cd hands-on-satubinha-iac
```

---

### 2. Inicializar o Terraform para um ambiente

```bash
cd environments/dev
terraform init -reconfigure
```

> Substitua `dev` por `staging` ou `prod` conforme necessário.

---

### 3. Visualizar o plano de execução

```bash
terraform plan -var-file="terraform.tfvars"
```

---

### 4. Aplicar a infraestrutura

```bash
terraform apply -var-file="terraform.tfvars"
```

Confirme digitando **yes** quando solicitado.

---

### 5. Conectar à instância EC2

```bash
ssh -i ~/.ssh/id_rsa ec2-user@<ip-publico>
```

Substitua `<ip-publico>` pelo IP público obtido via `terraform output`.

---

## Boas Práticas Aplicadas

* Estado remoto seguro (`S3 + use_lockfile = true`)
* Estrutura modular com outputs de todos os módulos
* Pastas separadas por ambiente (`dev`, `staging`, `prod`)
* Arquivos de state, planos e variáveis sensíveis **não versionados**
* `.gitignore` configurado para manter repositório limpo
* Naming dinâmico por ambiente usando `${var.env}`

---

## Possíveis Melhorias

* Pipeline CI/CD para aplicar Terraform automaticamente
* Módulo de VPC para isolar rede dos ambientes
* Deploy de Auto Scaling Group e Load Balancer
* Testes automatizados de `terraform fmt` e `validate` em PRs

---

## Autor

**Fabricio Peloso**
Interessado em Cloud Computing, DevOps e automação de infraestrutura.


