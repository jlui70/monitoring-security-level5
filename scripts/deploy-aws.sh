#!/bin/bash

# Script de Deploy na AWS EKS - Monitoring Security Level 5
# Este script cria cluster EKS e faz deploy completo da stack

set -e

PROJECT_NAME="monitoring-level5"
CLUSTER_NAME="monitoring-security-level5"
REGION="us-east-1"
NODE_TYPE="t3.medium"
NODES_COUNT=3

echo "🚀 Deploy AWS EKS - Monitoring Security Level 5"
echo "================================================"
echo ""
echo "📋 Configuração:"
echo "   Cluster: $CLUSTER_NAME"
echo "   Region: $REGION"
echo "   Nodes: $NODES_COUNT x $NODE_TYPE"
echo "   Custo estimado: ~$0.30/hora (~$214/mês)"
echo ""

# Confirmar
read -p "⚠️  Isso vai criar recursos na AWS (com custo). Continuar? (s/N): " confirm
if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
    echo "❌ Cancelado"
    exit 0
fi

echo ""
echo "📝 Salvando configurações para cleanup posterior..."
cat > aws-cluster-info.txt << EOF
CLUSTER_NAME=$CLUSTER_NAME
REGION=$REGION
CREATED_AT=$(date '+%Y-%m-%d %H:%M:%S')
EOF

echo ""
echo "⏱️  ETAPA 1/6: Criando cluster EKS (15-20 min)..."
echo "   Nodes: $NODES_COUNT x $NODE_TYPE"
echo "   Region: $REGION"
echo ""

eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --nodegroup-name standard-workers \
  --node-type $NODE_TYPE \
  --nodes $NODES_COUNT \
  --nodes-min 3 \
  --nodes-max 5 \
  --managed \
  --with-oidc \
  --tags "Project=$PROJECT_NAME,Environment=Test,ManagedBy=eksctl"

if [ $? -ne 0 ]; then
    echo "❌ Erro ao criar cluster!"
    exit 1
fi

echo ""
echo "✅ Cluster EKS criado com sucesso!"
echo ""

# Verificar contexto kubectl
echo "⏱️  ETAPA 2/6: Configurando kubectl..."
kubectl config use-context $(kubectl config get-contexts -o name | grep $CLUSTER_NAME)
kubectl get nodes

echo ""
echo "⏱️  ETAPA 3/6: Instalando EBS CSI Driver (necessário para PVCs)..."
echo ""

# Criar IAM service account para EBS CSI Driver
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster $CLUSTER_NAME \
  --region $REGION \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole_$CLUSTER_NAME

