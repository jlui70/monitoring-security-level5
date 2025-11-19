# 🧪 Teste de Clean Install - Level 5

## 📋 Pré-requisitos

Verifique o ambiente antes de iniciar:
```bash
./scripts/check-environment.sh
```

Deve mostrar ✅ em todos os 12 checks.

## 🚀 Instalação Completa (1 Comando)

```bash
./setup.sh
```

Este comando irá:
1. ✅ Validar ambiente
2. ✅ Criar cluster Kind
3. ✅ Instalar External Secrets Operator via Helm
4. ✅ Deploy de Vault + inicialização de secrets
5. ✅ Criar vault-token e reiniciar ESO (FIX CRÍTICO)
6. ✅ Sincronizar 4 secrets via External Secrets
7. ✅ Deploy de MySQL + schema do Zabbix (204 tabelas)
8. ✅ Deploy de Zabbix Stack (server, web, agent2)
9. ✅ Deploy de Prometheus + Node Exporter
10. ✅ Deploy de Grafana
11. ✅ Configurar Zabbix (templates, interface DNS)
12. ✅ Configurar Grafana (datasources, dashboards)

**Tempo estimado**: 15-20 minutos

## 🔍 Monitoramento do Progresso

Em outro terminal, monitore os pods:
```bash
watch -n 2 "kubectl get pods -n monitoring"
```

Ou veja logs do deploy:
```bash
tail -f /tmp/setup.log  # Se setup.sh criar log
```

## ✅ Validação Pós-Deploy

### 1. Verificar todos os pods Running
```bash
kubectl get pods -n monitoring
```

**Esperado**:
- `mysql-0`: 1/1 Running
- `vault-0`: 1/1 Running
- `zabbix-server-*`: 1/1 Running
- `zabbix-web-*`: 1/1 Running
- `zabbix-agent2-*`: 1/1 Running
- `prometheus-*`: 1/1 Running
- `grafana-*`: 1/1 Running
- `node-exporter-*`: 1/1 Running

### 2. Verificar External Secrets sincronizados
```bash
kubectl get externalsecrets -n monitoring
```

**Esperado**: Todos com `STATUS=SecretSynced, READY=True`

### 3. Testar acessos

#### Grafana
```bash
# Ver senha
kubectl get secret grafana-secret -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d && echo

# Acessar
open http://localhost:30300  # Mac
xdg-open http://localhost:30300  # Linux
```

**Credenciais**: admin / (senha do comando acima)

#### Zabbix
```bash
# Ver senha
kubectl get secret zabbix-secret -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d && echo

# Acessar
open http://localhost:30080  # Mac
xdg-open http://localhost:30080  # Linux
```

**Credenciais**: Admin / (senha do comando acima)

#### Prometheus
```bash
open http://localhost:30900  # Mac
xdg-open http://localhost:30900  # Linux
```

Testar query: `up` (deve mostrar todos os targets)

### 4. Validar coleta de dados do Zabbix

No Zabbix:
1. Ir em **Monitoring → Hosts**
2. Clicar em "Zabbix server"
3. Ir em **Latest data**
4. Aguardar 2-3 minutos até aparecerem métricas

No Grafana:
1. Ir em **Dashboards**
2. Abrir "Zabbix Overview"
3. Verificar se há dados no gráfico

### 5. Validar métricas do Prometheus

No Grafana:
1. Ir em **Dashboards**
2. Abrir "Node Exporter"
3. Verificar CPU, memória, disco, rede

No Prometheus:
1. Testar queries:
   - `node_cpu_seconds_total`
   - `node_memory_MemAvailable_bytes`
   - `up{job="kubernetes-nodes"}`

## 🛠️ Troubleshooting

### ExternalSecrets com SecretSyncedError

**Sintoma**: `STATUS=SecretSyncedError, READY=False`

**Causa**: ESO não reconheceu o vault-token

**Solução**:
```bash
# Verificar se vault-token existe
kubectl get secret vault-token -n monitoring

# Reiniciar ESO
kubectl rollout restart deployment/external-secrets -n external-secrets-system

# Aguardar 30s
sleep 30

# Verificar sync
kubectl get externalsecrets -n monitoring
```

### Pods em CrashLoopBackOff

**MySQL**:
```bash
kubectl logs mysql-0 -n monitoring --tail=50
```
Causa comum: secret não sincronizado, PVC sem espaço

**Zabbix Server**:
```bash
kubectl logs -n monitoring -l app=zabbix-server --tail=50
```
Causa comum: MySQL não pronto, senha incorreta

**Grafana**:
```bash
kubectl logs -n monitoring -l app=grafana --tail=50
```
Causa comum: secret não sincronizado

### MySQL init job não completa

```bash
# Ver logs do job
kubectl logs -n monitoring job/mysql-init-schema

# Cancelar e recriar se necessário
kubectl delete job mysql-init-schema -n monitoring
kubectl apply -f kubernetes/05-mysql/mysql-init-job.yaml
```

### Zabbix sem dados após 5 minutos

```bash
# Verificar conectividade Agent → Server
kubectl exec -n monitoring deployment/zabbix-agent2 -- nc -zv zabbix-server 10051

# Ver logs do Agent
kubectl logs -n monitoring -l app=zabbix-agent2

# Restartar Agent
kubectl rollout restart deployment/zabbix-agent2 -n monitoring
```

## 🗑️ Limpeza Completa

Para testar clean install novamente:

```bash
./cleanup.sh
```

Ou manual:
```bash
kind delete cluster --name kind
kubectl config delete-context kind-kind 2>/dev/null || true
```

## 📊 Checklist de Sucesso

- [ ] ✅ check-environment.sh: 12/12 checks
- [ ] ✅ setup.sh executou sem erros
- [ ] ✅ 11 pods Running em `monitoring` namespace
- [ ] ✅ 4 ExternalSecrets com SecretSynced
- [ ] ✅ Grafana acessível em localhost:30300
- [ ] ✅ Zabbix acessível em localhost:30080
- [ ] ✅ Prometheus acessível em localhost:30900
- [ ] ✅ Dashboard "Node Exporter" com dados
- [ ] ✅ Dashboard "Zabbix Overview" com dados
- [ ] ✅ Zabbix Latest data mostrando métricas

## 📝 Notas de Implementação

### Problema Resolvido: ESO Cache
O External Secrets Operator não reconhecia o `vault-token` secret criado antes do deploy dos ExternalSecrets. 

**Solução implementada** em `scripts/deploy.sh`:
```bash
# Criar vault-token (idempotente)
kubectl create secret generic vault-token \
  --from-literal=token='vault-dev-root-token' \
  -n monitoring --dry-run=client -o yaml | kubectl apply -f -

# Aplicar External Secrets
kubectl apply -f kubernetes/03-external-secrets/

# FIX: Reiniciar ESO para reconhecer vault-token
kubectl rollout restart deployment/external-secrets -n external-secrets-system
kubectl rollout status deployment/external-secrets -n external-secrets-system --timeout=120s

# Aguardar sync
sleep 30
```

Antes do fix: 100% de falha no sync
Após o fix: 100% de sucesso
