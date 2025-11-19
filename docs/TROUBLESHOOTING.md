# 🔧 Troubleshooting Guide - Level 5

## Issues Encontrados e Soluções

### 1. External Secrets Operator - API Version

**Problema:** Manifests usavam `external-secrets.io/v1beta1` mas a versão instalada é `v1`

**Solução:**
```bash
find kubernetes/03-external-secrets -name "*.yaml" -type f -exec sed -i 's/external-secrets.io\/v1beta1/external-secrets.io\/v1/g' {} \;
```

### 2. Vault StatefulSet - Chown Error

**Problema:** Vault tentava fazer chown em ConfigMap (read-only filesystem)

**Solução:** Removido volume do ConfigMap e adicionados env vars:
```yaml
env:
- name: SKIP_CHOWN
  value: "true"
- name: SKIP_SETCAP
  value: "true"
```

### 3. SecretStore - Kubernetes Auth Failing

**Problema:** DNS lookup failure ao tentar autenticar via Kubernetes auth

**Solução:** Mudado para token auth direto:
```yaml
spec:
  provider:
    vault:
      server: "http://vault.monitoring.svc.cluster.local:8200"
      auth:
        tokenSecretRef:
          name: "vault-token"
          key: "token"
```

Criar secret:
```bash
kubectl create secret generic vault-token \
  --from-literal=token='vault-dev-root-token' \
  -n monitoring
```

### 4. MySQL Schema - Caminho Errado

**Problema:** Script procurava `/usr/share/zabbix-sql-scripts/mysql/server.sql.gz` mas arquivo está em `/usr/share/doc/zabbix-server-mysql/create.sql.gz`

**Solução:** Atualizado `mysql-init-job.yaml`:
```bash
zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql ...
```

### 5. MySQL - Binary Logging Privileges

**Problema:** `ERROR 1419: You do not have the SUPER privilege and binary logging is enabled`

**Solução:** Adicionar ConfigMap com:
```ini
[mysqld]
log_bin_trust_function_creators = 1
```

## Comandos Úteis

### Verificar Status Geral
```bash
kubectl get pods -n monitoring
kubectl get externalsecrets -n monitoring
kubectl get secretstore -n monitoring
```

### Debug Vault
```bash
kubectl logs -n monitoring vault-0
kubectl exec -it vault-0 -n monitoring -- vault status
```

### Debug External Secrets
```bash
kubectl logs -n external-secrets-system deployment/external-secrets
kubectl describe externalsecret mysql-secret -n monitoring
```

### Debug MySQL
```bash
# Contar tabelas
kubectl exec mysql-0 -n monitoring -- mysql -uzabbix -pZabb1x_DB_P@ssw0rd zabbix -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='zabbix';"

# Verificar users
kubectl exec mysql-0 -n monitoring -- mysql -uzabbix -pZabb1x_DB_P@ssw0rd zabbix -e "SELECT COUNT(*) FROM users;"

# Ver variáveis
kubectl exec mysql-0 -n monitoring -- mysql -uroot -pMyS3cur3_R00t_P@ssw0rd -e "SHOW VARIABLES LIKE 'log_bin_trust%';"
```

### Recriar Schema MySQL
```bash
# Drop e recreate
kubectl exec mysql-0 -n monitoring -- mysql -uroot -pMyS3cur3_R00t_P@ssw0rd -e "DROP DATABASE IF EXISTS zabbix; CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"

# Carregar schema
kubectl run schema-loader --image=zabbix/zabbix-server-mysql:alpine-7.0.5 --restart=Never -n monitoring --rm -it --command -- sh -c "zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -h mysql -uzabbix -pZabb1x_DB_P@ssw0rd zabbix"
```

## Recomeçar do Zero

```bash
./scripts/cleanup.sh
./scripts/deploy.sh
```

## Verificar URLs

```bash
./scripts/test-urls.sh
```

Expected output:
- Zabbix: http://localhost:30080 (Admin/zabbix)
- Grafana: http://localhost:30300 (admin/admin)
- Prometheus: http://localhost:30900