# Instalar addon EBS CSI
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
eksctl create addon \
  --name aws-ebs-csi-driver \
  --cluster $CLUSTER_NAME \
  --region $REGION \
  --service-account-role-arn arn:aws:iam::${ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole_$CLUSTER_NAME \
  --force

echo ""
echo "✅ EBS CSI Driver instalado!"
echo ""

echo "⏱️  ETAPA 4/6: Aplicando Storage Class AWS..."
kubectl apply -f kubernetes/04-storage/aws/

echo ""
echo "✅ Storage Class configurado!"
echo ""

echo "⏱️  ETAPA 5/6: Instalando External Secrets Operator..."

# Instalar ESO via Helm (mais confiável que kubectl apply)
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets-system \
  --create-namespace \
  --wait

echo ""
echo "✅ External Secrets Operator instalado!"
echo ""

echo "⏱️  ETAPA 6/6: Deploy da stack de monitoramento..."
echo ""
echo "⚠️  Este processo leva 6-8 minutos devido a:"
echo "   - Vault unseal e configuração inicial"
echo "   - MySQL criação de schema (~2-3 min)"
echo "   - Zabbix aguardando banco pronto"
echo "   - ExternalSecrets sincronização"
echo ""

# Criar namespace primeiro
echo "📦 Criando namespace monitoring..."
kubectl create namespace monitoring 2>/dev/null || echo "   Namespace já existe"

# Deploy em ordem (seguindo a estrutura real do projeto)
echo ""
echo "🔐 PASSO 1/7: Deploy Vault..."
kubectl apply -f kubernetes/02-vault/

echo "   Aguardando pod Vault iniciar..."
kubectl wait --for=condition=ready pod -l app=vault -n monitoring --timeout=180s

echo "   Aguardando Vault unseal (30s)..."
sleep 30

# Verificar Vault unsealed
echo "   Verificando Vault status..."
kubectl exec -n monitoring vault-0 -- vault status | grep -q "Sealed.*false" || {
    echo "   ⚠️  Vault ainda sealed, aguardando mais 20s..."
    sleep 20
}

# Criar vault-token secret (necessário para External Secrets Operator)
echo ""
echo "🔑 Criando vault-token secret para ESO..."
kubectl create secret generic vault-token \
  -n monitoring \
  --from-literal=token=vault-dev-root-token \
  --dry-run=client -o yaml | kubectl apply -f -

echo "   ✅ vault-token criado!"

# Deploy ExternalSecrets (SecretStore + ExternalSecrets)
echo ""
echo "🔐 PASSO 2/7: Configurando ExternalSecrets..."
kubectl apply -f kubernetes/03-external-secrets/

echo "   Aguardando sincronização dos secrets (20s)..."
sleep 20

# Verificar ExternalSecrets
echo "   Verificando sincronização..."
kubectl get externalsecrets -n monitoring

# Se ainda houver SecretSyncedError, reiniciar ESO
if kubectl get externalsecrets -n monitoring | grep -q "SecretSyncedError"; then
    echo "   ⚠️  Detectado SecretSyncedError, reiniciando External Secrets Operator..."
    kubectl delete pod -n external-secrets-system -l app.kubernetes.io/name=external-secrets
    echo "   Aguardando nova sincronização (30s)..."
    sleep 30
    kubectl get externalsecrets -n monitoring
fi

# Deploy MySQL
echo ""
echo "🗄️  PASSO 3/7: Deploy MySQL..."
kubectl apply -f kubernetes/05-mysql/

echo "   Aguardando pod MySQL iniciar..."
kubectl wait --for=condition=ready pod -l app=mysql -n monitoring --timeout=180s

echo "   Aguardando MySQL init completar (15s)..."
sleep 15

# Verificar MySQL pronto
echo "   Testando conexão MySQL..."
kubectl exec -n monitoring mysql-0 -- mysql -uroot -p'VaultRootPass2024!' -e "SHOW DATABASES;" >/dev/null 2>&1 || {
    echo "   ⚠️  MySQL ainda inicializando, aguardando mais 30s..."
    sleep 30
}

# Deploy Zabbix
echo ""
echo "📊 PASSO 4/7: Deploy Zabbix..."
kubectl apply -f kubernetes/06-zabbix/

echo "   Aguardando pods iniciarem..."
sleep 30

# Aguardar Zabbix criar schema (processo demorado)
echo ""
echo "⏳ Aguardando Zabbix criar schema do banco (2-3 min)..."
echo "   Isso é normal - Zabbix cria ~200 tabelas na primeira execução"

# Monitorar logs do Zabbix Server até ver "server started"
timeout=180
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if kubectl logs -n monitoring -l app=zabbix-server --tail=20 2>/dev/null | grep -q "server.*started"; then
        echo "   ✅ Zabbix Server iniciado com sucesso!"
        break
    fi
    
    # Mostrar progresso
    if [ $((elapsed % 30)) -eq 0 ]; then
        echo "   Ainda criando schema... ($elapsed/${timeout}s)"
    fi
    
    sleep 10
    elapsed=$((elapsed + 10))
done

if [ $elapsed -ge $timeout ]; then
    echo "   ⚠️  Timeout aguardando Zabbix, mas continuando..."
fi

# Deploy Prometheus
echo ""
echo "📊 PASSO 5/7: Deploy Prometheus..."
kubectl apply -f kubernetes/07-prometheus/

# Deploy Grafana
echo ""
echo "📊 PASSO 6/7: Deploy Grafana..."
kubectl apply -f kubernetes/08-grafana/

# Deploy Node Exporter
echo ""
echo "📊 PASSO 7/7: Deploy Node Exporter (DaemonSet em todos os nodes)..."
kubectl apply -f kubernetes/09-node-exporter/

# Aguardar todos os pods ficarem prontos
echo ""
echo "🔍 Aguardando todos os pods ficarem Running/Completed..."
sleep 20
kubectl wait --for=condition=ready pod --all -n monitoring --timeout=300s 2>/dev/null || {
    echo "   ⚠️  Alguns pods ainda não estão Ready, verificando status..."
    kubectl get pods -n monitoring
}

echo ""
echo "⏱️  ETAPA 7/8: Configurando Zabbix (templates e hosts)..."
echo ""

# Aguardar Zabbix Web estar 100% pronto
sleep 10

# Executar configuração do Zabbix
if [ -f "./scripts/configure-zabbix-aws.sh" ]; then
    ./scripts/configure-zabbix-aws.sh
else
    echo "   ⚠️  Script configure-zabbix-aws.sh não encontrado"
fi

echo ""
echo "⏱️  ETAPA 8/8: Configurando Grafana (datasources e dashboards)..."
echo ""

# Executar configuração do Grafana
if [ -f "./scripts/configure-grafana-aws.sh" ]; then
    ./scripts/configure-grafana-aws.sh
else
    echo "   ⚠️  Script configure-grafana-aws.sh não encontrado"
fi

echo ""
echo "=========================================="
echo "✅ DEPLOY COMPLETO NA AWS EKS!"
echo "=========================================="
echo ""

# Verificar status final
echo "📊 STATUS FINAL DOS RECURSOS:"
echo ""

echo "1️⃣  Nodes:"
kubectl get nodes

echo ""
echo "2️⃣  Pods:"
kubectl get pods -n monitoring

echo ""
echo "3️⃣  ExternalSecrets:"
kubectl get externalsecrets -n monitoring

echo ""
echo "4️⃣  Kubernetes Secrets criados:"
kubectl get secrets -n monitoring | grep -E "mysql|zabbix|grafana"

echo ""
echo "5️⃣  Volumes EBS:"
kubectl get pvc -n monitoring

echo ""
echo "=========================================="
echo ""

# Obter Load Balancer URLs (se aplicar)
echo "🌐 Obtendo URLs de acesso..."
echo ""

# NodePort ainda funciona, mas vamos mostrar como expor via LoadBalancer
echo "📋 Acesso via NodePort (interno ao cluster):"
echo "   Para acessar externamente, você precisa:"
echo "   1. Port-forward: kubectl port-forward -n monitoring svc/grafana 3000:3000"
echo "   2. LoadBalancer: kubectl patch svc grafana -n monitoring -p '{\"spec\":{\"type\":\"LoadBalancer\"}}'"
echo ""

# Salvar informações de acesso
cat >> aws-cluster-info.txt << EOF

# Comandos úteis:
# Ver pods:
kubectl get pods -n monitoring

# Ver secrets:
kubectl get externalsecrets -n monitoring

# Port-forward Grafana:
kubectl port-forward -n monitoring svc/grafana 30300:3000

# Port-forward Zabbix:
kubectl port-forward -n monitoring svc/zabbix-web 30080:8080

# Port-forward Prometheus:
kubectl port-forward -n monitoring svc/prometheus 30900:9090

# Expor Grafana via LoadBalancer (cria IP público):
kubectl patch svc grafana -n monitoring -p '{"spec":{"type":"LoadBalancer"}}'
kubectl get svc grafana -n monitoring
EOF

echo "📝 Informações salvas em: aws-cluster-info.txt"
echo ""
echo "🎯 Próximos passos:"
echo "1. Verificar pods: kubectl get pods -n monitoring"
echo "2. Acessar Grafana: kubectl port-forward -n monitoring svc/grafana 30300:3000"
echo "3. Quando terminar: ./scripts/cleanup-aws.sh"
echo ""
echo "💰 Custo estimado: ~$0.30/hora"
echo "⚠️  Lembre-se de deletar o cluster quando terminar!"
echo ""
