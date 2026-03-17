# Hands-On Satubinha – Infraestrutura AWS com Terraform

Implementação prática de **Infraestrutura como Código (IaC)** utilizando **Terraform** para provisionar recursos na AWS de forma modular, segura e reutilizável, com pipeline CI/CD completo via GitHub Actions.

A infraestrutura criada inclui:

- Instância **EC2** com IMDSv2 e EBS encriptado
- **Security Group** com regras de ingress/egress explícitas
- **SSH Key Pair** (chave pública injetada via GitHub Secret — sem arquivo no runner)
- Armazenamento de **state remoto em S3** com lockfile nativo
- **IAM Role da EC2** para acesso ao ECR (módulo `aws-iam-ec2`)
- **IAM Role do GitHub Actions** via OIDC (módulo `aws-iam-oidc-github`, gerido pela camada `foundation`)
- Ambientes separados: **dev**, **staging**, **prod**

---

## Tecnologias Utilizadas

- Terraform
- AWS EC2, S3, IAM, Security Groups, Key Pair, ECR
- GitHub Actions (CI/CD)
- AWS OIDC (autenticação sem credenciais estáticas)
- Checkov (scan de segurança IaC)
- Linux

---

## Estrutura do Repositório

```text
hands-on-satubinha-iac/
│
├── .github/
│   └── workflows/
│       ├── terraform-dev.yaml       # Pipeline do ambiente dev
│       ├── terraform-staging.yaml   # Pipeline do ambiente staging
│       └── terraform-prod.yaml      # Pipeline do ambiente prod
│
├── foundation/                      # Recursos de conta — ciclo de vida permanente
│   ├── backend.tf                   # Backend S3 exclusivo da camada foundation
│   ├── main.tf                      # OIDC Provider + IAM Role do GitHub Actions
│   ├── outputs.tf                   # Outputs: role_arn, oidc_provider_arn
│   ├── providers.tf                 # Configuração do provider AWS
│   ├── variables.tf                 # Variáveis da camada foundation
│   └── foundation.tfvars            # Valores de variáveis (não versionado)
│
├── environments/
│   ├── dev/
│   │   ├── backend.tf           # Backend S3 para dev
│   │   ├── main.tf              # Módulo raiz do ambiente dev
│   │   ├── outputs.tf           # Outputs do ambiente dev
│   │   ├── providers.tf         # Configuração do provider AWS
│   │   ├── variables.tf         # Variáveis do ambiente dev
│   │   └── dev.tfvars           # Valores de variáveis (não versionado)
│   ├── staging/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   └── staging.tfvars
│   └── prod/
│       ├── backend.tf
│       ├── main.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── prod-public.tfvars   # Variáveis não sensíveis (versionado)
│       └── prod-private.tfvars  # Gerado no runner via GitHub Secret
│
├── modules/
│   ├── aws-ec2-instance/        # Instância EC2 — recebe IAM profile como variável
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── aws-iam-ec2/             # IAM Role + Instance Profile da EC2
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── aws-iam-oidc-github/     # OIDC Provider + IAM Role do GitHub Actions
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── aws-keypair/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── aws-s3-bucket/
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
```

---

## Camadas da Infraestrutura

O projeto separa os recursos em duas camadas com ciclos de vida distintos:

| Camada | Pasta | Ciclo de vida | Quem executa |
|---|---|---|---|
| **Foundation** | `foundation/` | Permanente — nunca destruir | Manual, uma única vez por conta AWS |
| **Environments** | `environments/dev\|staging\|prod` | Efémero — destroy liberado | CI/CD via GitHub Actions |

### Por que separar?

O OIDC Provider e a IAM Role do GitHub Actions são recursos de **conta AWS**, não de ambiente. Se ficarem dentro de `environments/dev/`, um `terraform destroy` do ambiente destrói a autenticação de todos os pipelines.

A camada `foundation/` tem o seu próprio state remoto (`satubinha-foundation-state`) e nunca é executada pelo CI/CD — apenas manualmente quando necessário.

---

## Pipeline CI/CD

O projeto tem três workflows independentes, um por ambiente, todos acionados via **`workflow_dispatch`** com inputs manuais.

### Funcionalidades do pipeline

