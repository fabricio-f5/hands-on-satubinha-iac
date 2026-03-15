# Hands-On Satubinha – Infraestrutura AWS com Terraform

Implementação prática de **Infraestrutura como Código (IaC)** utilizando **Terraform** para provisionar recursos na AWS de forma modular, segura e reutilizável, com pipeline CI/CD completo via GitHub Actions.

A infraestrutura criada inclui:

- Instância **EC2** com IMDSv2 e EBS encriptado
- **Security Group** com regras de ingress/egress explícitas
- **SSH Key Pair**
- Armazenamento de **state remoto em S3** com lockfile nativo
- **IAM Role** para acesso ao ECR
- Ambientes separados: **dev**, **staging**, **prod**

---

## Tecnologias Utilizadas

- Terraform
- AWS EC2, S3, IAM, Security Groups, Key Pair
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
│   ├── aws-ec2-instance/
│   │   ├── main.tf
│   │   ├── iam.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── aws-keypair/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── aws-s3-instance/
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

### Inputs disponíveis em cada workflow

```
apply          → Executar terraform apply? (default: false em staging/prod)
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

### Scan de segurança IaC (Checkov)

Cada pipeline executa o **Checkov** automaticamente antes do `terraform plan`, com o relatório guardado como artefacto do run.

Resultados do último scan: **29 passed, 9 failed (todos ignoráveis), 6 skipped (justificados)**

Skips documentados no código:
- `CKV_AWS_24` — SSH porta 22 aberto: IP dinâmico (5G) impede restrição por CIDR
- `CKV_AWS_382` — Egress total: ambiente de estudo, restrição por destino não é viável

### Hardening aplicado na infraestrutura

- **IMDSv2 obrigatório** na EC2 — bloqueia acesso ao metadata sem token (`http_tokens = required`)
- **EBS encriptado** em todas as instâncias (`root_block_device { encrypted = true }`)
- **S3 Public Access Block** ativo em todos os buckets
- **IAM Role com princípio do menor privilégio** — EC2 só tem acesso ECR readonly

---

## Separação de Ambientes por Pasta

O projeto usa **pastas separadas por ambiente** (`dev`, `staging`, `prod`) em vez de Terraform workspaces.

**Vantagens:**

1. **Isolamento total** — cada ambiente tem seu próprio backend e state
2. **Sem risco de conflito** — workspaces partilham os mesmos `.tf`, aumentando risco de erro
3. **Pipeline CI/CD direto** — cada workflow aponta para a sua pasta
4. **Auditoria clara no Git** — cada ambiente tem a sua configuração e variáveis
5. **Alinhado ao mercado** — padrão utilizado em equipas profissionais

---

## Pré-requisitos

### AWS

- Conta AWS com permissões para EC2, S3, IAM, Security Groups
- OIDC Provider configurado: `token.actions.githubusercontent.com`
- IAM Role `github-actions-terraform` com trust policy para este repositório

### GitHub Secrets necessários

| Secret | Descrição |
|---|---|
| `AWS_ROLE_ARN` | ARN da IAM Role para OIDC |
| `SSH_PUBLIC_KEY` | Chave pública SSH para acesso às instâncias |
| `PROD_PRIVATE_TFVARS` | Conteúdo do ficheiro `prod-private.tfvars` |

### GitHub Environments

- `prod` — configurar **required reviewers** para aprovação manual antes de apply/destroy

---

## Como Executar Localmente

### 1. Clonar o repositório

```bash
git clone https://github.com/fabricio-f5/hands-on-satubinha-iac.git
cd hands-on-satubinha-iac
```

### 2. Configurar credenciais AWS

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=us-east-1
```

### 3. Inicializar o Terraform para um ambiente

```bash
cd environments/dev
terraform init -reconfigure
```

> Substitua `dev` por `staging` ou `prod` conforme necessário.

### 4. Visualizar o plano de execução

```bash
terraform plan -var-file="dev.tfvars"
```

### 5. Aplicar a infraestrutura

```bash
terraform apply -var-file="dev.tfvars"
```

### 6. Conectar à instância EC2

```bash
ssh -i ~/.ssh/id_ed25519 ec2-user@$(terraform output -raw public_ip)
```

---

## Boas Práticas Aplicadas

- ✅ Autenticação AWS via OIDC — zero credenciais estáticas
- ✅ Scan de segurança IaC com Checkov em todos os pipelines
- ✅ IMDSv2 obrigatório e EBS encriptado em todas as instâncias
- ✅ S3 Public Access Block em todos os buckets
- ✅ State remoto seguro (`S3 + use_lockfile = true`)
- ✅ Estrutura modular com outputs em todos os módulos
- ✅ Ambientes isolados por pasta (`dev`, `staging`, `prod`)
- ✅ Variáveis sensíveis nunca versionadas (`.gitignore` + GitHub Secrets)
- ✅ Apply condicional — não aplica planos sem alterações
- ✅ Concurrency lock e environment gate em prod
- ✅ `terraform fmt -check` e `validate` em todos os pipelines

---

## Possíveis Melhorias

- Módulo de VPC dedicado para isolamento de rede por ambiente
- `versions.tf` com versões fixas do Terraform e providers
- Testes de infraestrutura com Terratest ou tflint
- Auto Scaling Group e Load Balancer
- Notificações de deploy (Slack, email)

---

## Autor

**Fabricio Peloso**  
Cloud Computing · DevOps · Infrastructure as Code

[![GitHub](https://img.shields.io/badge/GitHub-fabricio--f5-181717?logo=github)](https://github.com/fabricio-f5)
