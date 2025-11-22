#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# Script de Deploy AWS EKS com Ingress + HTTPS
# ═══════════════════════════════════════════════════════════════════════════
# Versão avançada com domínio público e certificados SSL automáticos
# Baseado no deploy-aws.sh + Ingress Controller + Cert-Manager
#
# ⚠️  CONFIGURAÇÃO OBRIGATÓRIA ANTES DE EXECUTAR:
#
# 1. Substitua DOMAIN pelo seu domínio registrado (linha 17)
# 2. Substitua EMAIL pelo seu email válido (linha 18)
# 3. Tenha acesso ao painel DNS do seu domínio (HostGator/GoDaddy)
#
# Exemplo:
#   DOMAIN="meusite.com.br"
#   EMAIL="meu-email@gmail.com"
#
# ═══════════════════════════════════════════════════════════════════════════

set -e

PROJECT_NAME="monitoring-level5-ingress"
CLUSTER_NAME="monitoring-security-level5"
REGION="us-east-1"
NODE_TYPE="t3.medium"
NODES_COUNT=3

# ═══════════════════════════════════════════════════════════════════════════
# ⚠️  EDITE AQUI - DOMÍNIO E EMAIL
# ═══════════════════════════════════════════════════════════════════════════
DOMAIN="devopsproject.com.br"        # ← SEU DOMÍNIO (obrigatório)
EMAIL="luiz7030@gmail.com"           # ← SEU EMAIL (obrigatório)
# ═══════════════════════════════════════════════════════════════════════════

echo "🚀 Deploy AWS EKS - Monitoring com Ingress + HTTPS"
echo "=================================================="
echo ""
echo "📋 Configuração:"
echo "   Cluster: $CLUSTER_NAME"
echo "   Region: $REGION"
echo "   Nodes: $NODES_COUNT x $NODE_TYPE"
echo "   Domínio: $DOMAIN"
echo "   Custo estimado: ~$0.46/hora (~$330/mês)"
echo "     - EKS Cluster: $0.10/hora"
echo "     - EC2 (3x t3.medium): $0.30/hora"
echo "     - Load Balancer (NLB): $0.06/hora"
echo ""

# Validação de domínio
if [ "$DOMAIN" == "devopsproject.com.br" ] || [ "$EMAIL" == "seu-email@exemplo.com" ]; then
    echo "⚠️  ATENÇÃO: Você precisa configurar o domínio e email!"
    echo ""
    echo "Edite este script e altere:"
    echo "  DOMAIN=\"seu-dominio.com.br\""
    echo "  EMAIL=\"seu-email@exemplo.com\""
    echo ""
    read -p "Continuar mesmo assim? (s/N): " continue_anyway
    if [ "$continue_anyway" != "s" ] && [ "$continue_anyway" != "S" ]; then
        echo "❌ Cancelado"
        exit 0
    fi
fi

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
DOMAIN=$DOMAIN
CREATED_AT=$(date '+%Y-%m-%d %H:%M:%S')
EOF

echo ""
echo "⏱️  ETAPA 1/10: Criando cluster EKS (15-20 min)..."
echo "   Nodes: $NODES_COUNT x $NODE_TYPE"
echo "   Region: $REGION"
echo ""

eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --nodegroup-name standard-workers \
  --node-type $NODE_TYPE \
  --nodes $NODES_COUNT \
  --nodes-min $NODES_COUNT \
  --nodes-max $NODES_COUNT \
  --managed

echo ""
echo "✅ Cluster criado!"
echo ""

echo "⏱️  ETAPA 2/10: Configurando IAM OIDC Provider..."
eksctl utils associate-iam-oidc-provider \
  --cluster $CLUSTER_NAME \
  --region $REGION \
  --approve

echo "✅ OIDC Provider associado!"
echo ""

echo "⏱️  ETAPA 3/10: Instalando EBS CSI Driver..."
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster $CLUSTER_NAME \
  --region $REGION \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --override-existing-serviceaccounts

echo ""
echo "⏱️  Aguardando IAM role ser criado (até 60s)..."

