# DevSecOps — Trivy e KICS

Laboratório prático de segurança em pipeline DevSecOps utilizando **Trivy** e **KICS**, com ambiente reproduzível em Docker e integração com GitHub Actions.

## Objetivo

Demonstrar a aplicação de controles de segurança em diferentes etapas de uma pipeline DevSecOps:

- **Trivy** — análise de vulnerabilidades em imagem Docker.
- **KICS** — análise de segurança de Infrastructure as Code (IaC), utilizando Terraform.
- **GitHub Actions** — execução dos scanners e aplicação de um security gate.
- **Docker Compose** — reprodução do ambiente local.

O security gate considera **HIGH** e **CRITICAL** como severidades bloqueantes.

## Cenários do laboratório

O projeto possui dois cenários:

### Cenário vulnerável

Utilizado para demonstrar a identificação de vulnerabilidades e o bloqueio do security gate.

- **Trivy:** imagem `bkimminich/juice-shop:latest`
- **KICS:** Terraform do projeto TerraGoat

### Cenário seguro

Utilizado para demonstrar uma execução aprovada pelo security gate.

- **Trivy:** `secure-fixture/Dockerfile`
- **KICS:** `secure-fixture/main.tf`

## Ferramentas

| Ferramenta | Categoria | Utilização |
|---|---|---|
| Trivy | Vulnerability Scanning | Análise da imagem Docker |
| KICS | IaC Security | Análise dos arquivos Terraform |
| Docker | Containerização | Execução do ambiente |
| Docker Compose | Orquestração | Reprodução local |
| GitHub Actions | CI/CD | Execução do security gate |

## Estrutura do repositório

```text
.
├── .github/
│   └── workflows/
│       └── security-pipeline.yml
├── reports/
│   ├── results.json
│   └── trivy-juice-shop.json
├── secure-fixture/
│   ├── Dockerfile
│   └── main.tf
├── terragoat/
├── docker-compose.yml
├── LAB.md
├── README.md
└── USO-DE-IA.md
