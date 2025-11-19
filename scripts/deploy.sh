#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "🚀 Deployment Monitoring Stack - Level 5"
echo "=========================================="
echo ""

# Verificar recursos disponíveis
echo "🔍 Verificando recursos do sistema..."
total_mem=$(free -g | awk '/^Mem:/{print $2}')
if [ "$total_mem" -lt 4 ]; then
    echo "⚠️  ATENÇÃO: Sistema com apenas ${total_mem}GB RAM detectado"
    echo "💡 Recomendado: Pelo menos 4GB RAM para deployment completo"
    echo "   Configure mais memória no WSL2/Docker Desktop se possível"
    echo ""
fi

# Verificar se kind está instalado
if ! command -v kind &> /dev/null; then
    echo "❌ kind não encontrado. Instale com: curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64 && chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind"
    exit 1
fi

# Verificar se kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl não encontrado. Instale com: curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/"
    exit 1
fi

# Verificar se cluster já existe
if kind get clusters 2>/dev/null | grep -q "^kind$"; then
    echo "✅ Cluster 'kind' já existe, usando o existente"
fi

# Criar cluster Kind se não existir
if ! kind get clusters 2>/dev/null | grep -q "^kind$"; then
    echo "📦 Criando cluster Kind..."
    cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
  - containerPort: 30300
    hostPort: 30300
    protocol: TCP
  - containerPort: 30900
    hostPort: 30900
    protocol: TCP
EOF
fi

echo "⏳ Aguardando cluster estar pronto..."
# Verificação mais robusta sem kubectl wait (que às vezes falha)
ready=false
for i in {1..24}; do  # 24 tentativas de 15s = 6 minutos total
    node_status=$(kubectl get nodes --no-headers 2>/dev/null | awk '{print $2}')
    if [[ "$node_status" == "Ready" ]]; then
        echo "✅ Cluster pronto!"
        ready=true
        break
    fi
    echo "  Tentativa $i/24... Node status: ${node_status:-aguardando}"
    sleep 15
done

if [ "$ready" = false ]; then
    echo "❌ Timeout aguardando cluster ficar pronto"
    echo "💡 Dica: Verifique se Docker Desktop/WSL2 tem recursos suficientes"
    echo "   Node status: $(kubectl get nodes 2>&1)"
    exit 1
fi

echo "⏳ Aguardando API server estabilizar..."
sleep 10

# Verificar CoreDNS (crítico para External Secrets e Grafana)
echo "🔍 Verificando CoreDNS..."
coredns_ready=false
for i in {1..12}; do
    ready_count=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | grep "Running" | wc -l)
    if [ "$ready_count" -ge 1 ]; then
        echo "✅ CoreDNS pronto! ($ready_count pods Running)"
        coredns_ready=true
        break
    fi
    echo "  Aguardando CoreDNS... tentativa $i/12"
    sleep 10
done

if [ "$coredns_ready" = false ]; then
    echo "⚠️  CoreDNS demorou para iniciar, tentando reiniciar..."
    kubectl rollout restart deployment/coredns -n kube-system 2>/dev/null || true
    sleep 15
    # Verificar novamente após restart
    ready_count=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | grep "Running" | wc -l)
    if [ "$ready_count" -ge 1 ]; then
        echo "✅ CoreDNS pronto após restart! ($ready_count pods Running)"
    else
        echo "⚠️  CoreDNS ainda não está pronto, mas continuando (pode causar problemas com DNS)"
    fi
fi

echo "📦 Instalando External Secrets Operator..."
# Verificar se helm está instalado
if ! command -v helm &> /dev/null; then
    echo "⚠️  Helm não encontrado. Instalando External Secrets via manifests alternativos..."
    # Criar namespace se não existir
    kubectl create namespace external-secrets-system --dry-run=client -o yaml | kubectl apply -f -
    
    # Aplicar CRDs localmente (para evitar rate limit do GitHub)
    cat <<EOF | kubectl apply -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: externalsecrets.external-secrets.io
spec:
  group: external-secrets.io
  names:
    kind: ExternalSecret
    listKind: ExternalSecretList
    plural: externalsecrets
    shortNames:
    - es
    singular: externalsecret
  scope: Namespaced
  versions:
  - name: v1beta1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              secretStoreRef:
                type: object
                properties:
                  name:
                    type: string
                  kind:
                    type: string
              target:
                type: object
                properties:
                  name:
                    type: string
                  creationPolicy:
                    type: string
              refreshInterval:
                type: string
              data:
                type: array
                items:
                  type: object
                  properties:
                    secretKey:
                      type: string
                    remoteRef:
                      type: object
                      properties:
                        key:
                          type: string
                        property:
                          type: string
