# ✅ Checklist de Deployment - Level 5

## 🔍 Verificações Antes de Iniciar

- [ ] Kind instalado (`kind version`)
- [ ] Kubectl instalado (`kubectl version --client`)
- [ ] Helm instalado (`helm version`) - opcional
- [ ] Nenhum cluster existente ou aceitação de deletar o existente

## 📋 Fluxo de Deployment Automático

### 1. Executar Setup
```bash
./setup.sh
```

### 2. O que acontece automaticamente:

#### Phase 1: Infraestrutura (deploy.sh)
- ✅ Cria cluster Kind
- ✅ Instala External Secrets Operator via Helm
- ✅ Cria namespace `monitoring`
- ✅ Implanta Vault em modo dev
- ✅ Job `vault-init` gera senhas complexas e armazena no Vault
- ✅ External Secrets sincroniza 4 secrets do Vault para Kubernetes

#### Phase 2: Database
- ✅ MySQL StatefulSet inicia (SEM criar usuário zabbix automaticamente)
- ✅ Job `mysql-init-schema`:
  - Init container conecta como root
  - Cria usuário `zabbix@'%'` com permissões remotas
  - Container principal cria schema Zabbix (204 tabelas)

#### Phase 3: Monitoring Stack
- ✅ Zabbix Server deployment
- ✅ Zabbix Web deployment
- ✅ Zabbix Agent2 deployment
- ✅ Job `zabbix-change-admin-password`:
  - Aguarda Zabbix Web estar pronto
  - Faz login com senha padrão "zabbix"
  - Muda senha para senha complexa do Vault
- ✅ Prometheus deployment
- ✅ Node Exporter deployment
- ✅ Grafana deployment (com init container para plugin Zabbix)

#### Phase 4: Configuração (setup.sh)
- ✅ Aguarda todos pods estarem Running
- ✅ Executa `configure-zabbix.sh`:
  - Faz login com senha do Vault
  - Configura interface Agent para usar DNS
  - Aplica templates (Zabbix server health, Linux by Zabbix agent)
- ✅ Executa `configure-grafana.sh`:
  - Configura datasource Prometheus
  - Configura datasource Zabbix (com senha do Vault)
  - Importa 2 dashboards
- ✅ Valida deployment
- ✅ Exibe credenciais
- ✅ Salva credenciais em `credentials.txt`

## 🎯 Pods Esperados (10 total)

### Running (8 pods)
- `vault-0` - HashiCorp Vault
- `mysql-0` - MySQL 8.3
- `zabbix-server` - Zabbix Server 7.0.5
- `zabbix-web` - Zabbix Web Frontend
- `zabbix-agent2` - Zabbix Agent2
- `prometheus` - Prometheus 2.48.1
- `node-exporter` - Node Exporter 1.7.0
- `grafana` - Grafana 10.2.3

### Completed (2 jobs)
- `vault-init` - Geração de senhas
- `mysql-init-schema` - Criação do schema
- `zabbix-change-admin-password` - Mudança de senha

## 🔐 Senhas Geradas Automaticamente

### Padrões de Senha:
- **Zabbix Admin**: `ComplexP@ssw0rd_<random>_L5!@` (32 chars)
- **Grafana Admin**: `K8s_Grafana_<random>_Vault2024!@` (28+ chars)
- **MySQL Root**: `K8s_Root_<random>_Vault2024!@` (21+ chars)
- **MySQL Zabbix**: `K8s_MySQL_<random>_Vault2024!@` (26+ chars)

**Importante**: Senha do Zabbix NÃO pode conter: "Admin", "Zabbix", "Administrator"

## 🔍 Validações Pós-Deploy

### Verificar Pods
```bash
kubectl get pods -n monitoring
# Esperar: 8 Running + 2-3 Completed
```

### Verificar Secrets Sincronizados
```bash
kubectl get externalsecrets -n monitoring
# Todos devem estar: SecretSynced=True
```

### Testar Acessos
```bash
# Zabbix
curl -s http://localhost:30080 | grep -q "Zabbix" && echo "✅ OK"

# Grafana
curl -s http://localhost:30300/api/health | grep -q "ok" && echo "✅ OK"

# Prometheus
curl -s http://localhost:30900/-/ready | grep -q "ready" && echo "✅ OK"
```

### Verificar Credenciais
```bash
./scripts/show-credentials.sh
```

## ⚠️ Problemas Conhecidos e Soluções

### 1. DNS não funciona (Grafana plugin download falha)
**Sintoma**: `dial tcp: lookup grafana.com: server misbehaving`
**Solução**: Reiniciar CoreDNS
```bash
kubectl rollout restart deployment/coredns -n kube-system
```

### 2. MySQL não aceita conexões remotas
**Sintoma**: `Host '10.244.0.X' is not allowed to connect`
**Solução**: Garantir que StatefulSet NÃO tem `MYSQL_USER` e `MYSQL_PASSWORD`
**Status**: ✅ JÁ CORRIGIDO

### 3. Senha do Zabbix rejeitada pela API
**Sintoma**: `must not contain user's name, surname or username`
**Solução**: Usar senha sem "Admin", "Zabbix", "Administrator"
**Status**: ✅ JÁ CORRIGIDO (padrão `ComplexP@ssw0rd_`)

### 4. Job zabbix-change-admin-password falha
**Sintoma**: Job fica travado ou falha
**Verificar**:
```bash
kubectl logs -n monitoring $(kubectl get pods -n monitoring -l job-name=zabbix-change-admin-password -o name) -c change-password
```
**Status**: ✅ JÁ CORRIGIDO (tenta senha padrão primeiro, depois Vault)

## 📊 Métricas de Sucesso

- ✅ 10 pods Running/Completed em < 5 minutos
- ✅ 4 External Secrets sincronizados
- ✅ Login Zabbix funciona com senha do Vault
- ✅ Login Grafana funciona com senha do Vault
- ✅ 2 dashboards importados no Grafana
- ✅ Zabbix coletando > 50 itens de dados
- ✅ Datasource Zabbix no Grafana conectado

## 🧹 Limpeza

```bash
./scripts/cleanup.sh
```

## 🔄 Reinstalação Limpa

```bash
./scripts/cleanup.sh && ./setup.sh
```

---

**Última atualização**: 19/11/2025
**Status**: ✅ Pronto para deployment do zero