# Aguardar role ser criado com retry
# Nota: eksctl trunca nomes longos, então buscamos por 'addon-iamse' ao invés do nome completo
for i in {1..12}; do
  ROLE_ARN=$(aws iam list-roles --query "Roles[?contains(RoleName, 'eksctl-${CLUSTER_NAME}-addon-iamse-Role1')].Arn" --output text 2>/dev/null)
  if [ -n "$ROLE_ARN" ]; then
    echo "✅ IAM role encontrado: $ROLE_ARN"
    break
  fi
  echo "   Tentativa $i/12... aguardando 5s"
  sleep 5
done

if [ -z "$ROLE_ARN" ]; then
  echo "❌ Erro: IAM role não foi criado"
  exit 1
fi

eksctl create addon \
  --name aws-ebs-csi-driver \
  --cluster $CLUSTER_NAME \
  --region $REGION \
  --service-account-role-arn $ROLE_ARN \
  --force

echo "✅ EBS CSI Driver instalado!"
echo ""

echo "⏱️  ETAPA 4/11: Criando namespace e StorageClass..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp3
  encrypted: "true"
EOF

echo "✅ Namespace e StorageClass criados!"
echo ""

echo "⏱️  ETAPA 5/11: Deploy Vault (dev mode)..."
kubectl apply -f ../kubernetes/02-vault/

echo "⏱️  Aguardando Vault ficar pronto (60s)..."
sleep 60

echo "✅ Vault pronto!"
echo ""

echo "⏱️  ETAPA 6/11: Criando vault-token para ExternalSecrets..."
kubectl create secret generic vault-token \
  -n monitoring \
  --from-literal=token=vault-dev-root-token \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ vault-token criado!"
echo ""

echo "⏱️  ETAPA 7/11: Instalando External Secrets Operator..."
helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true
helm repo update

helm upgrade --install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets-system \
  --create-namespace \
  --wait

kubectl apply -f ../kubernetes/03-external-secrets/

echo "⏱️  Aguardando ExternalSecrets sincronizar (30s)..."
sleep 30

# Verificar se há erros de sincronização
if kubectl get externalsecrets -n monitoring | grep -q "SecretSyncedError"; then
    echo "⚠️  ExternalSecrets com erro, reiniciando ESO..."
    kubectl delete pod -n external-secrets-system -l app.kubernetes.io/name=external-secrets
    sleep 30
fi

echo "✅ External Secrets Operator instalado!"
echo ""

echo "⏱️  ETAPA 8/11: Deploy MySQL..."
kubectl apply -f ../kubernetes/05-mysql/

echo "⏱️  Aguardando MySQL ficar pronto (60s)..."
sleep 60

echo "✅ MySQL pronto!"
echo ""

echo "⏱️  ETAPA 9/11: Deploy Zabbix + Prometheus..."
kubectl apply -f ../kubernetes/06-zabbix/
kubectl apply -f ../kubernetes/07-prometheus/

echo "⏱️  Aguardando Zabbix e Prometheus ficarem prontos (90s)..."
sleep 90

echo "✅ Zabbix e Prometheus prontos!"
echo ""

echo "⏱️  ETAPA 10/11: Instalando Ingress Controller + Cert-Manager..."
echo ""
echo "   9.1: NGINX Ingress Controller (2-3 min)..."
kubectl apply -f ../kubernetes/08-ingress/01-ingress-controller.yaml

echo "⏱️  Aguardando Load Balancer ser criado (120s)..."
sleep 120

# Substituir domínio no ClusterIssuer
echo "   9.2: Cert-Manager (instalação oficial)..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

echo "⏱️  Aguardando Cert-Manager ficar pronto (60s)..."
sleep 60

# Verificar se pods do cert-manager estão prontos
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=120s 2>/dev/null || true

# Substituir email no ClusterIssuer
sed "s/seu-email@exemplo.com/$EMAIL/g" ../kubernetes/08-ingress/03-cluster-issuer.yaml | kubectl apply -f -

echo "   9.3: ClusterIssuer configurado!"
echo ""

# Aplicar Services ClusterIP (substitui NodePort)
echo "   9.4: Aplicando Services ClusterIP..."
kubectl apply -f ../kubernetes/08-ingress/services-clusterip/

# Substituir domínio no Ingress e aplicar
echo "   9.5: Configurando Ingress rules..."
sed "s/devopsproject.com.br/$DOMAIN/g" ../kubernetes/08-ingress/04-monitoring-ingress.yaml | kubectl apply -f -

