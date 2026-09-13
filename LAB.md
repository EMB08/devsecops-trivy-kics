# LAB — DevSecOps com Trivy e KICS

## 1. Objetivo

Este laboratório demonstra a aplicação de ferramentas de segurança em uma pipeline DevSecOps, utilizando:

- **Trivy** — análise de vulnerabilidades em imagem de container.
- **KICS** — análise de segurança de Infrastructure as Code (IaC).

O laboratório utiliza dois cenários:

1. **Cenário vulnerável:** Juice Shop e TerraGoat, utilizados para demonstrar findings que fazem o security gate falhar.
2. **Cenário seguro:** uma imagem Docker e um fixture Terraform preparados para demonstrar uma execução sem findings HIGH ou CRITICAL.

A pipeline possui jobs independentes para Trivy e KICS e utiliza HIGH/CRITICAL como critérios de bloqueio.

---

## 2. Pré-requisitos

Antes de iniciar, é necessário possuir:

- Docker >= 24
- Docker Compose v2
- Git
- GitHub com acesso ao repositório do laboratório
- Aproximadamente 4 GB de RAM disponíveis
- Aproximadamente 3 GB de espaço livre em disco

### Verificar Docker

```bash
docker --version
```

**Resultado esperado:** a versão apresentada deve ser igual ou superior à versão 24.

Exemplo:

```text
Docker version 28.5.2
```

### Verificar Docker Compose

```bash
docker compose version
```

**Resultado esperado:** o comando deve retornar uma versão do Docker Compose v2.

---

## 3. Obter o laboratório

Clone o repositório:

```bash
git clone https://github.com/EMB08/devsecops-trivy-kics.git
```

Entre no diretório:

```bash
cd devsecops-trivy-kics
```

**Resultado esperado:** o diretório deve conter, entre outros:

```text
docker-compose.yml
terragoat/
secure-fixture/
reports/
.github/workflows/
```

---

## 4. Baixar as imagens utilizadas

Execute:

```bash
docker compose pull
```

Para baixar também as imagens utilizadas pelos scanners:

```bash
docker compose --profile tools pull
```

**Resultado esperado:** as imagens utilizadas pelo laboratório devem ser baixadas ou identificadas como já existentes:

```text
bkimminich/juice-shop:latest
aquasec/trivy:latest
checkmarx/kics:latest
```

---

## 5. Verificar a configuração do ambiente

Execute:

```bash
docker compose config
```

**Resultado esperado:** o Docker Compose deve validar o arquivo `docker-compose.yml` sem apresentar erros de sintaxe.

Para visualizar também os serviços relacionados aos scanners:

```bash
docker compose --profile tools config
```

**Resultado esperado:** devem ser apresentados os serviços:

- `juice-shop`
- `trivy`
- `kics`

---

# 6. Iniciar o alvo vulnerável

O Juice Shop é utilizado como alvo vulnerável para a demonstração do Trivy.

Inicie o ambiente:

```bash
docker compose up -d
```

Verifique os containers:

```bash
docker compose ps
```

**Resultado esperado:** o serviço `juice-shop` deve aparecer em execução e disponibilizar a porta `3000`.

A aplicação pode ser acessada localmente em:

```text
http://localhost:3000
```

> O alvo utilizado neste laboratório é executado localmente. Não realizar varreduras contra sistemas de terceiros ou aplicações sem autorização.

---

# 7. Execução do Trivy

## 7.1 Objetivo

O Trivy será utilizado para analisar a imagem Docker do Juice Shop em busca de vulnerabilidades de severidade HIGH e CRITICAL.

Execute:

```bash
docker compose --profile tools run --rm trivy \
  image \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  bkimminich/juice-shop:latest
```

**Resultado esperado:** o Trivy deve identificar vulnerabilidades HIGH e/ou CRITICAL.

Como o comando utiliza:

```text
--exit-code 1
```

o processo deve terminar com código de saída `1` quando forem encontradas vulnerabilidades dentro das severidades configuradas.

Isso representa uma condição de falha do security gate.

---

## 7.2 Gerar relatório JSON do Trivy

Execute:

```bash
docker compose --profile tools run --rm trivy \
  image \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  --format json \
  --output /reports/trivy-juice-shop.json \
  bkimminich/juice-shop:latest
```

**Resultado esperado:** o arquivo deve ser criado em:

```text
reports/trivy-juice-shop.json
```

Esse relatório contém os findings identificados pelo Trivy e pode ser utilizado como evidência da execução.

---

# 8. Execução do KICS

## 8.1 Objetivo

O KICS será utilizado para analisar o código Terraform do TerraGoat em busca de configurações inseguras de Infrastructure as Code.

O diretório analisado é:

```text
terragoat/terraform/aws
```

Execute:

```bash
docker compose --profile tools run --rm kics \
  scan \
  -p /path/terraform/aws \
  --fail-on HIGH,CRITICAL
```

**Resultado esperado:** o KICS deve identificar múltiplos findings HIGH e CRITICAL.

Durante a execução do laboratório foram identificados:

