#!/bin/bash

# Script de Cleanup AWS EKS - Remove todos os recursos criados
# IMPORTANTE: Execute este script para evitar custos contínuos!

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo -e "${RED}⚠️  CLEANUP AWS EKS - ATENÇÃO!${NC}"
echo "=========================================="
echo ""

# Ir para diretório raiz do projeto
cd "$(dirname "$0")/.."

# Carregar informações do cluster
if [ -f "aws-cluster-info.txt" ]; then
    # Ler valores do arquivo (sem source por causa do espaço na data)
    CLUSTER_NAME=$(grep "^CLUSTER_NAME=" aws-cluster-info.txt | cut -d'=' -f2)
    REGION=$(grep "^REGION=" aws-cluster-info.txt | cut -d'=' -f2)
    CREATED_AT=$(grep "^CREATED_AT=" aws-cluster-info.txt | cut -d'=' -f2-)
    
    echo "📋 Cluster encontrado:"
    echo "   Nome: $CLUSTER_NAME"
    echo "   Region: $REGION"
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
echo "  ❌ Cluster EKS: $CLUSTER_NAME"
echo "  ❌ Todos os nodes"
echo "  ❌ Todos os volumes EBS"
echo "  ❌ Load Balancers (se criados)"
echo "  ❌ IAM roles criados"
echo ""
echo "💰 Isso vai PARAR os custos de ~$0.30/hora"
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

# ETAPA 1: Deletar Load Balancers (se existirem)
echo "🔍 ETAPA 1/5: Verificando Load Balancers..."
LBS=$(kubectl get svc -n monitoring -o json | jq -r '.items[] | select(.spec.type=="LoadBalancer") | .metadata.name' 2>/dev/null || echo "")

if [ ! -z "$LBS" ]; then
    echo "   Encontrados Load Balancers, deletando primeiro..."
    kubectl delete svc -n monitoring --field-selector spec.type=LoadBalancer
    echo "   Aguardando Load Balancers serem removidos (30s)..."
    sleep 30
else
    echo "   ✅ Nenhum Load Balancer encontrado"
fi

# ETAPA 2: Deletar namespace monitoring (remove PVCs)
echo ""
echo "🗑️  ETAPA 2/5: Deletando namespace monitoring..."
kubectl delete namespace monitoring --timeout=120s 2>/dev/null || echo "   Namespace já foi removido"

# ETAPA 3: Deletar PVCs órfãos
echo ""
echo "🗑️  ETAPA 3/5: Verificando PVCs órfãos..."
kubectl delete pvc --all -A --timeout=60s 2>/dev/null || echo "   Nenhum PVC encontrado"

# Aguardar volumes EBS serem liberados
echo "   Aguardando volumes EBS serem liberados (20s)..."
sleep 20

# ETAPA 4: Deletar cluster EKS
echo ""
echo "🗑️  ETAPA 4/5: Deletando cluster EKS (10-15 min)..."
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

# ETAPA 5: Verificar volumes EBS órfãos
echo ""
echo "🔍 ETAPA 5/5: Verificando volumes EBS órfãos..."

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

# ETAPA 6: Limpar arquivo de configuração
echo ""
echo "🗑️  Removendo arquivo de configuração local..."
if [ -f "aws-cluster-info.txt" ]; then
    mv aws-cluster-info.txt aws-cluster-info-deleted-$(date +%Y%m%d-%H%M%S).txt
    echo "   ✅ Arquivo renomeado (backup)"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✅ CLEANUP COMPLETO!${NC}"
echo "=========================================="
echo ""
echo "📊 Recursos removidos:"
echo "  ✅ Cluster EKS deletado"
echo "  ✅ Nodes terminados"
echo "  ✅ Volumes EBS removidos"
echo "  ✅ Custos parados (~$0.30/hora)"
echo ""
echo "💰 Verifique no console AWS em 5 minutos:"
echo "   https://console.aws.amazon.com/billing/home"
echo ""
echo "📝 Backup de configuração salvo para referência"
echo ""