| Feature | Dev | Staging | Prod |
|---|---|---|---|
| `terraform fmt -check` | ✅ | ✅ | ✅ |
| `terraform validate` | ✅ | ✅ | ✅ |
| Checkov scan (IaC security) | ✅ | ✅ | ✅ |
| Apply condicional (só se há changes) | ✅ | ✅ | ✅ |
| Apply default | `true` | `false` | `false` |
| Autenticação AWS | OIDC | OIDC | OIDC |
| Environment gate (aprovação manual) | ❌ | ❌ | ✅ |
| Concurrency lock (bloqueia runs paralelos) | ❌ | ❌ | ✅ |
| Checkov report como artefacto | ✅ | ✅ | ✅ |
| Cleanup de ficheiros sensíveis | ✅ | ✅ | ✅ |

### Inputs disponíveis em cada workflow

```
apply          → Executar terraform apply? (default: true em dev, false em staging/prod)
plan_destroy   → Executar terraform plan para destroy?
destroy        → Executar terraform destroy?
```

---

## Segurança

### Autenticação AWS via OIDC

O projeto **não utiliza AWS Access Keys estáticas**. A autenticação é feita via **OpenID Connect (OIDC)**, onde o GitHub emite um token temporário por run que a AWS valida diretamente.

```yaml
- name: Configure AWS credentials via OIDC
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: us-east-1
    role-session-name: GitHubActions-${{ github.run_id }}
```

**Vantagens em relação a Access Keys:**
- Zero credenciais permanentes no repositório
- Token expira automaticamente ao fim de cada job
- Sem necessidade de rotação manual de chaves
- Auditoria nativa via CloudTrail por session name

### Separação de responsabilidades IAM

O projeto separa as permissões IAM em dois módulos dedicados:

| Módulo | Gerido por | Role | Permissão |
|---|---|---|---|
| `aws-iam-oidc-github` | `foundation/` | `github-actions-prod-role` | `ECRPowerUser` (push de imagens) |
| `aws-iam-ec2` | `environments/*/` | `*-ec2-role` | `ECRReadOnly` (pull de imagens) |

A IAM da EC2 é desacoplada do módulo `aws-ec2-instance` — o ambiente decide qual role associar, passando o `instance_profile_name` como variável.

### Injeção de chave SSH via secret

A chave pública SSH não é armazenada em ficheiro no repositório nem no runner. É injetada diretamente como variável Terraform via GitHub Secret:

```yaml
terraform plan -var="public_key=${{ secrets.SSH_PUBLIC_KEY }}"
```

Isso elimina o risco de ficheiro temporário no runner e remove a dependência da função `file()` no Terraform.

### Scan de segurança IaC (Checkov)

Cada pipeline executa o **Checkov** automaticamente antes do `terraform plan`, com o relatório guardado como artefacto do run.

Resultados do último scan: **29 passed, 9 failed (todos ignoráveis), 6 skipped (justificados)**

Skips documentados no código:
- `CKV_AWS_24` — SSH porta 22 aberto: IP dinâmico (5G) impede restrição por CIDR
- `CKV_AWS_382` — Egress total: ambiente de estudo, restrição por destino não é viável

### Hardening aplicado na infraestrutura

- **IMDSv2 obrigatório** na EC2 — bloqueia acesso ao metadata sem token (`http_tokens = required`)
- **Hop limit = 1** — impede que containers dentro da EC2 acedam ao IMDS
- **EBS encriptado** em todas as instâncias (`root_block_device { encrypted = true }`)
- **S3 Public Access Block** ativo em todos os buckets
- **IAM Role com princípio do menor privilégio** — EC2 só tem ECRReadOnly, GitHub Actions tem ECRPowerUser

---

## Separação de Ambientes por Pasta

O projeto usa **pastas separadas por ambiente** (`dev`, `staging`, `prod`) em vez de Terraform workspaces.

**Vantagens:**

1. **Isolamento total** — cada ambiente tem o seu próprio backend e state
2. **Sem risco de conflito** — workspaces partilham os mesmos `.tf`, aumentando risco de erro
3. **Pipeline CI/CD direto** — cada workflow aponta para a sua pasta
4. **Auditoria clara no Git** — cada ambiente tem a sua configuração e variáveis
5. **Alinhado ao mercado** — padrão utilizado em equipas profissionais

---

## Pré-requisitos

### AWS

- Conta AWS com permissões para EC2, S3, IAM, Security Groups, ECR
- Camada `foundation/` aplicada — cria o OIDC Provider e a IAM Role do GitHub Actions
- Buckets S3 para state remoto criados previamente via AWS CLI (um por camada)

### Buckets S3 necessários

