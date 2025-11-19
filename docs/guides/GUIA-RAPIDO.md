# ⚡ Guia Rápido - Level 5

## 🚀 Instalação em 1 Comando
```bash
./setup.sh
```

## 🌐 Acessos
| Serviço | URL | Credenciais |
|---------|-----|-------------|
| Grafana | http://localhost:30300 | admin / (ver abaixo) |
| Zabbix | http://localhost:30080 | Admin / (ver abaixo) |
| Prometheus | http://localhost:30900 | N/A |

### Ver Senhas
```bash
# Grafana
kubectl get secret grafana-secret -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d && echo

# Zabbix  
kubectl get secret zabbix-secret -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d && echo
```

## 🔍 Status Rápido
```bash
# Todos os pods
kubectl get pods -n monitoring

# External Secrets sync
kubectl get externalsecrets -n monitoring

# Services expostos
kubectl get svc -n monitoring
```

## 🛠️ Troubleshooting

### ExternalSecrets não sincronizam
```bash
kubectl rollout restart deployment/external-secrets -n external-secrets-system
sleep 30
kubectl get externalsecrets -n monitoring
```

### Pod em CrashLoop
```bash
# Ver logs
kubectl logs -n monitoring <pod-name>

# Descrever para ver eventos
kubectl describe pod -n monitoring <pod-name>
```

### Resetar tudo
```bash
./cleanup.sh
./setup.sh
```

## 📊 Validação Completa
```bash
# 1. Todos os pods Running?
kubectl get pods -n monitoring | grep -v "Running\|Completed" && echo "❌ Pods com problema" || echo "✅ Todos OK"

# 2. External Secrets sincronizados?
kubectl get externalsecrets -n monitoring | grep -v "SecretSynced.*True" && echo "❌ Secrets não sincronizados" || echo "✅ Todos sincronizados"

# 3. Web UIs acessíveis?
curl -s http://localhost:30300 > /dev/null && echo "✅ Grafana OK" || echo "❌ Grafana falhou"
curl -s http://localhost:30080 > /dev/null && echo "✅ Zabbix OK" || echo "❌ Zabbix falhou"
curl -s http://localhost:30900 > /dev/null && echo "✅ Prometheus OK" || echo "❌ Prometheus falhou"
```

## 🎯 Arquivos Importantes
- `setup.sh` - Script principal de deploy
- `cleanup.sh` - Remove tudo
- `scripts/check-environment.sh` - Valida pré-requisitos
- `scripts/deploy.sh` - Deploy da infraestrutura
- `TESTE-CLEAN-INSTALL.md` - Guia detalhado de teste
- `RESUMO-DEPLOY-SUCESSO.md` - Documentação completa

## ⚠️ Problema Conhecido: ExternalSecrets

Se os ExternalSecrets não sincronizarem automaticamente após `./setup.sh`, o deploy.sh já inclui o fix:

**O que acontece**:
1. vault-token criado
2. External Secrets aplicados
3. **ESO reiniciado** (força reconhecimento do token)
4. Sleep 30s
5. Validação dos secrets

Se ainda assim falhar, executar manualmente:
```bash
kubectl rollout restart deployment/external-secrets -n external-secrets-system
```

## 📱 Comandos Úteis

### Port-forward para debug
```bash
# MySQL
kubectl port-forward -n monitoring svc/mysql 3306:3306

# Vault UI (não exposto por padrão)
kubectl port-forward -n monitoring svc/vault 8200:8200
```

### Exec em pods
```bash
# MySQL
kubectl exec -it mysql-0 -n monitoring -- bash

# Vault
kubectl exec -it vault-0 -n monitoring -- sh

# Zabbix Server
kubectl exec -it deployment/zabbix-server -n monitoring -- bash
```

### Ver secrets do Vault
```bash
kubectl exec -it vault-0 -n monitoring -- sh -c '
export VAULT_TOKEN=vault-dev-root-token
vault kv list secret/
vault kv get secret/mysql
vault kv get secret/zabbix
vault kv get secret/grafana
'
```

## 🔄 Workflow de Desenvolvimento

1. **Fazer alterações** nos manifestos YAML
2. **Aplicar mudanças**:
   ```bash
   kubectl apply -f kubernetes/<diretorio>/
   ```
3. **Verificar logs**:
   ```bash
   kubectl logs -n monitoring <pod> --tail=50 -f
   ```
4. **Testar localmente**
5. **Commit** se funcionar

## 🧪 Testes Automatizados

### Validação mínima
```bash
#!/bin/bash
set -e

# Check pods
[ $(kubectl get pods -n monitoring --no-headers | grep -c "Running\|Completed") -eq 11 ] || exit 1

# Check ExternalSecrets
[ $(kubectl get externalsecrets -n monitoring --no-headers | grep -c "SecretSynced.*True") -eq 4 ] || exit 1

# Check web UIs
curl -sf http://localhost:30300 > /dev/null || exit 1
curl -sf http://localhost:30080 > /dev/null || exit 1
curl -sf http://localhost:30900 > /dev/null || exit 1

echo "✅ Todos os testes passaram!"
```

Salvar como `test-deployment.sh` e executar após deploy.

---

**Tempo médio de deploy**: 15-20 minutos  
**Documentação completa**: Ver `TESTE-CLEAN-INSTALL.md`
