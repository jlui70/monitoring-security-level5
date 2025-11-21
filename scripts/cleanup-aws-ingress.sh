#!/bin/bash

# Script de Cleanup AWS EKS com Ingress - Remove todos os recursos criados
# IMPORTANTE: Execute este script para evitar custos contínuos!

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo -e "${RED}⚠️  CLEANUP AWS EKS + INGRESS - ATENÇÃO!${NC}"
echo "=========================================="
echo ""

# Ir para diretório raiz do projeto
cd "$(dirname "$0")/.."

# Carregar informações do cluster
if [ -f "aws-cluster-info.txt" ]; then
    CLUSTER_NAME=$(grep "^CLUSTER_NAME=" aws-cluster-info.txt | cut -d'=' -f2)
    REGION=$(grep "^REGION=" aws-cluster-info.txt | cut -d'=' -f2)
    DOMAIN=$(grep "^DOMAIN=" aws-cluster-info.txt | cut -d'=' -f2 2>/dev/null || echo "N/A")
    CREATED_AT=$(grep "^CREATED_AT=" aws-cluster-info.txt | cut -d'=' -f2-)
    
    echo "📋 Cluster encontrado:"
    echo "   Nome: $CLUSTER_NAME"
    echo "   Region: $REGION"
    echo "   Domínio: $DOMAIN"
    echo "   Criado em: $CREATED_AT"
else
    echo "❌ Arquivo aws-cluster-info.txt não encontrado!"
    echo ""
    read -p "Nome do cluster: " CLUSTER_NAME
    read -p "Region (us-east-1): " REGION
    REGION=${REGION:-us-east-1}
fi

echo ""
echo -e "${YELLOW}Este script vai DELETAR:${NC}"
echo "  ❌ Ingress Controller + Network Load Balancer"
echo "  ❌ Cert-Manager + certificados SSL"
echo "  ❌ Namespace monitoring (Vault, MySQL, Zabbix, Grafana, Prometheus)"
echo "  ❌ Cluster EKS: $CLUSTER_NAME"
echo "  ❌ Todos os nodes"
echo "  ❌ Todos os volumes EBS"
echo "  ❌ IAM roles criados"
echo ""
echo "💰 Isso vai PARAR os custos de ~$0.46/hora (~$330/mês)"
echo ""

read -p "Confirma DELETAR todos os recursos? (sim/NAO): " confirm
if [ "$confirm" != "sim" ]; then
    echo -e "${GREEN}❌ Cancelado. Nada foi deletado.${NC}"
    echo ""
    echo "⚠️  O cluster continua rodando e gerando custos!"
    exit 0
fi

echo ""
echo "⏱️  Iniciando cleanup..."
echo ""

# ETAPA 1: Deletar Ingress Controller (deleta o Load Balancer)
echo "🗑️  ETAPA 1/7: Deletando Ingress Controller..."
kubectl delete -f kubernetes/08-ingress/01-ingress-controller.yaml 2>/dev/null || echo "   Já foi removido"

echo "   ⏱️  Aguardando Load Balancer ser removido pela AWS (120s)..."
sleep 120

echo "   ✅ Ingress Controller deletado"

# ETAPA 2: Deletar Cert-Manager
echo ""
echo "🗑️  ETAPA 2/7: Deletando Cert-Manager..."
kubectl delete -f kubernetes/08-ingress/02-cert-manager.yaml 2>/dev/null || echo "   Já foi removido"
kubectl delete namespace cert-manager --timeout=60s 2>/dev/null || echo "   Namespace já foi removido"

echo "   ✅ Cert-Manager deletado"

# ETAPA 3: Deletar namespace ingress-nginx
echo ""
echo "🗑️  ETAPA 3/7: Deletando namespace ingress-nginx..."
kubectl delete namespace ingress-nginx --timeout=60s 2>/dev/null || echo "   Já foi removido"

