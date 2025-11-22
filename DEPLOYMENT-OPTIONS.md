# 🚀 Guia de Deployment - 3 Opções Disponíveis

## 📌 Visão Geral

Este repositório oferece **3 formas diferentes** de deployar a stack de monitoramento. Cada opção atende diferentes necessidades e orçamentos.

---

## 🎯 Decisão Rápida

**Responda estas perguntas:**

1. Você tem conta AWS configurada?
   - ❌ **Não** → Use [Opção 1 (Kind Local)](#opção-1-kind-local)
   - ✅ **Sim** → Continue para pergunta 2

2. Você tem um domínio registrado (HostGator/GoDaddy)?
   - ❌ **Não** → Use [Opção 2 (AWS Básico)](#opção-2-aws-básico)
   - ✅ **Sim** → Use [Opção 3 (AWS + Ingress)](#opção-3-aws--ingress)

---

## 📊 Comparação Completa

| Característica | Opção 1 | Opção 2 | Opção 3 |
|----------------|---------|---------|---------|
| **Nome** | Kind Local | AWS Básico | AWS + Ingress |
| **Branch** | `main` | `main` | `feature/ingress-https` |
| **Ambiente** | Docker Desktop | AWS EKS | AWS EKS |
| **Cluster** | Kind (local) | EKS real | EKS real |
| **Acesso** | NodePort | Port-forward | HTTPS público |
| **URL Exemplo** | `localhost:30300` | `localhost:3000` | `grafana.seudominio.com.br` |
| **SSL/TLS** | ❌ Não | ❌ Não | ✅ **Let's Encrypt** |
| **Domínio** | ❌ Não precisa | ❌ Não precisa | ✅ **Necessário** |
| **Configuração** | Zero | AWS CLI | **Editar domínio + email** |
| **Load Balancer** | Não | Não | ✅ NLB |
| **Custo/hora** | $0 | ~$0.30 | ~$0.46 |
| **Custo/mês** | **$0** | ~$216 | ~$330 |
| **Tempo Deploy** | 5-10 min | 25-30 min | 30-40 min |
| **Ideal para** | Aprendizado | Validação cloud | **Demos profissionais** |

---

## 🎮 Opção 1: Kind Local

### ✅ Quando usar
- Primeiro contato com o projeto
- Aprender Kubernetes sem custos
- Desenvolvimento local
- Testes rápidos
- Não tem conta AWS

### 📦 O que você precisa
- Docker Desktop instalado
- 8GB RAM disponível
- 20GB disco livre

### 🚀 Como usar

```bash
git clone https://github.com/jlui70/monitoring-security-level5.git
cd monitoring-security-level5
./setup.sh
```

**Acessos:**
- Grafana: http://localhost:30300
- Zabbix: http://localhost:30080
- Prometheus: http://localhost:30900

### 📖 Documentação completa
- [README.md](README.md) - Seção "Opção 1"
- [docs/SETUP-LOCAL.md](docs/SETUP-LOCAL.md)

---

## ☁️ Opção 2: AWS Básico

### ✅ Quando usar
- Validar em cluster real
- Testar storage persistente (EBS)
- Não precisa de acesso público
- Quer economizar (sem Load Balancer)

### 📦 O que você precisa
- Conta AWS configurada (`aws configure`)
- Permissões para criar EKS cluster
- Budget: ~$216/mês

### 🚀 Como usar

```bash
git clone https://github.com/jlui70/monitoring-security-level5.git
cd monitoring-security-level5

# Deploy (25-30 min)
./scripts/deploy-aws.sh

# Acessar (port-forward manual)
kubectl port-forward -n monitoring svc/grafana 3000:3000
kubectl port-forward -n monitoring svc/zabbix-web 8080:8080
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

**Acessos (após port-forward):**
- Grafana: http://localhost:3000
- Zabbix: http://localhost:8080
- Prometheus: http://localhost:9090

### 🧹 Cleanup

```bash
./scripts/cleanup-aws.sh
```

### 📖 Documentação completa
- [README.md](README.md) - Seção "Opção 2"
- [docs/AWS-DEPLOYMENT.md](docs/AWS-DEPLOYMENT.md)

---

## 🌐 Opção 3: AWS + Ingress

### ✅ Quando usar
- Demonstração profissional
- Portfolio com HTTPS válido
- Apresentação para clientes
- Aprender Ingress + Cert-Manager
- Precisa de acesso público

### 📦 O que você precisa
- Conta AWS configurada
- **Domínio registrado** (HostGator, GoDaddy, etc)
- **Acesso ao painel DNS**
- Email válido (notificações Let's Encrypt)
- Budget: ~$330/mês

### 🔴 CONFIGURAÇÃO OBRIGATÓRIA

**ANTES de executar**, você DEVE editar:

```bash
nano scripts/deploy-aws-ingress.sh

# Linhas 31-32:
DOMAIN="SEU-DOMINIO.com.br"          # ← Alterar
EMAIL="seu-email@exemplo.com"        # ← Alterar
```

### 🚀 Como usar

```bash
git clone https://github.com/jlui70/monitoring-security-level5.git
cd monitoring-security-level5

# Alternar para branch Ingress
git checkout feature/ingress-https

# ⚠️ EDITAR domínio e email (OBRIGATÓRIO)
nano scripts/deploy-aws-ingress.sh

# Deploy (30-40 min)
./scripts/deploy-aws-ingress.sh
```

### 🌐 Configurar DNS

Ao final do deploy, copie o endereço do Load Balancer e crie CNAMEs:

```
Painel DNS (HostGator/GoDaddy):

grafana.seudominio.com.br    → k8s-ingress-xxxxx.elb.amazonaws.com
zabbix.seudominio.com.br     → k8s-ingress-xxxxx.elb.amazonaws.com
prometheus.seudominio.com.br → k8s-ingress-xxxxx.elb.amazonaws.com
```

Aguarde propagação DNS (5-30 min).

**Acessos (HTTPS com certificado válido):**
- https://grafana.seudominio.com.br
- https://zabbix.seudominio.com.br
- https://prometheus.seudominio.com.br

### 🧹 Cleanup

```bash
./scripts/cleanup-aws-ingress.sh
# ⚠️ Lembre de remover CNAMEs manualmente do painel DNS
```

### 📖 Documentação completa
- [README.md](README.md) - Seção "Opção 3"
- [docs/INGRESS-HTTPS-SETUP.md](docs/INGRESS-HTTPS-SETUP.md)

---

## 🔄 Migrando entre Opções

### De Local (Kind) → AWS Básico

```bash
# Limpar Kind
kind delete cluster --name monitoring-level5

# Deploy AWS
./scripts/deploy-aws.sh
```

### De AWS Básico → AWS + Ingress

```bash
# Limpar AWS Básico
./scripts/cleanup-aws.sh

# Alternar branch
git checkout feature/ingress-https

# Editar domínio
nano scripts/deploy-aws-ingress.sh

# Deploy Ingress
./scripts/deploy-aws-ingress.sh
```

### De AWS + Ingress → Local (Kind)

```bash
# Limpar AWS Ingress
./scripts/cleanup-aws-ingress.sh

# Remover CNAMEs do painel DNS (manual)

# Voltar para main
git checkout main

# Deploy Kind
./setup.sh
```

---

## 📚 Estrutura de Branches

```
main (branch padrão)
├── setup.sh                      # Deploy Kind Local
├── scripts/deploy-aws.sh         # Deploy AWS Básico
└── docs/
    ├── SETUP-LOCAL.md
    └── AWS-DEPLOYMENT.md

feature/ingress-https
├── scripts/deploy-aws-ingress.sh # Deploy AWS + Ingress
├── kubernetes/08-ingress/        # Manifests Ingress + Cert-Manager
└── docs/
    └── INGRESS-HTTPS-SETUP.md
```

---

## 🆘 Ajuda Rápida

### ❓ Qual opção devo escolher?

**Para aprender:** Opção 1 (Kind Local)  
**Para validar em cloud:** Opção 2 (AWS Básico)  
**Para demonstrar/portfolio:** Opção 3 (AWS + Ingress)

### ❓ Posso testar todas as opções?

Sim! Mas execute o cleanup antes de trocar:
- Kind: `kind delete cluster --name monitoring-level5`
- AWS Básico: `./scripts/cleanup-aws.sh`
- AWS Ingress: `./scripts/cleanup-aws-ingress.sh`

### ❓ Não tenho domínio, mas quero HTTPS

Use Opção 2 (AWS Básico) + port-forward. Para demos, mostre via localhost. Ou registre um domínio barato (~R$40/ano no Registro.br).

### ❓ Tenho domínio mas configurei errado

1. Limpe o deploy: `./scripts/cleanup-aws-ingress.sh`
2. Edite: `nano scripts/deploy-aws-ingress.sh`
3. Corrija DOMAIN e EMAIL
4. Deploy novamente: `./scripts/deploy-aws-ingress.sh`

---

## 📞 Suporte

- **Issues:** https://github.com/jlui70/monitoring-security-level5/issues
- **Discussões:** https://github.com/jlui70/monitoring-security-level5/discussions
- **Documentação:** Veja pasta `docs/`

---

**Criado por:** Luiz Silva  
**Licença:** MIT  
**Série:** Monitoring Security Evolution (Level 5 de 5)
