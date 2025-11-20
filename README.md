# 🔐 Monitoring Security Evolution - Level 5

![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.34-326CE5?logo=kubernetes)
![Vault](https://img.shields.io/badge/Vault-Dev%20Mode-000000?logo=vault)
![Zabbix](https://img.shields.io/badge/Zabbix-7.0-D40000?logo=zabbix)
![Prometheus](https://img.shields.io/badge/Prometheus-Latest-E6522C?logo=prometheus)
![Grafana](https://img.shields.io/badge/Grafana-Latest-F46800?logo=grafana)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

**Stack completa de monitoramento em Kubernetes** com HashiCorp Vault e External Secrets Operator para gerenciamento automático de credenciais.

> 🎯 **Posição na Série:** Este é o **Level 5 (FINAL)** de 5 na evolução de segurança  
> 🏆 **Conquista Máxima:** Consumo direto do Vault via External Secrets Operator - **ZERO arquivos .env**!

---

## 🎯 **Evolução da Série (5 Níveis COMPLETOS)**

<table>
<thead>
<tr>
<th style="min-width: 100px;">Nível</th>
<th>Foco</th>
<th>Secrets Storage</th>
<th>Onde Containers Leem</th>
<th>Orquestração</th>
<th>Status</th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>Level&nbsp;1</strong></td>
<td>Baseline</td>
<td>Hardcoded</td>
<td>Código fonte</td>
<td>Docker Compose</td>
<td>✅</td>
</tr>
<tr>
<td><strong>Level&nbsp;2</strong></td>
<td>Env Vars</td>
<td><code>.env</code> files</td>
<td><code>.env</code></td>
<td>Docker Compose</td>
<td>✅</td>
</tr>
<tr>
<td><strong>Level&nbsp;3</strong></td>
<td>Vault Foundation</td>
<td>Vault + <code>.env</code></td>
<td><code>.env</code></td>
<td>Docker Compose</td>
<td>✅</td>
</tr>
<tr>
<td><strong>Level&nbsp;4</strong></td>
<td>AWS Cloud</td>
<td>AWS Secrets Manager</td>
<td>AWS API</td>
<td>Terraform + EC2</td>
<td>✅</td>
</tr>
<tr>
<td><strong>Level&nbsp;5</strong></td>
<td><strong>K8s + Vault</strong></td>
<td><strong>Vault (KV v2)</strong></td>
<td><strong>Kubernetes Secrets</strong></td>
<td><strong>Kubernetes</strong></td>
<td><strong>✅ VOCÊ ESTÁ AQUI</strong></td>
</tr>
</tbody>
</table>

**Level 5 = Vault REAL**  
**ZERO `.env` files • Consumo direto via External Secrets Operator • Automação completa**

---

## 🚀 **Evolução vs Level 3 e Level 4**

### **Comparativo Completo:**

| Aspecto | Level 3 (Vault) | Level 4 (AWS) | Level 5 (K8s + Vault) |
|---------|-----------------|---------------|----------------------|
| **Ambiente** | Local/On-Premise | AWS Cloud | **Kubernetes (any)** |
| **Secrets Manager** | HashiCorp Vault | AWS Secrets Manager | **HashiCorp Vault** |
| **Integração** | Manual (`.env`) | AWS SDK | **External Secrets Operator** ✅ |
| **Consumo Secrets** | ❌ Indiretamente (`.env`) | Via AWS CLI/SDK | **✅ Direto (K8s Secrets)** |
| **Arquivo `.env`** | ✅ Necessário | ❌ Não usa | **❌ ZERO `.env`** ✅ |
| **Sincronização** | ❌ Manual | Partial (scripts) | **✅ Automática (ESO)** |
| **Orquestração** | Docker Compose | Terraform + EC2 | **Kubernetes** ✅ |
| **Escalabilidade** | Limitada | Média | **Alta (K8s native)** ✅ |
| **Rotação Automática** | ❌ Manual | Opcional (AWS) | **✅ Automática (refresh 1h)** |
| **Cloud Lock-in** | Não | Sim (AWS) | **Não (multi-cloud)** ✅ |
| **Deploy** | `docker-compose up` | Terraform + SSH | **`./setup.sh`** ✅ |
| **Complexidade** | Baixa | Média-Alta | **Média** |
| **Custo** | $0 (self-hosted) | ~$35/mês | **$0 (self-hosted)** ✅ |

### 💡 **Por que Level 5 é DEFINITIVO?**

**O que Level 3 NÃO conseguia:**
- ❌ Containers ainda liam senhas do `.env` (Docker Compose limitation)
- ❌ Sem sincronização automática (restart necessário)
- ❌ Sem injeção dinâmica de secrets

**O que Level 5 RESOLVE:**
- ✅ **ZERO `.env` files** - Vault é a ÚNICA fonte de verdade
- ✅ **External Secrets Operator** - Sincroniza Vault → Kubernetes Secrets automaticamente
- ✅ **Refresh automático** - Secrets atualizados a cada 1 hora (configurável)
- ✅ **Kubernetes-native** - Pods consomem secrets como qualquer outro K8s Secret
- ✅ **Multi-cloud ready** - Roda em qualquer Kubernetes (AWS EKS, GCP GKE, Azure AKS, on-premise)
- ✅ **Production-ready** - Base sólida para ambientes corporativos

---

## 📋 **O que você ganha no Level 5?**

### ✅ **Funcionalidades EXCLUSIVAS do Level 5:**

- 🎯 **Consumo Direto do Vault** - Pods leem secrets via External Secrets Operator
- 🔄 **Sincronização Automática** - ESO mantém Kubernetes Secrets atualizados com Vault
- 🚫 **ZERO `.env` Files** - Eliminação completa de arquivos de ambiente
- ☸️ **Kubernetes-native** - Arquitetura cloud-native de verdade
- 🔐 **Vault KV v2** - Secrets versionados com auditoria completa
- 🤖 **Automação Completa** - Deploy end-to-end em 15-20 minutos
- 🛡️ **ServiceAccounts** - RBAC e least privilege configurados
- 📊 **Auto-recovery** - Detecta e corrige problemas automaticamente (volumes corrompidos, sync errors)

### ✅ **Herda do Level 3:**

- 🏦 **HashiCorp Vault** - Servidor Vault configurado e integrado
- 🔐 **Secrets Criptografados** - AES-256 no armazenamento
- 📊 **Auditoria Habilitada** - Log de todos os acessos aos secrets
- 🔄 **Versionamento de Secrets** - Histórico completo de alterações
- 🛡️ **Políticas de Acesso** - Segregação por serviço

### ✅ **Herda dos Levels 1 & 2:**

- 📊 **Stack Completa** - Zabbix 7.0 + Grafana + Prometheus
- 🖥️ **Monitoramento Sistema** - CPU, RAM, Disk, Network via Node Exporter
- 🗄️ **Monitoramento MySQL** - Performance e métricas avançadas
- 📈 **Dashboards Prontos** - 2 dashboards funcionais (Node Exporter + Zabbix Overview)
- ⚙️ **Configuração Automática** - Templates Zabbix e datasources Grafana configurados

---

## 🏗️ **Arquitetura**

```
┌─────────────────────────────────────────────────────────────┐
│                  Kubernetes Cluster (Kind)                  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │            External Secrets Operator                  │ │
│  │              (Namespace: external-secrets-system)     │ │
│  │                                                       │ │
│  │  ┌─────────────────────────────────────────────┐    │ │
│  │  │  Controller: Monitora ExternalSecrets       │    │ │
│  │  │  Webhook: Valida manifests                  │    │ │
│  │  │  Cert-Controller: Gerencia certificados     │    │ │
│  │  └─────────────────────────────────────────────┘    │ │
│  └───────────────────────────────────────────────────────┘ │
│                           │                                 │
│  ┌────────────────────────▼──────────────────────────────┐ │
│  │              Namespace: monitoring                    │ │
│  │                                                       │ │
│  │  ┌──────────┐        ┌─────────────────┐            │ │
│  │  │  Vault   │◄───────┤  SecretStore    │            │ │
│  │  │ (KV v2)  │        │ (vault-backend) │            │ │
│  │  └─────┬────┘        └────────┬────────┘            │ │
│  │        │                      │                      │ │
│  │        │   ┌──────────────────▼──────────────┐      │ │
│  │        │   │   4x ExternalSecrets:           │      │ │
│  │        │   │   • mysql-secret                │      │ │
│  │        │   │   • zabbix-secret               │      │ │
│  │        │   │   • grafana-secret              │      │ │
│  │        │   │   • prometheus-secret           │      │ │
│  │        │   └──────────────────┬──────────────┘      │ │
│  │        │                      │                      │ │
│  │        │             ┌────────▼──────────┐           │ │
│  │        │             │ Kubernetes Secrets│           │ │
│  │        │             │ (Auto-sync 1h)    │           │ │
│  │        │             └────────┬──────────┘           │ │
│  │        │                      │                      │ │
│  │  ┌─────▼──────┐    ┌──────────▼───────────┐         │ │
│  │  │ MySQL 8.3  │◄───┤  Zabbix Server       │         │ │
│  │  │            │    │  + Web + Agent2      │         │ │
│  │  └────────────┘    └──────────────────────┘         │ │
│  │                                                      │ │
│  │  ┌─────────────┐   ┌──────────────┐   ┌─────────┐  │ │
│  │  │ Prometheus  │◄──┤ Node Exporter│──►│ Grafana │  │ │
│  │  └─────────────┘   └──────────────┘   └─────────┘  │ │
│  │                                                      │ │
│  │  🌐 NodePorts:                                      │ │
│  │  • Grafana: 30300 • Zabbix: 30080 • Prometheus:30900│ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### **Fluxo de Secrets:**

1. **Vault** armazena secrets no KV v2 engine
2. **vault-init Job** cria secrets iniciais no Vault
3. **SecretStore** configura conexão Vault ↔ ESO
4. **ExternalSecrets** definem quais secrets sincronizar
5. **ESO Controller** lê do Vault e cria Kubernetes Secrets
6. **Pods** consomem secrets como volumes ou env vars
7. **Auto-refresh** a cada 1 hora (configurável)

---

## 🚀 **Quick Start (2 comandos)**

### **Pré-requisitos:**

- **Docker** - Rodando e acessível
- **kind** v0.30.0+
- **kubectl** v1.28+
- **helm** v3.0+
- **Recursos Mínimos**: 4GB RAM, 2 CPU cores, 10GB disk

### **Instalação Completa:**

```bash
# 1. Clone o repositório
git clone https://github.com/jlui70/monitoring-security-level5.git
cd monitoring-security-level5

# 2. Validar ambiente (IMPORTANTE!)
./scripts/check-environment.sh

# 3. Deploy completo (15-20 minutos)
./setup.sh
```

**Pronto!** O script faz tudo automaticamente:
- ✅ Cria cluster Kind
- ✅ Instala External Secrets Operator via Helm
- ✅ Deploy Vault + inicialização de secrets
- ✅ Configura SecretStore e ExternalSecrets
- ✅ **Reinicia ESO** (fix crítico para sync funcionar)
- ✅ Deploy MySQL + Zabbix + Prometheus + Grafana
- ✅ Configura templates Zabbix e dashboards Grafana

---

## 🌐 **Acessar Aplicações**

### **URLs de Acesso:**

| Aplicação | URL | Usuário Padrão |
|-----------|-----|----------------|
| **Grafana** | http://localhost:30300 | admin |
| **Zabbix** | http://localhost:30080 | Admin |
| **Prometheus** | http://localhost:30900 | - |

### **Ver Credenciais:**

```bash
# Exibir todas as credenciais
./scripts/show-credentials.sh

# Ou individualmente:

# Senha do Grafana
kubectl get secret grafana-secret -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d && echo

# Senha do Zabbix
kubectl get secret zabbix-secret -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d && echo
```

---

## 📁 **Estrutura do Projeto**

```
monitoring-security-level5/
├── README.md                    # Este arquivo
├── setup.sh                     # Script principal de deploy
├── kind-config.yaml            # Configuração do cluster Kind
│
├── scripts/                     # Scripts de automação
│   ├── cleanup.sh              # Limpeza completa
│   ├── deploy.sh               # Deploy da infraestrutura
│   ├── check-environment.sh    # Validação de pré-requisitos
│   ├── configure-zabbix.sh     # Configuração do Zabbix
│   ├── configure-grafana.sh    # Configuração do Grafana
│   └── show-credentials.sh     # Exibir credenciais
│
├── kubernetes/                  # Manifestos Kubernetes (ordem numérica)
│   ├── 01-namespace/           # Namespace monitoring
│   ├── 02-vault/               # Vault StatefulSet + vault-init Job
│   ├── 03-external-secrets/    # SecretStore + 4x ExternalSecrets
│   ├── 04-storage/             # StorageClass para Kind
│   ├── 05-mysql/               # MySQL 8.3 + schema init Job
│   ├── 06-zabbix/              # Zabbix server, web, agent2 + password Job
│   ├── 07-prometheus/          # Prometheus + RBAC
│   ├── 08-grafana/             # Grafana + datasources ConfigMap
│   └── 09-node-exporter/       # Node Exporter DaemonSet
│
├── grafana/                     # Assets do Grafana
│   └── dashboards/             # Dashboards JSON
│
└── docs/                        # Documentação
    ├── guides/                  # Guias de uso
    ├── troubleshooting/         # Solução de problemas
    └── INDEX.md                 # Índice da documentação
```

---

## 🔐 **Gerenciamento de Secrets**

### **Estrutura no Vault:**

```
secret/ (KV v2)
├── mysql
│   ├── root-password      = K8s_MySQL__Vault2024!@
│   └── database           = zabbix
├── zabbix
│   ├── admin-password     = ComplexP@ssw0rd__L5!@
│   ├── db-password        = (mesmo do MySQL zabbix)
│   ├── db-user            = zabbix
│   ├── db-name            = zabbix
│   └── server-host        = zabbix-server
├── grafana
│   ├── admin-password     = K8s_Grafana__Vault2024!@
│   └── admin-user         = admin
└── prometheus
    └── retention-time     = 15d
```

### **Comandos Úteis:**

```bash
# Listar todos os secrets do Vault
kubectl exec vault-0 -n monitoring -- sh -c '
  export VAULT_TOKEN=vault-dev-root-token
  vault kv list secret/
'

# Ver secret específico
kubectl exec vault-0 -n monitoring -- sh -c '
  export VAULT_TOKEN=vault-dev-root-token
  vault kv get secret/mysql
'

# Verificar sincronização dos ExternalSecrets
kubectl get externalsecrets -n monitoring

# Deve mostrar:
# NAME                STORE           STATUS         READY
# grafana-secret      vault-backend   SecretSynced   True
# mysql-secret        vault-backend   SecretSynced   True
# prometheus-secret   vault-backend   SecretSynced   True
# zabbix-secret       vault-backend   SecretSynced   True

# Ver Kubernetes Secrets criados automaticamente
kubectl get secrets -n monitoring | grep -E 'mysql-secret|zabbix-secret|grafana-secret|prometheus-secret'
```

---

## 🛠️ **Troubleshooting**

### **ExternalSecrets não sincronizam (SecretSyncedError):**

**Causa**: ESO não reconheceu o `vault-token` secret (cache issue)

**Solução automática**: O `deploy.sh` já faz isso, mas se necessário:

```bash
# Reiniciar ESO para limpar cache
kubectl rollout restart deployment/external-secrets -n external-secrets-system

# Aguardar 30 segundos
sleep 30

# Verificar sync
kubectl get externalsecrets -n monitoring
```

### **MySQL em CrashLoopBackOff:**

**Causa**: Volume corrompido de deploy anterior

**Solução automática**: O `deploy.sh` detecta e corrige automaticamente

**Solução manual**:

```bash
# Deletar StatefulSet e PVC
kubectl delete statefulset mysql -n monitoring
kubectl delete pvc mysql-data-mysql-0 -n monitoring

# Recriar
kubectl apply -f kubernetes/05-mysql/mysql-statefulset.yaml
```

### **Reset Completo:**

```bash
# Limpar tudo
./scripts/cleanup.sh

# Reinstalar
./setup.sh
```

Mais detalhes em [docs/troubleshooting/](docs/troubleshooting/)

---

## 📊 **Validação**

```bash
# 1. Todos os pods Running/Completed?
kubectl get pods -n monitoring

# Esperado: 10-11 pods (vault, mysql, zabbix x3, prometheus, grafana, node-exporter)

# 2. ExternalSecrets sincronizados?
kubectl get externalsecrets -n monitoring

# Esperado: 4/4 com STATUS=SecretSynced, READY=True

# 3. Web UIs acessíveis?
curl -s http://localhost:30300 > /dev/null && echo "✅ Grafana OK"
curl -s http://localhost:30080 > /dev/null && echo "✅ Zabbix OK"
curl -s http://localhost:30900 > /dev/null && echo "✅ Prometheus OK"
```

---

## ⚠️ **Notas Importantes**

### **Segurança (Modo Desenvolvimento):**

- ⚠️ **Vault em dev mode** - NÃO usar em produção
- ⚠️ **Root token fixo** - `vault-dev-root-token` (apenas para labs)
- ⚠️ **Sem TLS** - Comunicação não criptografada
- ⚠️ **Sem HA** - Instância única de cada componente

### **Para Produção você PRECISA:**

1. Vault em modo produção com unsealing adequado
2. TLS/SSL habilitado em todos os serviços
3. Autenticação robusta (OIDC, LDAP, etc.)
4. Estratégia de backup e disaster recovery
5. Alta disponibilidade (múltiplas réplicas)
6. Certificados reais (Let's Encrypt, CA interna)
7. Network Policies configuradas
8. Resource limits e quotas

---

## 🔗 **Série Monitoring Security (COMPLETA)**

- **[Level 1](https://github.com/jlui70/monitoring-security-level1)** - Baseline (hardcoded secrets)
- **[Level 2](https://github.com/jlui70/monitoring-security-level2)** - Env vars (`.env` files)
- **[Level 3](https://github.com/jlui70/monitoring-security-level3)** - Vault Foundation (Vault + `.env`)
- **[Level 4](https://github.com/jlui70/monitoring-security-level4-aws-v2)** - AWS Cloud (AWS Secrets Manager)
- **[Level 5](https://github.com/jlui70/monitoring-security-level5)** - **K8s + Vault (Consumo direto)** ⬅️ **VOCÊ ESTÁ AQUI**

---

## 🤝 **Contribuindo**

Contribuições são bem-vindas! Veja [CONTRIBUTING.md](CONTRIBUTING.md) para detalhes.

---

## 📝 **Licença**

Este projeto está licenciado sob a MIT License - veja [LICENSE](LICENSE) para detalhes.

---

## 🙏 **Agradecimentos**

- **HashiCorp Vault** - Secret management
- **External Secrets Operator** - Integração Kubernetes
- **Zabbix** - Plataforma de monitoramento
- **Prometheus** - Coleta de métricas
- **Grafana** - Visualização
- **Kind** - Kubernetes in Docker

---

**⭐ Se este projeto ajudou você, dê uma estrela!**

Construído com ❤️ para a comunidade DevOps Brasil