# ETAPA 4: Deletar namespace monitoring (remove PVCs)
echo ""
echo "🗑️  ETAPA 4/7: Deletando namespace monitoring..."
kubectl delete namespace monitoring --timeout=120s 2>/dev/null || echo "   Namespace já foi removido"

# ETAPA 5: Deletar External Secrets Operator
echo ""
echo "🗑️  ETAPA 5/7: Deletando External Secrets Operator..."
kubectl delete namespace external-secrets-system --timeout=60s 2>/dev/null || echo "   Já foi removido"

# Aguardar volumes EBS serem liberados
echo "   ⏱️  Aguardando volumes EBS serem liberados (30s)..."
sleep 30

# ETAPA 6: Deletar cluster EKS
echo ""
echo "🗑️  ETAPA 6/7: Deletando cluster EKS (10-15 min)..."
echo "   Cluster: $CLUSTER_NAME"
echo "   Region: $REGION"
echo ""

eksctl delete cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --wait

if [ $? -ne 0 ]; then
    echo ""
    echo -e "${RED}❌ Erro ao deletar cluster!${NC}"
    echo ""
    echo "Tente manualmente:"
    echo "  eksctl delete cluster --name $CLUSTER_NAME --region $REGION"
    echo ""
    echo "Ou via console AWS:"
    echo "  https://console.aws.amazon.com/eks/home?region=$REGION#/clusters/$CLUSTER_NAME"
    exit 1
fi

# ETAPA 7: Verificar volumes EBS órfãos
echo ""
echo "🔍 ETAPA 7/7: Verificando volumes EBS órfãos..."

ORPHAN_VOLUMES=$(aws ec2 describe-volumes \
  --region $REGION \
  --filters "Name=tag:kubernetes.io/cluster/$CLUSTER_NAME,Values=owned" \
  --query 'Volumes[?State==`available`].VolumeId' \
  --output text 2>/dev/null || echo "")

if [ ! -z "$ORPHAN_VOLUMES" ]; then
    echo -e "${YELLOW}⚠️  Volumes EBS órfãos encontrados:${NC}"
    echo "$ORPHAN_VOLUMES"
    echo ""
    read -p "Deletar volumes órfãos? (s/N): " delete_volumes
    if [ "$delete_volumes" = "s" ] || [ "$delete_volumes" = "S" ]; then
        for vol in $ORPHAN_VOLUMES; do
            echo "   Deletando volume: $vol"
            aws ec2 delete-volume --volume-id $vol --region $REGION
        done
        echo "   ✅ Volumes deletados"
    else
        echo -e "${YELLOW}   ⚠️  Volumes não deletados. Custos: ~$0.10/GB/mês${NC}"
    fi
else
    echo "   ✅ Nenhum volume órfão encontrado"
fi

# Limpar arquivo de configuração
echo ""
echo "🗑️  Removendo arquivo de configuração local..."
if [ -f "aws-cluster-info.txt" ]; then
    mv aws-cluster-info.txt aws-cluster-info-deleted-$(date +%Y%m%d-%H%M%S).txt
    echo "   ✅ Arquivo renomeado (backup)"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ CLEANUP COMPLETO!${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Recursos removidos:"
echo "   ✅ Network Load Balancer"
echo "   ✅ Ingress Controller (NGINX)"
echo "   ✅ Cert-Manager + certificados SSL"
echo "   ✅ Cluster EKS: $CLUSTER_NAME"
echo "   ✅ Nodes EC2"
echo "   ✅ Volumes EBS"
echo "   ✅ IAM roles"
echo ""
if [ "$DOMAIN" != "N/A" ]; then
    echo "🌐 LEMBRETE DNS:"
    echo "   Você pode REMOVER os registros CNAME no HostGator:"
    echo "   - grafana.$DOMAIN"
    echo "   - zabbix.$DOMAIN"
    echo "   - prometheus.$DOMAIN"
    echo "   - eks.$DOMAIN"
    echo ""
fi
echo "💰 Custos AWS: ZERADOS!"
echo ""
echo "════════════════════════════════════════════════════════"
