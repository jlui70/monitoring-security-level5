#!/bin/bash

set -e

echo "🧹 Limpeza Total do Ambiente"
echo "=============================="
echo ""

# Deletar cluster Kind
if kind get clusters 2>/dev/null | grep -q "^kind$"; then
    echo "🗑️  Deletando cluster Kind..."
    kind delete cluster
    echo "✅ Cluster deletado"
else
    echo "ℹ️  Cluster Kind não encontrado"
fi

# Limpar containers Docker órfãos
echo "🧹 Limpando containers Docker órfãos..."
docker ps -aq --filter "name=kind" | xargs -r docker rm -f 2>/dev/null || true

# Limpar volumes Docker órfãos do Kind
echo "🗑️  Limpando volumes Docker do Kind..."
docker volume ls -q | grep -E '^[a-f0-9]{64}$|kind' | xargs -r docker volume rm 2>/dev/null || true

# Limpar diretórios do Kind no sistema (pode conter dados corrompidos)
echo "🗑️  Limpando diretórios locais do Kind..."
sudo rm -rf /tmp/kind-* 2>/dev/null || true
sudo rm -rf /var/lib/kind 2>/dev/null || true
rm -rf ~/.kube/kind-* 2>/dev/null || true

# Limpar contexto kubectl
echo "🧹 Limpando contexto kubectl..."
kubectl config delete-context kind-kind 2>/dev/null || true
kubectl config delete-cluster kind-kind 2>/dev/null || true
kubectl config unset users.kind-kind 2>/dev/null || true

echo ""
echo "✅ Limpeza concluída!"
echo ""
echo "Para fazer novo deployment:"
echo "  ./scripts/deploy.sh"
echo ""
