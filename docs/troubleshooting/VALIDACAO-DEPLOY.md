# ✅ Validação do Deploy Level 5

## 🎯 Status do Deployment ($(date '+%Y-%m-%d %H:%M:%S'))

### Pods em Execução
```
$(kubectl get pods -n monitoring)
```

### Secrets Gerenciados pelo Vault
```
$(kubectl get externalsecrets -n monitoring)
$(kubectl get secrets -n monitoring | grep -E 'mysql-secret|zabbix-secret|grafana-secret|prometheus-secret')
```

### Serviços Expostos
```
$(kubectl get svc -n monitoring)
```

## 🔗 URLs de Acesso

- **Grafana**: http://localhost:30300
  - Usuário: admin
  - Senha: (obtida do Vault via External Secrets)

- **Zabbix**: http://localhost:30080
  - Usuário: Admin
  - Senha: (obtida do Vault via External Secrets)

- **Prometheus**: http://localhost:30900

## 🔐 Comandos de Validação

### Ver senha do Grafana
```bash
kubectl get secret grafana-secret -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d && echo
```

### Ver senha do Zabbix
```bash
kubectl get secret zabbix-secret -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d && echo
```

### Testar conexão com MySQL
```bash
kubectl exec -it mysql-0 -n monitoring -- mysql -u root -p$(kubectl get secret mysql-secret -n monitoring -o jsonpath='{.data.root-password}' | base64 -d) -e "SHOW DATABASES;"
```

## 🚀 Próximos Passos

1. Aguardar 2-3 minutos para coleta de dados do Zabbix Agent
2. Acessar Grafana e verificar dashboards:
   - Node Exporter (métricas Prometheus)
   - Zabbix Overview (métricas Zabbix)
3. Verificar no Zabbix se host está com dados: Monitoring → Latest data

## 🛠️ Troubleshooting

### ExternalSecrets não sincronizando
```bash
# Ver logs do ESO
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets --tail=50

# Verificar status do SecretStore
kubectl describe secretstore vault-backend -n monitoring

# Forçar reconciliação
kubectl rollout restart deployment/external-secrets -n external-secrets-system
```

### Zabbix sem dados
```bash
# Ver logs do Zabbix Server
kubectl logs -n monitoring -l app=zabbix-server --tail=50

# Ver logs do Agent
kubectl logs -n monitoring -l app=zabbix-agent2 --tail=50

# Testar conectividade Agent → Server
kubectl exec -n monitoring -l app=zabbix-agent2 -- nc -zv zabbix-server 10051
```