| Bucket | Camada | Criação |
|---|---|---|
| `satubinha-foundation-state` | `foundation/` | Manual via AWS CLI |
| `satubinha-dev-state` | `environments/dev/` | Manual via AWS CLI |
| `satubinha-staging-state` | `environments/staging/` | Manual via AWS CLI |
| `satubinha-prod-state` | `environments/prod/` | Manual via AWS CLI |

### GitHub Secrets necessários

| Secret | Descrição |
|---|---|
| `AWS_ROLE_ARN` | ARN da IAM Role para OIDC (output da camada `foundation/`) |
| `SSH_PUBLIC_KEY` | Conteúdo da chave pública SSH (ex: `ssh-ed25519 AAAA...`) |
| `PROD_PRIVATE_TFVARS` | Conteúdo do ficheiro `prod-private.tfvars` |

### GitHub Environments

- `prod` — configurar **required reviewers** para aprovação manual antes de apply/destroy

---

## Como Executar

### 1. Clonar o repositório

```bash
git clone https://github.com/fabricio-f5/hands-on-satubinha-iac.git
cd hands-on-satubinha-iac
```

### 2. Aplicar a camada foundation (uma única vez)

```bash
cd foundation/
terraform init
terraform apply -var-file="foundation.tfvars"

# Anote o output — será o valor do secret AWS_ROLE_ARN no GitHub
terraform output github_actions_role_arn
```

> Se o OIDC Provider e a IAM Role já existirem na conta (criados manualmente),
> use `terraform import` para trazer os recursos para o state sem recriar.

### 3. Configurar credenciais AWS locais

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=us-east-1
```

### 4. Inicializar e aplicar um ambiente

```bash
cd environments/dev
terraform init
terraform plan -var-file="dev.tfvars" -var="public_key=$(cat ~/.ssh/id_ed25519.pub)"
terraform apply -var-file="dev.tfvars" -var="public_key=$(cat ~/.ssh/id_ed25519.pub)"
```

> Substitua `dev` por `staging` ou `prod` conforme necessário.

### 5. Conectar à instância EC2

```bash
ssh -i ~/.ssh/id_ed25519 ec2-user@$(terraform output -raw public_ip)
```

---

## Boas Práticas Aplicadas

- ✅ Autenticação AWS via OIDC — zero credenciais estáticas
- ✅ Camada `foundation/` isolada — OIDC e IAM Role protegidos de destroy acidental
- ✅ IAM desacoplado — módulos dedicados `aws-iam-ec2` e `aws-iam-oidc-github`
- ✅ Princípio do menor privilégio — EC2 (ECRReadOnly) vs GitHub Actions (ECRPowerUser)
- ✅ Chave SSH injetada via secret — sem `file()` nem ficheiro temporário no runner
- ✅ Scan de segurança IaC com Checkov em todos os pipelines
- ✅ IMDSv2 obrigatório e hop limit = 1 em todas as instâncias
- ✅ EBS encriptado em todas as instâncias
- ✅ S3 Public Access Block em todos os buckets
- ✅ State remoto seguro (`S3 + use_lockfile = true`)
- ✅ Estrutura modular com outputs em todos os módulos
- ✅ Ambientes isolados por pasta (`dev`, `staging`, `prod`)
- ✅ Variáveis sensíveis nunca versionadas (`.gitignore` + GitHub Secrets)
- ✅ Apply condicional — não aplica planos sem alterações
- ✅ Concurrency lock e environment gate em prod
- ✅ Cleanup de ficheiros sensíveis com `if: always()`
- ✅ `terraform fmt -check` e `validate` em todos os pipelines

---

## Possíveis Melhorias

- Módulo de VPC dedicado para isolamento de rede por ambiente
- `versions.tf` com versões fixas do Terraform e providers por ambiente
- Testes de infraestrutura com Terratest ou tflint
- Terragrunt para eliminar duplicação de `providers.tf` e `variables.tf` entre ambientes
- Auto Scaling Group e Load Balancer
- Notificações de deploy (Slack, email)
- Módulo `aws-iam-oidc-github` com suporte a múltiplos repositórios
- Workflow dedicado para a camada `foundation/` com `workflow_dispatch` protegido

---

## Autor

**Fabricio Peloso**  
Cloud Computing · DevOps · Infrastructure as Code

[![GitHub](https://img.shields.io/badge/GitHub-fabricio--f5-181717?logo=github)](https://github.com/fabricio-f5)