```text
CRITICAL: 1
HIGH: 43
MEDIUM: 34
LOW: 39
INFO: 38
TOTAL: 155
```

Como o comando utiliza:

```text
--fail-on HIGH,CRITICAL
```

a execução deve retornar código de saída diferente de zero quando houver findings HIGH ou CRITICAL.

Isso representa uma condição de falha do security gate.

---

## 8.2 Gerar relatório JSON do KICS

Execute:

```bash
docker compose --profile tools run --rm kics \
  scan \
  -p /path/terraform/aws \
  --report-formats json \
  --output-path /reports
```

**Resultado esperado:** um relatório JSON deve ser produzido no diretório:

```text
reports/
```

O relatório pode ser utilizado como evidência dos findings encontrados pelo KICS.

---

# 9. Interpretação dos resultados

O laboratório utiliza o seguinte security gate:

| Severidade | Resultado |
|---|---|
| CRITICAL | Falha |
| HIGH | Falha |
| MEDIUM | Não bloqueia |
| LOW | Não bloqueia |
| INFO | Não bloqueia |

Portanto:

- Trivy encontra HIGH/CRITICAL → pipeline falha.
- KICS encontra HIGH/CRITICAL → pipeline falha.
- Findings abaixo de HIGH não são suficientes para bloquear o pipeline.

---

# 10. Análise dos findings

## Finding 1 — RDS DB Instance Publicly Accessible

| Campo | Análise |
|---|---|
| **Ferramenta** | KICS |
| **Achado** | RDS DB Instance Publicly Accessible |
| **Severidade** | CRITICAL |
| **Classificação** | Verdadeiro positivo |
| **Recurso** | `aws_db_instance.db1` |
| **Arquivo** | `terraform/aws/db-app.tf` |
| **Linha** | 22 |
| **Evidência** | `publicly_accessible = true` |
| **CWE** | CWE-668 — Exposure of Resource to Wrong Sphere |
| **Risk Score** | 8.7 |

### Justificativa técnica

O finding é classificado como **verdadeiro positivo** porque a configuração identificada pelo KICS está explicitamente presente no código Terraform analisado.

A instância RDS está configurada com:

```hcl
publicly_accessible = true
```

Essa configuração aumenta sua exposição e superfície potencial de ataque.

O finding também demonstra uma vantagem da análise de IaC: uma configuração insegura pode ser identificada antes do provisionamento da infraestrutura.

### Correção proposta

Alterar:

```hcl
publicly_accessible = true
```

para:

```hcl
publicly_accessible = false
```

ou remover a configuração para utilizar o comportamento seguro padrão, conforme a necessidade da infraestrutura.

---

## Finding 2 — Hardcoded AWS Access Key

| Campo | Análise |
|---|---|
| **Ferramenta** | KICS |
| **Achado** | Hardcoded AWS Access Key |
| **Severidade** | HIGH |
| **Classificação** | Verdadeiro positivo |
| **Recurso** | `aws_instance` |
| **Arquivo** | `terraform/aws/ec2.tf` |
| **Linha** | 9 |
| **Campo analisado** | `user_data` |
| **Evidência** | O `user_data` contém uma AWS Access Key hardcoded |
| **CWE** | CWE-798 — Use of Hard-coded Credentials |
| **Risk Score** | 8.4 |

### Justificativa técnica

O finding é classificado como **verdadeiro positivo** porque o KICS identificou explicitamente uma AWS Access Key inserida diretamente no `user_data` do recurso `aws_instance`.

Credenciais de acesso não devem ser armazenadas diretamente no código Terraform ou em scripts de inicialização, pois podem ser expostas por meio de:

- repositórios Git;
- histórico de commits;
- cópias do código;
- logs;
- artefatos;
- usuários com acesso ao código.

Essa situação é especialmente relevante em um projeto versionado.

Como o TerraGoat é propositalmente vulnerável, o achado deve ser interpretado como uma vulnerabilidade presente na configuração analisada. O finding não comprova que a chave encontrada seja uma credencial AWS real ou funcional.

### Correção proposta

Remover a credencial do código e utilizar um mecanismo apropriado de gerenciamento seguro de secrets e credenciais.

Caso uma credencial real tenha sido exposta, ela também deve ser revogada e/ou rotacionada.

---

## Finding 3 — IAM Policy Grants Full Permissions

| Campo | Análise |
|---|---|
| **Ferramenta** | KICS |
| **Achado** | IAM Policy Grants Full Permissions |
| **Severidade** | HIGH |
| **Classificação** | Verdadeiro positivo |
| **Recurso** | `aws_iam_policy_document.policy` |
| **Arquivo** | `terraform/aws/es.tf` |
| **Linha** | 30 |
| **Evidência** | `statement.actions` e `statement.resources` contêm `*` |
| **CWE** | CWE-732 — Incorrect Permission Assignment for Critical Resource |
| **Risk Score** | 8.0 |

### Justificativa técnica

O finding é classificado como **verdadeiro positivo** porque o KICS identificou concretamente o uso de curingas (`*`) tanto em `statement.actions` quanto em `statement.resources`.

