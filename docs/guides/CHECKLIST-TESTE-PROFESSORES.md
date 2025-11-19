# 🧪 Checklist de Teste - Level 5 (Para Professores)

## 🎯 Objetivo
Validar instalação **100% automatizada** do Monitoring Stack Level 5 com segurança enterprise-grade.

---

## ✅ Pré-requisitos (já devem estar instalados)

```bash
kind version      # v0.20+
kubectl version   # 1.27+
helm version      # 3.0+
docker --version  # 24+
```

---

## 🚀 Teste Completo (5-8 minutos)

### 1️⃣ Limpeza Inicial

```bash
cd monitoring-security-level5
./scripts/cleanup.sh
```

**✅ Deve mostrar:** `✅ Limpeza concluída!`

---

### 2️⃣ Instalação Automática

```bash
./setup.sh
```

**⏱️ Aguarde:** 5-8 minutos  
**✅ Deve mostrar no final:**
```
✅ DEPLOYMENT CONCLUÍDO!
🔐 Credenciais salvas em: credentials.txt
```

---

### 3️⃣ Verificar Credenciais Geradas

```bash
cat credentials.txt
```

**✅ Deve conter:**
- Senha Zabbix: `ComplexP@ssw0rd_XXXXXX_L5!@`
- Senha Grafana: `K8s_Grafana_XXXXXX_Vault2024!@`

---

### 4️⃣ Validar Pods (8 Running + 3 Completed)

```bash
kubectl get pods -n monitoring
```

**✅ Resultado esperado:**
```
grafana-XXX                      1/1  Running    0  Xm
mysql-0                          1/1  Running    0  Xm
node-exporter-XXX                1/1  Running    0  Xm
prometheus-XXX                   1/1  Running    0  Xm
vault-0                          1/1  Running    0  Xm
zabbix-agent2-XXX                1/1  Running    0  Xm
zabbix-server-XXX                1/1  Running    0  Xm
zabbix-web-XXX                   1/1  Running    0  Xm

mysql-init-schema-XXX            0/1  Completed  0  Xm
vault-init-XXX                   0/1  Completed  0  Xm
zabbix-change-admin-password-X   0/1  Completed  0  Xm
```

---

### 5️⃣ Testar Login Zabbix

1. **Acessar:** http://localhost:30080
2. **Login:**
   - User: `Admin`
   - Pass: **(pegar do `credentials.txt`)**
3. **✅ Verificar:**
   - Login funciona com senha complexa
   - Dashboard carrega
   - `Monitoring → Hosts` mostra "Zabbix server" verde

---

### 6️⃣ Testar Login Grafana

1. **Acessar:** http://localhost:30300
2. **Login:**
   - User: `admin`
   - Pass: **(pegar do `credentials.txt`)**
3. **✅ Verificar:**
   - Login funciona com senha complexa
   - 2 dashboards existem ("Node Exporter", "Zabbix Server")
   - Data Sources conectados (Prometheus, Zabbix)

---

### 7️⃣ Validar External Secrets (Integração Vault)

```bash
kubectl get externalsecrets -n monitoring
```

**✅ Todos devem estar:** `STATUS=SecretSynced`
```
NAME                STORE           STATUS
grafana-secret      vault-backend   SecretSynced
mysql-secret        vault-backend   SecretSynced
prometheus-secret   vault-backend   SecretSynced
zabbix-secret       vault-backend   SecretSynced
```

---

### 8️⃣ Verificar Senhas no Vault

```bash
kubectl exec -n monitoring vault-0 -- sh -c 'export VAULT_TOKEN=vault-dev-root-token && vault kv get secret/zabbix'
```

**✅ Deve mostrar:**
```
====== Data ======
Key                 Value
---                 -----
admin-password      ComplexP@ssw0rd_XXXXXX_L5!@
database-password   K8s_MySQL_XXXXXX_Vault2024!@
server-password     K8s_Server_XXXXXX_Vault2024!@
```

---

## 📋 Checklist de Aprovação

- [ ] ✅ Cleanup executou sem erros
- [ ] ✅ Setup completou em menos de 10 minutos
- [ ] ✅ Arquivo `credentials.txt` gerado automaticamente
- [ ] ✅ 8 pods Running + 3 Completed
- [ ] ✅ Zabbix login funciona com senha complexa do Vault
- [ ] ✅ Grafana login funciona com senha complexa do Vault
- [ ] ✅ 4 ExternalSecrets sincronizados (SecretSynced)
- [ ] ✅ Vault armazena secrets com senhas 32+ caracteres
- [ ] ✅ ZERO arquivos .env ou senhas hardcoded visíveis
- [ ] ✅ Prometheus acessível (http://localhost:30900)

---

## 🎯 Diferenciais Level 5 vs Level 3

| Característica | Level 3 | Level 5 |
|----------------|---------|---------|
| **Comando único** | ❌ docker-compose up | ✅ ./setup.sh |
| **Secrets** | .env files | ✅ Vault + ESO |
| **Senhas** | 16-20 chars | ✅ 32-40 chars |
| **Plataforma** | Docker local | ✅ Kubernetes |
| **Cloud Ready** | ❌ Não | ✅ Kind/EKS/GKE/AKS |
| **Alteração senha** | Manual | ✅ Job automático |

---

## ⚠️ Se algo falhar

### Pods não sobem:
```bash
kubectl describe pod <nome-pod> -n monitoring
kubectl logs <nome-pod> -n monitoring
```

### Senha Zabbix não funciona:
```bash
kubectl logs job/zabbix-change-admin-password -n monitoring -c change-password
```

### ExternalSecrets erro:
```bash
kubectl logs -n external-secrets-system deployment/external-secrets
```

---

## 🎓 Resumo para Avaliação

**✅ Automação:** Instalação 100% com 1 comando  
**✅ Segurança:** Senhas 2x mais complexas que Level 3, gerenciadas via Vault  
**✅ Kubernetes-Native:** External Secrets Operator + RBAC + Policies  
**✅ Produção-Ready:** Funciona em Kind/EKS/GKE/AKS sem alterações  
**✅ Zero .env:** Secrets dinâmicos via ESO  

---

**⏱️ Tempo total do teste:** ~8 minutos  
**🎯 Objetivo:** Demonstrar evolução de segurança Level 1→5 com automação completa