EOF
    
    cat <<EOF | kubectl apply -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: secretstores.external-secrets.io
spec:
  group: external-secrets.io
  names:
    kind: SecretStore
    listKind: SecretStoreList
    plural: secretstores
    singular: secretstore
  scope: Namespaced
  versions:
  - name: v1beta1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            x-kubernetes-preserve-unknown-fields: true
EOF
    
    # Deploy operator simplificado
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets
  namespace: external-secrets-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-secrets
  namespace: external-secrets-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: external-secrets
  template:
    metadata:
      labels:
        app: external-secrets
    spec:
      serviceAccountName: external-secrets
      containers:
      - name: external-secrets
        image: ghcr.io/external-secrets/external-secrets:v0.9.9
        imagePullPolicy: IfNotPresent
        args:
        - --concurrent=1
        ports:
        - containerPort: 8080
          name: metrics
        resources:
          requests:
            memory: "128Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "100m"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-secrets
rules:
- apiGroups: ["external-secrets.io"]
  resources: ["externalsecrets", "secretstores"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["secrets", "serviceaccounts"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["create", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-secrets
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-secrets
subjects:
- kind: ServiceAccount
  name: external-secrets
  namespace: external-secrets-system
EOF
else
    # Usar Helm se disponível
    helm repo add external-secrets https://charts.external-secrets.io || true
    helm repo update
    
    echo "⏳ Instalando External Secrets Operator via Helm (com retry)..."
    max_attempts=3
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "   Tentativa $attempt/$max_attempts..."
        
        if helm install external-secrets external-secrets/external-secrets \
            -n external-secrets-system \
            --create-namespace \
            --timeout 5m \
            --wait 2>/dev/null; then
            echo "✅ External Secrets Operator instalado com sucesso!"
            break
        else
            if [ $attempt -lt $max_attempts ]; then
                echo "⚠️  Tentativa $attempt falhou, aguardando 15 segundos..."
                sleep 15
                attempt=$((attempt + 1))
            else
                echo "❌ Falha após $max_attempts tentativas"
                exit 1
            fi
        fi
    done
fi

echo "⏳ Aguardando External Secrets Operator..."
for i in {1..36}; do  # 36 * 5s = 3min
    eso_ready=$(kubectl get deployment external-secrets -n external-secrets-system -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")
    if [[ "$eso_ready" -ge 1 ]]; then
        echo "✅ External Secrets Operator pronto!"
        break
    fi
    if [[ $((i % 6)) -eq 0 ]]; then
        echo "  [$i/36] ESO: $eso_ready/1"
    fi
    sleep 5
done
sleep 5

echo "📁 Aplicando Storage Class (Kind)..."
kubectl apply -f "$PROJECT_ROOT/kubernetes/04-storage/kind/storage-class.yaml"

echo "🏗️  Criando namespace..."
kubectl apply -f "$PROJECT_ROOT/kubernetes/01-namespace/namespace.yaml"

echo "🔐 Implantando Vault..."
kubectl apply -f "$PROJECT_ROOT/kubernetes/02-vault/"
echo "⏳ Aguardando Vault estar pronto..."
for i in {1..48}; do  # 48 * 5s = 4min
    vault_ready=$(kubectl get pod -l app=vault -n monitoring -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
    if [[ "$vault_ready" == "true" ]]; then
        echo "✅ Vault pronto!"
        break
    fi
    if [[ $i -eq 1 ]]; then
        echo "  Aguardando pod do Vault ser criado..."
    elif [[ $((i % 6)) -eq 0 ]]; then
        echo "  [$i/48] Vault ainda não está pronto..."
    fi
    sleep 5
done

if [[ "$(kubectl get pod -l app=vault -n monitoring -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)" != "true" ]]; then
    echo "❌ Vault não ficou pronto"
    kubectl get pods -n monitoring -l app=vault
    exit 1
fi

echo "🔑 Inicializando Vault com secrets..."
kubectl apply -f "$PROJECT_ROOT/kubernetes/02-vault/vault-init-job.yaml"
for i in {1..48}; do  # 48 * 5s = 4min
    job_status=$(kubectl get job vault-init -n monitoring -o jsonpath='{.status.succeeded}' 2>/dev/null || echo "0")
    if [[ "$job_status" == "1" ]]; then
        echo "✅ Vault inicializado com secrets!"
        break
    fi
    if [[ $i -eq 1 ]]; then
        echo "  Aguardando job vault-init ser criado..."
    elif [[ $((i % 12)) -eq 0 ]]; then
        echo "  [$i/48] Vault-init rodando ($(( i * 5 / 60 ))min)..."
    fi
    sleep 5
done

if [[ "$(kubectl get job vault-init -n monitoring -o jsonpath='{.status.succeeded}' 2>/dev/null)" != "1" ]]; then
    echo "❌ Job vault-init falhou"
    kubectl logs -n monitoring job/vault-init --tail=50
    exit 1
fi

echo "📦 Configurando External Secrets..."
# Criar secret com token do Vault
kubectl create secret generic vault-token \
  --from-literal=token='vault-dev-root-token' \
  -n monitoring --dry-run=client -o yaml | kubectl apply -f -

# Aplicar manifests
kubectl apply -f "$PROJECT_ROOT/kubernetes/03-external-secrets/"

# CRÍTICO: Reiniciar ESO para reconhecer vault-token
echo "🔄 Reiniciando External Secrets Operator para reconhecer vault-token..."
kubectl rollout restart deployment/external-secrets -n external-secrets-system
kubectl rollout status deployment/external-secrets -n external-secrets-system --timeout=120s

echo "⏳ Aguardando secrets serem criados (30s)..."
sleep 30

# Verificar se secrets foram criados
for secret in mysql-secret zabbix-secret grafana-secret prometheus-secret; do
    if kubectl get secret $secret -n monitoring &> /dev/null; then
        echo "✅ Secret $secret criado"
    else
        echo "❌ Falha ao criar secret $secret"
        exit 1
    fi
done

echo "💾 Implantando MySQL..."
kubectl apply -f "$PROJECT_ROOT/kubernetes/05-mysql/mysql-configmap.yaml"
kubectl apply -f "$PROJECT_ROOT/kubernetes/05-mysql/mysql-service.yaml"
kubectl apply -f "$PROJECT_ROOT/kubernetes/05-mysql/mysql-statefulset.yaml"

echo "⏳ Aguardando MySQL ficar Ready (com detecção de CrashLoopBackOff)..."
for i in {1..36}; do  # 36 * 5s = 3min
    mysql_status=$(kubectl get pod mysql-0 -n monitoring -o jsonpath='{.status.phase}' 2>/dev/null || echo "Pending")
    mysql_ready=$(kubectl get pod mysql-0 -n monitoring -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
    
    if [[ "$mysql_ready" == "true" ]]; then
        echo "✅ MySQL pronto!"
        break
    fi
    
    # Detectar CrashLoopBackOff
    if kubectl get pod mysql-0 -n monitoring 2>/dev/null | grep -q "CrashLoopBackOff"; then
        echo "⚠️  MySQL em CrashLoopBackOff detectado! Verificando causa..."
        kubectl logs mysql-0 -n monitoring --tail=20 2>/dev/null || true
        
        # Verificar se é problema de volume corrompido
        if kubectl logs mysql-0 -n monitoring 2>/dev/null | grep -q "data files are corrupt\|Corruption"; then
            echo "🔧 Volumes corrompidos detectados! Recriando com volumes limpos..."
            kubectl delete statefulset mysql -n monitoring --force --grace-period=0 2>/dev/null || true
            kubectl delete pvc mysql-data-mysql-0 -n monitoring --force --grace-period=0 2>/dev/null || true
            sleep 5
            echo "📦 Recriando MySQL com volume novo..."
            kubectl apply -f "$PROJECT_ROOT/kubernetes/05-mysql/mysql-statefulset.yaml"
            continue
        else
            echo "❌ MySQL falhou por outro motivo. Verificar logs acima."
            exit 1
        fi
    fi
    
    echo "  [$i/36] MySQL: $mysql_status (Ready: $mysql_ready)"
    sleep 5
done

# Verificação final
if ! kubectl get pod mysql-0 -n monitoring -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null | grep -q "true"; then
    echo "❌ MySQL não ficou Ready após 3 minutos"
    kubectl describe pod mysql-0 -n monitoring
    exit 1
fi

echo "🗄️  Inicializando schema MySQL..."
kubectl apply -f "$PROJECT_ROOT/kubernetes/05-mysql/mysql-init-job.yaml"
echo "⏳ Aguardando schema ser criado (pode levar até 10 minutos)..."
for i in {1..120}; do  # 120 * 5s = 10min
    job_status=$(kubectl get job mysql-init-schema -n monitoring -o jsonpath='{.status.succeeded}' 2>/dev/null || echo "0")
    if [[ "$job_status" == "1" ]]; then
        echo "✅ Schema MySQL criado com sucesso!"
        break
    fi
    if [[ $((i % 12)) -eq 0 ]]; then  # A cada minuto
        echo "  [$i/120] Aguardando job mysql-init-schema ($(( i * 5 / 60 ))min)..."
    fi
    sleep 5
done

if [[ "$(kubectl get job mysql-init-schema -n monitoring -o jsonpath='{.status.succeeded}' 2>/dev/null)" != "1" ]]; then
    echo "❌ Job mysql-init-schema falhou ou não completou"
    kubectl logs -n monitoring job/mysql-init-schema --tail=50
    exit 1
fi

echo "📊 Implantando Zabbix..."
kubectl apply -f "$PROJECT_ROOT/kubernetes/06-zabbix/"

echo "⏳ Aguardando Zabbix Server e Web..."
for i in {1..48}; do  # 48 * 5s = 4min
    server_ready=$(kubectl get deploy zabbix-server -n monitoring -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")
    web_ready=$(kubectl get deploy zabbix-web -n monitoring -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")
    
    if [[ "$server_ready" -ge 1 && "$web_ready" -ge 1 ]]; then
        echo "✅ Zabbix Server e Web prontos!"
        break
    fi
    echo "  [$i/48] Server: $server_ready/1, Web: $web_ready/1"
    sleep 5
done

echo "🔐 Alterando senha padrão do Admin para senha complexa do Vault..."
kubectl apply -f "$PROJECT_ROOT/kubernetes/06-zabbix/zabbix-admin-password-job.yaml"
for i in {1..24}; do  # 24 * 5s = 2min
    job_status=$(kubectl get job zabbix-change-admin-password -n monitoring -o jsonpath='{.status.succeeded}' 2>/dev/null || echo "0")
    if [[ "$job_status" == "1" ]]; then
        echo "✅ Senha do Zabbix alterada!"
        break
    fi
    sleep 5
done

echo "📈 Implantando Prometheus..."
kubectl apply -f "$PROJECT_ROOT/kubernetes/07-prometheus/"
for i in {1..36}; do  # 36 * 5s = 3min
    prom_ready=$(kubectl get deploy prometheus -n monitoring -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")
    if [[ "$prom_ready" -ge 1 ]]; then
        echo "✅ Prometheus pronto!"
        break
    fi
    echo "  [$i/36] Prometheus: $prom_ready/1"
    sleep 5
done

echo "📉 Implantando Node Exporter..."
kubectl apply -f "$PROJECT_ROOT/kubernetes/09-node-exporter/"
for i in {1..24}; do  # 24 * 5s = 2min
    node_ready=$(kubectl get ds node-exporter -n monitoring -o jsonpath='{.status.numberReady}' 2>/dev/null || echo "0")
    if [[ "$node_ready" -ge 1 ]]; then
        echo "✅ Node Exporter pronto!"
        break
    fi
    echo "  [$i/24] Node Exporter: $node_ready/1"
    sleep 5
done

echo "📊 Implantando Grafana..."
kubectl apply -f "$PROJECT_ROOT/kubernetes/08-grafana/"
for i in {1..48}; do  # 48 * 5s = 4min
    grafana_ready=$(kubectl get deploy grafana -n monitoring -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")
    if [[ "$grafana_ready" -ge 1 ]]; then
        echo "✅ Grafana pronto!"
        break
    fi
    echo "  [$i/48] Grafana: $grafana_ready/1"
    sleep 5
done

echo ""
echo "⏳ Aguardando todos os pods ficarem prontos..."
sleep 10

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT CONCLUÍDO!"
echo "=========================================="
echo ""
echo "📊 Status dos Pods:"
kubectl get pods -n monitoring
echo ""
echo "🔐 Secrets gerenciados pelo Vault:"
kubectl get externalsecrets -n monitoring
echo ""
echo "📝 Próximos passos:"
echo "  1. ./scripts/show-credentials.sh   - Ver credenciais de acesso"
echo "  2. ./scripts/configure-zabbix.sh   - Configurar templates no Zabbix"
echo "  3. ./scripts/configure-grafana.sh  - Importar dashboards no Grafana"
echo ""
echo "💡 Para acesso rápido:"
echo "   ./scripts/show-credentials.sh"
echo ""
