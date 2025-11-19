# 🚀 INSTRUÇÕES DE DEPLOYMENT - Level 5

## ⚠️ PROBLEMAS IDENTIFICADOS E CORREÇÕES

### 1. Timeout no `kubectl wait --for=condition=Ready`
**Problema**: Comando trava mesmo com node Ready (bug conhecido no WSL2)  
**Solução**: Substituído por verificação manual do status

### 2. Helm install demora muito
**Problema**: External Secrets Operator via Helm pode demorar 5+ minutos  
**Solução**: Script agora detecta se ESO já está instalado e pula reinstalação

### 3. Portas em uso após cleanup
**Problema**: `cleanup.sh` não sempre libera portas imediatamente  
**Solução**: Script verifica portas antes de iniciar

## ✅ DEPLOYMENT OTIMIZADO

### Passo 1: Verificar Ambiente (OBRIGATÓRIO)
```bash
cd /home/luiz7/monitoring-security-level5
./scripts/check-environment.sh
```

**Se falhar com portas em uso:**
```bash
# Limpeza forçada
kind delete cluster
docker ps -a | grep kind | awk '{print $1}' | xargs -r docker rm -f
sleep 5
./scripts/check-environment.sh
```

### Passo 2: Deploy Completo
```bash
./setup.sh
```

**Tempo Esperado**: 8-12 minutos total
- Cluster Kind: 1-2 min
- External Secrets: 2-4 min (primeira vez)
- MySQL + Schema: 2-3 min  
- Zabbix Stack: 2-3 min
- Configuração: 1-2 min

### Passo 3: Verificação
```bash
# Ver pods
kubectl get pods -n monitoring

# Ver credenciais
./scripts/show-credentials.sh
```

## 🔧 ALTERAÇÕES APLICADAS NOS SCRIPTS

### `deploy.sh`
- ✅ Verificação de memória RAM no início
- ✅ `kubectl wait` substituído por loop com verificação manual
- ✅ CoreDNS verificado antes de continuar
- ✅ Timeout do mysql-init-schema aumentado para 10min
- ✅ Logs de erro mais detalhados

### `setup.sh`
- ✅ Login Zabbix usa senha do Vault (não mais "zabbix")
- ✅ Obtenção de senhas com VAULT_TOKEN correto
- ✅ Validação de Grafana usa senha do Vault

### `check-environment.sh` (NOVO)
- ✅ Verifica todas as dependências
- ✅ Checa recursos (RAM, CPU, Disco)
- ✅ Valida portas disponíveis
- ✅ Detecta cluster existente

## 🐛 SE AINDA ASSIM FALHAR

### Cenário 1: Timeout no CoreDNS
```bash
kubectl rollout restart deployment/coredns -n kube-system
sleep 30
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

### Cenário 2: MySQL Init Schema trava
```bash
# Ver logs
kubectl logs -n monitoring job/mysql-init-schema --all-containers=true

# Se usuário não existe
kubectl delete job mysql-init-schema -n monitoring
kubectl apply -f kubernetes/05-mysql/mysql-init-job.yaml
```

### Cenário 3: External Secrets demora muito
```bash
# Verificar se já está rodando
kubectl get pods -n external-secrets-system

# Se sim, pular instalação do Helm e continuar
kubectl create namespace monitoring
kubectl apply -f kubernetes/02-vault/
# ... continue manualmente seguindo deploy.sh
```

## 📊 MÉTRICAS DE SUCESSO

Após `./setup.sh` finalizar, você DEVE ver:

```
✅ 10 pods total (8 Running + 2 Completed)
✅ 4 External Secrets sincronizados
✅ Credenciais exibidas na tela
✅ Arquivo credentials.txt criado
```

**Acessos:**
- Zabbix: http://localhost:30080
- Grafana: http://localhost:30300  
- Prometheus: http://localhost:30900

## 🔄 REINSTALAÇÃO LIMPA

```bash
# Limpeza TOTAL
kind delete cluster
docker ps -a | grep kind | awk '{print $1}' | xargs -r docker rm -f
sleep 5

# Verificar ambiente
./scripts/check-environment.sh

# Deploy
./setup.sh
```

## 💡 DICAS WSL2

Se continuar tendo problemas, ajuste recursos do WSL2:

**Arquivo**: `C:\Users\<seu-usuario>\.wslconfig`
```ini
[wsl2]
memory=6GB
processors=4
swap=2GB
```

Após editar, reinicie WSL:
```powershell
wsl --shutdown
```

---

**Última atualização**: 19/11/2025 16:00  
**Status**: Scripts otimizados e testados  
**Próximo teste**: Aguardando confirmação do usuário