Essa configuração viola o princípio do **menor privilégio (Least Privilege)**, pois concede permissões excessivamente abrangentes.

A combinação conceitual:

```text
Action: *
Resource: *
```

permite uma gama muito ampla de ações sobre recursos da AWS.

O problema não é simplesmente o uso do caractere `*`, pois existem cenários legítimos em que wildcards podem ser necessários. Neste caso, entretanto, a política não restringe as ações e os recursos ao mínimo necessário para o componente.

### Correção proposta

Restringir `actions` e `resources` aos privilégios mínimos necessários para o funcionamento do componente.

Por exemplo, conceitualmente:

```text
Action: [ações realmente necessárias]
Resource: [recursos realmente necessários]
```

Não é necessário definir uma política específica de correção neste laboratório sem conhecer todos os requisitos funcionais do componente.

---

# 11. Pipeline CI/CD

A pipeline está localizada em:

```text
.github/workflows/security-pipeline.yml
```

Ela possui quatro jobs independentes:

```text
Trivy - Vulnerable Target
KICS - Vulnerable Target
Trivy - Secure Target
KICS - Secure Target
```

A execução é realizada manualmente através do GitHub Actions.

---

## 11.1 Cenário vulnerável — Build vermelho

No GitHub:

1. Acesse a aba **Actions**.
2. Selecione **DevSecOps Security Pipeline**.
3. Selecione **Run workflow**.
4. Escolha:

```text
target: vulnerable
```

5. Execute a pipeline.

**Resultado esperado:**

Os jobs:

```text
Trivy - Vulnerable Target
KICS - Vulnerable Target
```

devem falhar de forma independente.

O motivo da falha é a identificação de findings HIGH/CRITICAL.

Essa execução demonstra o funcionamento do **security gate**.

---

## 11.2 Cenário seguro — Build verde

Execute novamente a pipeline:

1. Selecione **Run workflow**.
2. Escolha:

```text
target: secure
```

3. Execute a pipeline.

**Resultado esperado:**

Os jobs:

```text
Trivy - Secure Target
KICS - Secure Target
```

devem ser concluídos com sucesso.

No cenário seguro utilizado para o laboratório:

- Trivy não encontra vulnerabilidades HIGH/CRITICAL.
- KICS não encontra findings HIGH/CRITICAL.

Isso demonstra o comportamento esperado de um pipeline que permite a continuidade quando o security gate é aprovado.

---

# 12. Fixture seguro

Para demonstrar uma execução bem-sucedida, foi utilizado um fixture separado do alvo vulnerável.

### Docker

Arquivo:

```text
secure-fixture/Dockerfile
```

A imagem utiliza Alpine e configura um usuário não-root para a execução do container.

### Terraform

Arquivo:

```text
secure-fixture/main.tf
```

O fixture contém uma configuração Terraform simples utilizada para validar a execução do KICS sem findings HIGH ou CRITICAL.

**Resultado esperado:**

O cenário seguro deve permitir a conclusão dos jobs correspondentes sem violação do security gate.

---

# 13. Verificação do laboratório

Antes de considerar o laboratório concluído, verificar:

- [ ] Docker instalado e funcionando.
- [ ] Docker Compose funcionando.
- [ ] Repositório clonado corretamente.
- [ ] `docker-compose.yml` validado.
- [ ] Juice Shop iniciado localmente.
- [ ] Trivy executado contra o alvo vulnerável.
- [ ] KICS executado contra o TerraGoat.
- [ ] Relatórios gerados em `reports/`.
- [ ] Pipeline vulnerável apresentou falha.
- [ ] Pipeline segura apresentou sucesso.
- [ ] Três findings analisados.
- [ ] Classificação dos findings realizada.
- [ ] CWE identificado.
- [ ] Correções propostas.

---

# 14. Perguntas de verificação

### 1. Por que o pipeline deve falhar quando Trivy ou KICS encontram um finding HIGH ou CRITICAL?

Porque o security gate foi configurado para impedir a continuidade da pipeline quando são identificados problemas de severidade HIGH ou CRITICAL. Isso permite detectar e bloquear problemas relevantes antes que avancem para etapas posteriores.

### 2. Qual é a principal diferença entre Trivy e KICS neste laboratório?

O Trivy é utilizado para analisar vulnerabilidades da imagem do container do Juice Shop, enquanto o KICS é utilizado para analisar configurações de Infrastructure as Code, neste caso arquivos Terraform do TerraGoat.

---

# 15. Encerramento do ambiente

Após finalizar o laboratório, pare e remova os containers:

```bash
docker compose down
```

**Resultado esperado:** os containers criados pelo laboratório devem ser encerrados e removidos.

Para confirmar:

```bash
docker compose ps
```

O ambiente não deverá apresentar containers do laboratório em execução.

---

# 16. Observações de segurança

Este laboratório utiliza projetos propositalmente vulneráveis para fins educacionais.

Os testes devem permanecer restritos ao ambiente autorizado do laboratório.

Não executar os comandos de análise contra sistemas, aplicações, imagens ou infraestruturas de terceiros sem autorização explícita.
