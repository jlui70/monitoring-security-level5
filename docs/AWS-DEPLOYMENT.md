# ☁️ Deploy na AWS EKS - Monitoring Security Level 5

**Guia completo para deploy da stack de monitoramento em Amazon EKS**

---

## 📋 Índice

- [Pré-requisitos](#-pré-requisitos)
- [Deploy Automático](#-deploy-automático)
- [Acessar Aplicações](#-acessar-aplicações)
- [Verificação](#-verificação)
- [Cleanup](#-cleanup)
- [Diferenças vs Kind](#-diferenças-vs-kind)
- [Custos](#-custos)
- [Troubleshooting](#-troubleshooting)

---

## 🎯 Pré-requisitos

### **Ferramentas necessárias:**

```bash
# Verificar instalações
aws --version          # AWS CLI v2.0+
eksctl version         # eksctl 0.150+
kubectl version        # kubectl 1.28+
helm version           # helm 3.0+
jq --version           # jq 1.6+
```

### **Credenciais AWS configuradas:**

```bash
# Configurar AWS CLI (se ainda não configurado)
aws configure

# Verificar acesso
aws sts get-caller-identity
```

### **Permissões IAM necessárias:**

- ✅ **EKS** - Criar/deletar clusters
- ✅ **EC2** - Criar/deletar instâncias, volumes EBS, VPC
- ✅ **IAM** - Criar/deletar roles e policies
- ✅ **CloudFormation** - Gerenciar stacks

---

## 🚀 Deploy Automático

### **1. Clone o repositório:**

```bash
git clone https://github.com/jlui70/monitoring-security-level5.git
cd monitoring-security-level5
```

### **2. Execute o deploy (25-30 minutos):**

```bash
./scripts/deploy-aws.sh
```

### **O que o script faz automaticamente:**

**ETAPA 1-4: Infraestrutura AWS (~15-20 min)**
- ✅ Cria cluster EKS `monitoring-security-level5`
- ✅ Provisiona 3x nodes EC2 t3.medium
- ✅ Instala EBS CSI Driver (volumes persistentes)
- ✅ Configura Storage Class `ebs-sc` (gp3)
- ✅ Instala External Secrets Operator via Helm

**ETAPA 5-6: Deploy Aplicações (7 passos, ~8-10 min)**
- ✅ **PASSO 1/7**: Vault (StatefulSet + unseal automático)
- ✅ **PASSO 2/7**: ExternalSecrets (sincronização com Vault)
- ✅ **PASSO 3/7**: MySQL (StatefulSet + schema Zabbix ~200 tabelas)
- ✅ **PASSO 4/7**: Zabbix (Server + Web + Agent2)
- ✅ **PASSO 5/7**: Prometheus (métricas)
- ✅ **PASSO 6/7**: Grafana (dashboards)
- ✅ **PASSO 7/7**: Node Exporter (DaemonSet em todos os nodes)

**ETAPA 7-8: Configuração Automática via API**
- ✅ **ETAPA 7**: Zabbix (2 templates aplicados)
- ✅ **ETAPA 8**: Grafana (2 datasources + 2 dashboards personalizados)

**Tempo total:** ~25-30 minutos

---

## 🌐 Acessar Aplicações

### **Criar port-forwards (3 terminais):**

```bash
# Terminal 1 - Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Terminal 2 - Zabbix
kubectl port-forward -n monitoring svc/zabbix-web 8080:8080

# Terminal 3 - Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

### **URLs de Acesso:**

| Aplicação | URL | Credenciais |
|-----------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin / K8s_Grafana__Vault2024!@ |
| **Zabbix** | http://localhost:8080 | Admin / ComplexP@ssw0rd__L5!@ |
| **Prometheus** | http://localhost:9090 | - |

> 💡 **Credenciais são geradas pelo Vault e sincronizadas via External Secrets Operator**

---

## ✅ Verificação

### **Status dos recursos:**

```bash
# Nodes do cluster
kubectl get nodes

# Pods (deve ter 12 pods: 10 Running + 2 Completed)
kubectl get pods -n monitoring

# ExternalSecrets (deve ter 4 sincronizados)
kubectl get externalsecrets -n monitoring

# Volumes EBS (deve ter 2 volumes Bound)
kubectl get pvc -n monitoring

# Services
kubectl get svc -n monitoring
```

### **Verificação via Console AWS:**

1. **EKS Console**: `monitoring-security-level5` cluster Active
2. **EC2 Instances**: 3x t3.medium Running
3. **EBS Volumes**: 2 volumes (vault-data 1Gi, mysql-data 10Gi)
4. **Workloads → Pods**: 12 pods visíveis

### **Verificar aplicações:**

**Zabbix:**
- Login → Configuration → Hosts → `Zabbix server`
- ✅ Deve ter **2 templates** aplicados
- ✅ Interface Agent em modo **DNS** (zabbix-agent2-service)

**Grafana:**
- Configuration → Data Sources
- ✅ Deve ter **Prometheus** + **Zabbix**
- Dashboards
- ✅ Deve ter **Node Exporter** + **Zabbix Overview**

**Prometheus:**
- Status → Targets
- ✅ `prometheus (1/1 up)`
- ✅ `node-exporter (1/1 up)`

---

## 🗑️ Cleanup

### **Deletar todos os recursos AWS (~10 min):**

```bash
./scripts/cleanup-aws.sh
```

**O que será deletado:**
- ❌ Cluster EKS completo
- ❌ 3x nodes EC2
- ❌ Volumes EBS (vault-data, mysql-data)
- ❌ VPC, subnets, security groups
- ❌ IAM roles criados pelo eksctl
- ❌ Load Balancers (se criados)

⚠️ **IMPORTANTE**: Execute o cleanup quando terminar para **parar os custos**!

### **Verificar cleanup completo:**

```bash
# Não deve retornar nenhum cluster
eksctl get cluster --region us-east-1

# Verificar no Console AWS EKS
# Deve mostrar "No clusters"
```

---

## 🔄 Diferenças vs Kind (Local)

| Aspecto | Kind (Local) | AWS EKS |
|---------|--------------|---------|
| **Acesso** | NodePort direto (30080, 30300, 30900) | Port-forward (8080, 3000, 9090) |
| **Storage** | local-path (emulado) | EBS gp3 (real, persistente) |
| **Nodes** | 1 node (Docker container) | 3 nodes (EC2 t3.medium) |
| **Custo** | $0 (gratuito) | ~$0.30/hora (~$216/mês) |
| **Setup** | 15-20 min | 25-30 min |
| **Cleanup** | 2 min | 10 min |
| **Stack** | **Idêntica** ✅ | **Idêntica** ✅ |
| **Automação** | **Idêntica** ✅ | **Idêntica** ✅ |
| **Multi-cloud** | Não aplicável | ✅ Production-ready |

### **O que é IGUAL:**

✅ **Mesma stack**: Vault, ESO, MySQL, Zabbix, Prometheus, Grafana, Node Exporter  
✅ **Mesmos scripts**: configure-zabbix-aws.sh, configure-grafana-aws.sh  
✅ **Mesmos templates**: 2 templates Zabbix  
✅ **Mesmos dashboards**: 2 dashboards Grafana personalizados  
✅ **Mesma configuração**: ExternalSecrets, SecretStore, vault-token

### **O que é DIFERENTE:**

🔄 **Storage**: EBS gp3 vs local-path  
🔄 **Acesso**: Port-forward vs NodePort  
🔄 **Script**: deploy-aws.sh vs setup.sh  

---

## 💰 Custos

### **Breakdown de custos estimados:**

```
1. EKS Control Plane: $0.10/hora
   → $2.40/dia → $72/mês

2. EC2 Instances (3x t3.medium):
   → $0.0416/hora × 3 = $0.125/hora
   → $3/dia → $90/mês

3. EBS Volumes:
   → vault-data: 1 GB gp3 = ~$0.08/mês
   → mysql-data: 10 GB gp3 = ~$0.80/mês
   → 3x node volumes (8 GB cada) = ~$1.92/mês
   Subtotal: ~$2.80/mês

4. Data Transfer (estimado): ~$0.50/dia

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TOTAL ESTIMADO:
  • Por hora:  ~$0.30/hora
  • Por dia:   ~$7.20/dia
  • Por mês:   ~$216/mês (30 dias)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### **Calcular custo em tempo real:**

```bash
# Tempo que o cluster está ativo
HOURS=$(kubectl get nodes -o json | jq -r '.items[0].metadata.creationTimestamp' | \
  xargs -I {} date -d {} +%s | xargs -I {} echo "scale=2; ($(date +%s) - {}) / 3600" | bc)

# Custo acumulado
echo "Custo atual: \$$(echo "scale=2; $HOURS * 0.30" | bc) USD"
```

### **Cost Explorer (AWS Console):**

```
AWS Console → Cost Management → Cost Explorer
  → Filtro: Service = "Elastic Container Service for Kubernetes"
  → Time range: Last 7 Days
```

⚠️ **Lembre-se**: Execute `./scripts/cleanup-aws.sh` quando terminar!

---

## 🔧 Troubleshooting

### **Problema 1: ExternalSecrets com SecretSyncedError**

**Sintoma:**
```bash
kubectl get externalsecrets -n monitoring
# STATUS: SecretSyncedError
```

**Solução:**
```bash
# Verificar se vault-token existe
kubectl get secret vault-token -n monitoring

# Se não existir, o script deploy-aws.sh já cria automaticamente
# Se ainda tiver erro, reiniciar ESO:
kubectl delete pod -n external-secrets-system -l app.kubernetes.io/name=external-secrets
```

### **Problema 2: MySQL/Vault PVC Pending**

**Sintoma:**
```bash
kubectl get pvc -n monitoring
# STATUS: Pending
```

**Solução:**
```bash
# Verificar StorageClass
kubectl get sc

# Deve existir: ebs-sc (ebs.csi.aws.com)
# Se não existir, o EBS CSI Driver não foi instalado
# Reinstale o cluster ou execute manualmente:
eksctl create addon --name aws-ebs-csi-driver --cluster monitoring-security-level5 --region us-east-1
```

### **Problema 3: Prometheus Targets DOWN**

**Sintoma:**
- Prometheus Targets → `kubernetes-nodes (0/3 up)`

**Explicação:**
- ✅ Isso é **esperado** no AWS EKS
- ❌ `kubernetes-nodes` tenta acessar IPs privados dos nodes (192.168.x.x) - bloqueado
- ✅ `node-exporter (1/1 up)` é o correto - usa Service DNS

**Solução:** Nenhuma ação necessária. Use o target `node-exporter` via Service.

### **Problema 4: Dashboard Zabbix sem dados**

**Sintoma:**
- Grafana → Zabbix Overview → "No data"
- Erro: `Datasource XXX was not found`

**Causa:** UID do datasource Zabbix mudou entre deploys

**Solução:**
```bash
# O script configure-grafana-aws.sh já corrige isso automaticamente
# Se ainda tiver problema, reimportar dashboard:
./scripts/configure-grafana-aws.sh
```

### **Problema 5: Não consigo acessar Console EKS**

**Sintoma:**
```
Error loading resources
nodes is forbidden: User "arn:aws:iam::XXX:root" cannot list resource "nodes"
```

**Solução:**
```bash
# Adicionar permissão de acesso ao cluster
aws eks associate-access-policy \
  --cluster-name monitoring-security-level5 \
  --region us-east-1 \
  --principal-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):root \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster
```

---

## 📚 Recursos Adicionais

- 📘 [README Principal](../README.md) - Deploy local com Kind
- 📘 [Checklist AWS](../DEPLOY-AWS-CHECKLIST.md) - Verificação completa
- 📘 [Troubleshooting Geral](troubleshooting/COMMON-ISSUES.md)
- 📘 [Arquitetura](../docs/architecture.png)

---

## 🎯 Próximos Passos

Após validar na AWS, você pode:

1. ✅ Testar em **GCP GKE** ou **Azure AKS** (mesma stack, script específico)
2. ✅ Adaptar para **produção** (replica sets, backup, monitoring externo)
3. ✅ Integrar com **CI/CD** (GitOps, ArgoCD, Flux)
4. ✅ Adicionar **Service Mesh** (Istio, Linkerd)

---

**🎉 Parabéns!** Você validou o **Monitoring Security Level 5** em ambiente cloud production-ready! 🚀