echo "✅ Ingress Controller + Cert-Manager instalados!"
echo ""

echo "⏱️  ETAPA 11/11: Deploy Grafana e configuração final..."
kubectl apply -f ../kubernetes/08-grafana/
kubectl apply -f ../kubernetes/09-node-exporter/

echo "⏱️  Aguardando Grafana e Node Exporter ficarem prontos (60s)..."
sleep 60

# Configurar Zabbix
echo "🔧 Configurando Zabbix..."
../scripts/configure-zabbix-aws.sh

# Configurar Grafana
echo "🔧 Configurando Grafana..."
../scripts/configure-grafana-aws.sh

echo "✅ Configuração completa!"
echo ""

# Obter endereço do Load Balancer
echo "📡 Obtendo endereço do Load Balancer..."
echo ""
LB_ADDRESS=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -z "$LB_ADDRESS" ]; then
    echo "⚠️  Load Balancer ainda não tem endereço externo!"
    echo "   Execute: kubectl get svc -n ingress-nginx ingress-nginx-controller"
    echo ""
else
    echo "✅ Load Balancer criado:"
    echo "   $LB_ADDRESS"
    echo ""
fi

echo "════════════════════════════════════════════════════════"
echo "🎉 DEPLOY COMPLETO!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo ""
echo "1️⃣  CONFIGURAR DNS NO HOSTGATOR"
echo "   ────────────────────────────────────────────────"
echo "   Criar registros CNAME apontando para:"
echo "   $LB_ADDRESS"
echo ""
echo "   Registros necessários:"
echo "   grafana.$DOMAIN      → CNAME → Load Balancer"
echo "   zabbix.$DOMAIN       → CNAME → Load Balancer"
echo "   prometheus.$DOMAIN   → CNAME → Load Balancer"
echo "   eks.$DOMAIN          → CNAME → Load Balancer (opcional)"
echo ""
echo "2️⃣  AGUARDAR PROPAGAÇÃO DNS (5-30 minutos)"
echo "   ────────────────────────────────────────────────"
echo "   Testar: dig grafana.$DOMAIN"
echo "   Ou:     nslookup grafana.$DOMAIN"
echo ""
echo "3️⃣  AGUARDAR EMISSÃO DE CERTIFICADOS (2-5 minutos)"
echo "   ────────────────────────────────────────────────"
echo "   Verificar: kubectl get certificate -n monitoring"
echo "   Aguardar status: READY = True"
echo ""
echo "4️⃣  ACESSAR APLICAÇÕES VIA HTTPS"
echo "   ────────────────────────────────────────────────"
echo "   Grafana:    https://grafana.$DOMAIN"
echo "   Zabbix:     https://zabbix.$DOMAIN"
echo "   Prometheus: https://prometheus.$DOMAIN"
echo ""
echo "   🔐 Credenciais (geradas pelo Vault):"
echo "      # Grafana"
echo "      Usuário: admin"
echo "      Senha: kubectl get secret -n monitoring grafana-secret -o jsonpath='{.data.admin-password}' | base64 -d"
echo ""
echo "      # Zabbix"
echo "      Usuário: Admin"
echo "      Senha: kubectl get secret -n monitoring zabbix-secret -o jsonpath='{.data.admin-password}' | base64 -d"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "📊 COMANDOS ÚTEIS:"
echo ""
echo "   # Verificar status dos pods"
echo "   kubectl get pods -n monitoring"
echo ""
echo "   # Verificar Load Balancer"
echo "   kubectl get svc -n ingress-nginx"
echo ""
echo "   # Verificar certificados SSL"
echo "   kubectl get certificate -n monitoring"
echo "   kubectl describe certificate monitoring-tls-cert -n monitoring"
echo ""
echo "   # Logs do Cert-Manager (se certificado não for emitido)"
echo "   kubectl logs -n cert-manager deploy/cert-manager"
echo ""
echo "   # Logs do Ingress Controller"
echo "   kubectl logs -n ingress-nginx deploy/ingress-nginx-controller"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "💰 LEMBRETE: Este cluster tem CUSTO (~$0.46/hora)"
echo "   Execute ./cleanup-aws.sh quando terminar!"
echo ""
echo "════════════════════════════════════════════════════════"
