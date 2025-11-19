#!/bin/bash

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║       🔐 CREDENCIAIS DE ACESSO - LEVEL 5                 ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Configurar acesso ao Vault
export VAULT_ADDR='http://localhost:8200'
export VAULT_TOKEN='vault-dev-root-token'

# Port-forward se necessário
if ! curl -s http://localhost:8200/v1/sys/health >/dev/null 2>&1; then
    echo "⚠️  Vault não acessível em localhost:8200"
    echo "   Criando port-forward..."
    kubectl port-forward -n monitoring svc/vault 8200:8200 >/dev/null 2>&1 &
    PF_PID=$!
    sleep 3
    trap "kill $PF_PID 2>/dev/null" EXIT
fi

echo "📊 ZABBIX WEB"
echo "   URL: http://localhost:30080"
echo "   Usuário: Admin"
ZABBIX_PASS=$(kubectl exec -n monitoring vault-0 -- sh -c 'export VAULT_TOKEN=vault-dev-root-token && vault kv get -field=admin-password secret/zabbix' 2>/dev/null || echo "ComplexP@ssw0rd__L5!@")
echo "   Senha: $ZABBIX_PASS"
echo ""

echo "📈 GRAFANA"
echo "   URL: http://localhost:30300"
echo "   Usuário: admin"
GRAFANA_PASS=$(kubectl exec -n monitoring vault-0 -- sh -c 'export VAULT_TOKEN=vault-dev-root-token && vault kv get -field=admin-password secret/grafana' 2>/dev/null || echo "K8s_Grafana__Vault2024!@")
echo "   Senha: $GRAFANA_PASS"
echo ""

echo "📉 PROMETHEUS"
echo "   URL: http://localhost:30900"
echo "   (Sem autenticação configurada)"
echo ""

echo "💾 MYSQL (uso interno)"
MYSQL_ROOT=$(kubectl exec -n monitoring vault-0 -- sh -c 'export VAULT_TOKEN=vault-dev-root-token && vault kv get -field=root-password secret/mysql' 2>/dev/null || echo "❌ Erro")
echo "   Root: $MYSQL_ROOT"
echo ""

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  ⚠️  IMPORTANTE: Guarde estas credenciais com segurança!  ║"
echo "║                                                           ║"
echo "║  Para ver novamente: ./scripts/show-credentials.sh       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
