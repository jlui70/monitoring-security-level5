# 🌐 Deploy com Ingress + HTTPS na AWS EKS

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [⚠️ CONFIGURAÇÃO OBRIGATÓRIA](#️-configuração-obrigatória)
3. [Pré-requisitos](#pré-requisitos)
4. [Arquitetura](#arquitetura)
5. [Deploy Automático](#deploy-automático)
6. [Configuração DNS](#configuração-dns)
7. [Verificação](#verificação)
8. [Troubleshooting](#troubleshooting)
9. [Custos](#custos)
10. [Cleanup](#cleanup)

---

## 🎯 Visão Geral

Esta é uma versão **avançada** do projeto Monitoring Security Level 5 que adiciona:

- ✅ **NGINX Ingress Controller** - Roteamento HTTP/HTTPS inteligente
- ✅ **Cert-Manager** - Certificados SSL/TLS automáticos via Let's Encrypt
- ✅ **Domínio público** - Acesso via subdomínios (grafana.seudominio.com.br)
- ✅ **HTTPS gratuito** - Certificados válidos e confiáveis
- ✅ **1 único Load Balancer** - Economia vs múltiplos LBs

### Diferenças vs versão base

| Característica | Versão Base (main) | Versão Ingress (feature/ingress-https) |
|----------------|-------------------|----------------------------------------|
| **Acesso** | Port-forward (kubectl) | Domínio público (HTTPS) |
| **Certificado** | Sem SSL | Let's Encrypt (gratuito) |
| **Load Balancers** | 0 | 1 (NLB) |
| **DNS necessário** | Não | Sim (HostGator) |
| **Custo/mês** | ~$216 | ~$330 |
| **Apresentação** | Demo local/técnica | Demo profissional |

---

## ⚠️ CONFIGURAÇÃO OBRIGATÓRIA

### 🔴 IMPORTANTE: Antes de executar o deploy

**Você DEVE editar 1 arquivo** para configurar seu próprio domínio e email:

#### Arquivo: `scripts/deploy-aws-ingress.sh`

```bash
# Abrir arquivo
nano scripts/deploy-aws-ingress.sh

# Linhas 13-14: Alterar valores
DOMAIN="SEU-DOMINIO.com.br"          # ← Substituir pelo seu domínio
EMAIL="seu-email@exemplo.com"        # ← Substituir pelo seu email
```

**Exemplo real:**
```bash
DOMAIN="devopsproject.com.br"
EMAIL="luiz7030@gmail.com"
```

### 📝 O que acontece se NÃO alterar?

| Item | Sem Alteração | Após Configurar |
|------|---------------|-----------------|
| **Domínio** | Script para e pede confirmação | Deploy continua automático |
| **Email** | Notificações Let's Encrypt vão para email errado | Você recebe avisos de renovação |
| **DNS** | Você terá que mapear o domínio `devopsproject.com.br` (não vai funcionar) | Seu domínio funciona |
| **Certificados SSL** | Não serão emitidos | Emitidos automaticamente |

### ✅ Checklist pré-deploy

Antes de executar `./scripts/deploy-aws-ingress.sh`, confirme:

- [ ] Editei `scripts/deploy-aws-ingress.sh` com MEU domínio
- [ ] Editei `scripts/deploy-aws-ingress.sh` com MEU email
- [ ] Tenho acesso ao painel DNS do meu domínio (HostGator/GoDaddy/etc)
- [ ] AWS CLI configurado (`aws configure`)
- [ ] Conta AWS com permissões para criar EKS cluster

---

## ✅ Pré-requisitos

### 1. Ferramentas instaladas

```bash
# Verificar instalação
aws --version        # AWS CLI v2.x
eksctl version       # eksctl 0.150+
kubectl version      # kubectl 1.28+
helm version         # Helm 3.x
```

### 2. Credenciais AWS configuradas

```bash
aws configure
# AWS Access Key ID: AKIA...
# AWS Secret Access Key: ...
# Default region name: us-east-1
# Default output format: json
```

### 3. Domínio registrado (HostGator)

Você precisa ter:
- ✅ Domínio registrado (ex: `devopsproject.com.br`)
- ✅ Acesso ao painel DNS do HostGator
- ✅ Capacidade de criar registros CNAME

### 4. Email válido (para Let's Encrypt)

Let's Encrypt envia notificações de renovação de certificado.

---

## 🏗️ Arquitetura

```
Internet (HTTPS)
       ↓
AWS Network Load Balancer (NLB)
       ↓
NGINX Ingress Controller
       ↓
┌──────────────────────────────────────┐
│  Routing por Host:                   │
│                                      │
│  grafana.devopsproject.com.br        │
│    → grafana:3000 (ClusterIP)        │
│                                      │
│  zabbix.devopsproject.com.br         │
│    → zabbix-web:8080 (ClusterIP)     │
│                                      │
│  prometheus.devopsproject.com.br     │
│    → prometheus:9090 (ClusterIP)     │
└──────────────────────────────────────┘
       ↓
   Aplicações (Pods)
```

### Componentes adicionais

1. **NGINX Ingress Controller**
   - Deployment: 2 réplicas
   - Service: LoadBalancer (NLB)
   - Roteamento por Host header

2. **Cert-Manager**
   - Controller + Webhook + CA Injector
   - Integração com Let's Encrypt
   - Renovação automática (60 dias)

3. **ClusterIssuers**
   - `letsencrypt-staging`: Testes (certificado não confiável)
   - `letsencrypt-prod`: Produção (certificado confiável)

4. **Services ClusterIP**
   - Substituem NodePort da versão base
   - Acessíveis apenas via Ingress

---

## 🚀 Deploy Automático

### Passo 1: Configurar domínio e email

Edite o script `scripts/deploy-aws-ingress.sh`:

```bash
# Linha 13-14: Substituir valores
DOMAIN="devopsproject.com.br"          # ← SEU DOMÍNIO
EMAIL="seu-email@exemplo.com"          # ← SEU EMAIL
```

### Passo 2: Executar deploy

```bash
cd ~/monitoring-security-level5
git checkout feature/ingress-https
./scripts/deploy-aws-ingress.sh
```

### Passo 3: Aguardar conclusão

O script executa **10 etapas** (30-40 minutos):

```
⏱️  ETAPA 1/10: Criando cluster EKS (15-20 min)
✅ Cluster criado!

⏱️  ETAPA 2/10: Instalando EBS CSI Driver...
✅ EBS CSI Driver instalado!

⏱️  ETAPA 3/10: Criando namespace e StorageClass...
✅ Namespace e StorageClass criados!

⏱️  ETAPA 4/10: Deploy Vault (dev mode)...
✅ Vault pronto!

⏱️  ETAPA 5/10: Criando vault-token para ExternalSecrets...
✅ vault-token criado!

⏱️  ETAPA 6/10: Instalando External Secrets Operator...
✅ External Secrets Operator instalado!

⏱️  ETAPA 7/10: Deploy MySQL...
✅ MySQL pronto!

⏱️  ETAPA 8/10: Deploy Zabbix + Prometheus...
✅ Zabbix e Prometheus prontos!

⏱️  ETAPA 9/10: Instalando Ingress Controller + Cert-Manager...
   9.1: NGINX Ingress Controller (2-3 min)...
   9.2: Cert-Manager...
   9.3: ClusterIssuer configurado!
   9.4: Aplicando Services ClusterIP...
   9.5: Configurando Ingress rules...
✅ Ingress Controller + Cert-Manager instalados!

⏱️  ETAPA 10/10: Deploy Grafana e configuração final...
🔧 Configurando Zabbix...
🔧 Configurando Grafana...
✅ Configuração completa!

🎉 DEPLOY COMPLETO!
```

---

## 🌐 Configuração DNS

### Passo 1: Obter endereço do Load Balancer

Ao final do deploy, o script exibe:

```
📡 Obtendo endereço do Load Balancer...
✅ Load Balancer criado:
   k8s-ingressn-ingressn-abc123-1234567890.us-east-1.elb.amazonaws.com
```

Ou execute manualmente:

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Output:
# NAME                       TYPE           EXTERNAL-IP
# ingress-nginx-controller   LoadBalancer   k8s-ingress-xxxxx.us-east-1.elb.amazonaws.com
```

### Passo 2: Acessar painel DNS do HostGator

1. Login em: https://financeiro.hostgator.com.br/
2. Menu: **Domínios** → Seu domínio → **Gerenciar DNS**

### Passo 3: Criar registros CNAME

Adicione os seguintes registros:

| Nome | Tipo | Valor (Destino) | TTL |
|------|------|-----------------|-----|
| `grafana` | CNAME | `k8s-ingress-xxxxx.us-east-1.elb.amazonaws.com` | 300 |
| `zabbix` | CNAME | `k8s-ingress-xxxxx.us-east-1.elb.amazonaws.com` | 300 |
| `prometheus` | CNAME | `k8s-ingress-xxxxx.us-east-1.elb.amazonaws.com` | 300 |
| `eks` | CNAME | `k8s-ingress-xxxxx.us-east-1.elb.amazonaws.com` | 300 |

**Exemplo visual:**

```
┌─────────────────┬───────┬──────────────────────────────────────────────┐
│ Nome do Registro│ Tipo  │ Valor                                        │
├─────────────────┼───────┼──────────────────────────────────────────────┤
│ grafana         │ CNAME │ k8s-ingress-abc123.us-east-1.elb.amazonaws..│
│ zabbix          │ CNAME │ k8s-ingress-abc123.us-east-1.elb.amazonaws..│
│ prometheus      │ CNAME │ k8s-ingress-abc123.us-east-1.elb.amazonaws..│
│ eks             │ CNAME │ k8s-ingress-abc123.us-east-1.elb.amazonaws..│
└─────────────────┴───────┴──────────────────────────────────────────────┘
```

### Passo 4: Aguardar propagação DNS (5-30 minutos)

Testar propagação:

```bash
# Método 1: dig
dig grafana.devopsproject.com.br

# Método 2: nslookup
nslookup grafana.devopsproject.com.br

# Método 3: DNS público (Google)
dig @8.8.8.8 grafana.devopsproject.com.br

# Sucesso quando retornar o endereço do Load Balancer
```

### Passo 5: Aguardar emissão de certificados (2-5 minutos)

Verificar status:

```bash
# Listar certificados
kubectl get certificate -n monitoring

# Output esperado:
# NAME                    READY   SECRET                  AGE
# monitoring-tls-cert     True    monitoring-tls-cert     3m

# Detalhes do certificado
kubectl describe certificate monitoring-tls-cert -n monitoring
```

**Status possíveis:**
- `READY: False` → Aguardando validação DNS
- `READY: True` → Certificado emitido com sucesso

---

## ✅ Verificação

### 1. Status dos Pods

```bash
kubectl get pods -n monitoring

# Esperado: 12 pods Running/Completed
# - vault-0                    1/1   Running
# - mysql-0                    1/1   Running
# - zabbix-server-xxx          1/1   Running
# - zabbix-web-xxx             1/1   Running
# - zabbix-agent2-xxx          1/1   Running
# - prometheus-xxx             1/1   Running
# - node-exporter-xxx (3x)     1/1   Running
# - grafana-xxx                1/1   Running
# - configure-zabbix-xxx       0/1   Completed
# - configure-grafana-xxx      0/1   Completed
```

### 2. Status do Ingress

```bash
kubectl get ingress -n monitoring

# Output:
# NAME                        HOSTS                           ADDRESS
# monitoring-ingress          grafana.devopsproject.com.br    k8s-ingress-xxx...
#                             zabbix.devopsproject.com.br
#                             prometheus.devopsproject.com.br
# monitoring-root-redirect    eks.devopsproject.com.br        k8s-ingress-xxx...
```

### 3. Acessar aplicações via HTTPS

```bash
# URLs de acesso
https://grafana.devopsproject.com.br
https://zabbix.devopsproject.com.br
https://prometheus.devopsproject.com.br
```

**🔐 Credenciais (geradas automaticamente pelo Vault):**

As senhas são **geradas aleatoriamente** pelo Vault durante o deploy. Para obtê-las:

```bash
# GRAFANA
Usuário: admin
Senha: (obter do Vault)

kubectl exec -n monitoring vault-0 -- vault kv get secret/grafana
# Ou diretamente do Kubernetes Secret:
kubectl get secret -n monitoring grafana-secret -o jsonpath='{.data.admin-password}' | base64 -d
echo

# ZABBIX
Usuário: Admin
Senha: (obter do Vault)

kubectl exec -n monitoring vault-0 -- vault kv get secret/zabbix
# Ou diretamente do Kubernetes Secret:
kubectl get secret -n monitoring zabbix-secret -o jsonpath='{.data.admin-password}' | base64 -d
echo
```

> 💡 **Segurança Level 5:** Senhas únicas por deployment, gerenciadas pelo Vault - nunca hardcoded!

### 4. Verificar certificado SSL no browser

1. Acesse qualquer URL HTTPS
2. Clique no cadeado 🔒
3. Verifique: "Let's Encrypt Authority X3"
4. Validade: ~90 dias

---

## 🔧 Troubleshooting

### Problema 1: DNS não resolve

**Sintoma:**
```bash
dig grafana.devopsproject.com.br
# NXDOMAIN ou sem resposta
```

**Soluções:**
```bash
# 1. Verificar registros no HostGator
# - Login no painel
# - Verificar se CNAME foi salvo

# 2. Aguardar propagação (pode demorar 30 min)
dig @8.8.8.8 grafana.devopsproject.com.br

# 3. Limpar cache DNS local
sudo systemd-resolve --flush-caches
```

---

### Problema 2: Certificado não é emitido

**Sintoma:**
```bash
kubectl get certificate -n monitoring
# READY: False
```

**Soluções:**
```bash
# 1. Verificar logs do Cert-Manager
kubectl logs -n cert-manager deploy/cert-manager

# 2. Verificar desafio HTTP-01
kubectl get challenges -n monitoring

# 3. Testar com staging primeiro
# Editar kubernetes/08-ingress/04-monitoring-ingress.yaml
# Mudar: cert-manager.io/cluster-issuer: "letsencrypt-staging"
kubectl apply -f kubernetes/08-ingress/04-monitoring-ingress.yaml

# 4. Se funcionar em staging, voltar para prod
# Mudar: cert-manager.io/cluster-issuer: "letsencrypt-prod"
kubectl delete certificate monitoring-tls-cert -n monitoring
kubectl apply -f kubernetes/08-ingress/04-monitoring-ingress.yaml
```

---

### Problema 3: 502 Bad Gateway

**Sintoma:** Acesso via browser retorna erro 502

**Soluções:**
```bash
# 1. Verificar se services estão ClusterIP
kubectl get svc -n monitoring

# Grafana, zabbix-web, prometheus devem ser ClusterIP
# Se forem NodePort, aplicar versão ClusterIP:
kubectl apply -f kubernetes/08-ingress/services-clusterip/

# 2. Verificar se pods estão Running
kubectl get pods -n monitoring

# 3. Verificar logs do Ingress
kubectl logs -n ingress-nginx deploy/ingress-nginx-controller
```

---

### Problema 4: Load Balancer sem endereço externo

**Sintoma:**
```bash
kubectl get svc -n ingress-nginx
# EXTERNAL-IP: <pending>
```

**Soluções:**
```bash
# 1. Aguardar (pode levar 3-5 minutos)
kubectl get svc -n ingress-nginx -w

# 2. Verificar logs do controller
kubectl logs -n ingress-nginx deploy/ingress-nginx-controller

# 3. Verificar quotas AWS
aws servicequotas get-service-quota \
  --service-code elasticloadbalancing \
  --quota-code L-53DA6B97
```

---

### Problema 5: Rate limit do Let's Encrypt

**Sintoma:** Certificado falha com erro "too many certificates already issued"

**Informação:**
- Produção: **50 certificados/domínio/semana**
- Staging: **30.000 certificados/domínio/semana**

**Solução:**
```bash
# 1. Usar staging temporariamente
# Editar kubernetes/08-ingress/04-monitoring-ingress.yaml
# Mudar para: letsencrypt-staging

# 2. Aguardar 1 semana para resetar limite

# 3. Considerar usar subdomínio diferente
# Ex: eks2.devopsproject.com.br
```

---

## 💰 Custos

### Breakdown detalhado (região us-east-1)

| Recurso | Quantidade | Custo/hora | Custo/dia | Custo/mês |
|---------|-----------|-----------|-----------|-----------|
| **EKS Cluster** | 1 | $0.10 | $2.40 | $73.00 |
| **EC2 t3.medium** | 3 | $0.0416 x 3 | $2.99 | $90.72 |
| **EBS gp3 (1Gi)** | 1 | $0.00014 | $0.003 | $0.10 |
| **EBS gp3 (10Gi)** | 1 | $0.0014 | $0.03 | $1.00 |
| **Network Load Balancer** | 1 | $0.0225 | $0.54 | $16.20 |
| **Data Transfer** | ~5GB/mês | - | - | $0.45 |
| **Total** | - | **$0.46** | **$11.04** | **$330** |

### Comparação vs versão base

| Item | Versão Base | Versão Ingress | Diferença |
|------|------------|---------------|-----------|
| EKS + EC2 + EBS | $216/mês | $216/mês | $0 |
| Load Balancer | $0 | $16.20/mês | **+$16.20** |
| **Total** | **$216/mês** | **$330/mês** | **+$114/mês** |

### Economia vs múltiplos Load Balancers

Se você criar LoadBalancer separado para cada aplicação:
- 3 Load Balancers x $16.20 = **$48.60/mês**
- 1 Load Balancer (Ingress) = **$16.20/mês**
- **Economia: $32.40/mês**

---

## 🧹 Cleanup

### Opção 1: Script automatizado (recomendado)

```bash
cd ~/monitoring-security-level5
./scripts/cleanup-aws-ingress.sh
```

O script remove (em ordem segura):
- ✅ Network Load Balancer (aguarda 120s para AWS processar)
- ✅ Ingress Controller (NGINX)
- ✅ Cert-Manager + certificados SSL
- ✅ Namespace monitoring (Vault, MySQL, Zabbix, Grafana, Prometheus)
- ✅ External Secrets Operator
- ✅ Cluster EKS
- ✅ Node Groups
- ✅ Volumes EBS órfãos
- ✅ IAM Roles

**Diferença vs cleanup-aws.sh padrão:**
- `cleanup-aws.sh` → Para versão **sem Ingress** (port-forward)
- `cleanup-aws-ingress.sh` → Para versão **com Ingress** (HTTPS público) ✅

### Opção 2: Limpeza manual

```bash
# 1. Deletar Ingress Controller (deleta Load Balancer automaticamente)
kubectl delete -f kubernetes/08-ingress/01-ingress-controller.yaml

# Aguardar Load Balancer ser removido (2-3 min)
sleep 180

# 2. Deletar Cert-Manager
kubectl delete -f kubernetes/08-ingress/02-cert-manager.yaml
kubectl delete namespace cert-manager

# 3. Deletar namespace ingress-nginx
kubectl delete namespace ingress-nginx

# 4. Deletar namespace monitoring
kubectl delete namespace monitoring

# 5. Deletar cluster EKS
eksctl delete cluster --name monitoring-security-level5 --region us-east-1

# 6. Verificar volumes EBS órfãos
aws ec2 describe-volumes \
  --region us-east-1 \
  --filters Name=status,Values=available \
  --query 'Volumes[*].[VolumeId,Size,CreateTime]' \
  --output table

# 7. Deletar volumes órfãos (se houver)
aws ec2 delete-volume --volume-id vol-xxxxx --region us-east-1
```

**⚠️ IMPORTANTE - Limpeza DNS:**

Após o cleanup, você pode **remover os registros CNAME** no HostGator:
- `grafana.seu-dominio.com.br`
- `zabbix.seu-dominio.com.br`
- `prometheus.seu-dominio.com.br`
- `eks.seu-dominio.com.br`

Isso evita que o DNS aponte para endereços inexistentes.

### Opção 3: Remover apenas Ingress (manter cluster)

```bash
# Voltar para versão base (port-forward)
git checkout main

# Deletar Ingress resources
kubectl delete -f kubernetes/08-ingress/

# Aplicar Services NodePort de volta
kubectl apply -f kubernetes/08-grafana/grafana-service.yaml
kubectl apply -f kubernetes/06-zabbix/zabbix-web-service.yaml
kubectl apply -f kubernetes/07-prometheus/prometheus-service.yaml

# Port-forward manual
kubectl port-forward -n monitoring svc/grafana 3000:3000
kubectl port-forward -n monitoring svc/zabbix-web 8080:8080
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

---

## 📚 Referências

- [NGINX Ingress Controller - AWS](https://kubernetes.github.io/ingress-nginx/deploy/#aws)
- [Cert-Manager Documentation](https://cert-manager.io/docs/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [HostGator - Gerenciar DNS](https://suporte.hostgator.com.br/hc/pt-br/articles/115000251854)

---

## 🎯 Resumo Executivo

Esta versão adiciona **acesso público via HTTPS** ao projeto, transformando-o em uma solução **production-ready** com:

1. ✅ **Domínio profissional** (grafana.seudominio.com.br)
2. ✅ **Certificado SSL válido** (Let's Encrypt)
3. ✅ **Renovação automática** (60 dias)
4. ✅ **Custo otimizado** (1 LB ao invés de 3)
5. ✅ **Deploy 100% automatizado** (30-40 min)

**Ideal para:**
- ✅ Apresentações profissionais
- ✅ Demos para clientes
- ✅ Validação de conceitos multi-cloud
- ✅ Portfolio técnico

**Não ideal para:**
- ❌ Produção real (Vault em dev mode)
- ❌ Orçamento limitado (+$114/mês)
- ❌ Projetos sem domínio público

---

**Criado em:** 21 de Novembro de 2025  
**Branch:** `feature/ingress-https`  
**Autor:** Monitoring Security Level 5 Project
