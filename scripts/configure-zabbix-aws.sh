#!/bin/bash

# 🔧 Script de configuração automática do Zabbix para AWS EKS
# Versão AWS do configure-zabbix.sh - faz EXATAMENTE a mesma coisa via port-forward

NAMESPACE="monitoring"
ZABBIX_USER="Admin"
ZABBIX_PASSWORD="ComplexP@ssw0rd__L5!@"
LOCAL_PORT=38080

echo "🔧 Configurando Zabbix Server automaticamente (AWS EKS)..."

# Criar port-forward em background
kubectl port-forward -n $NAMESPACE svc/zabbix-web $LOCAL_PORT:8080 > /dev/null 2>&1 &
PF_PID=$!
trap "kill $PF_PID 2>/dev/null || true" EXIT

# Aguardar Zabbix estar disponível
echo "⏳ Aguardando Zabbix estar disponível..."
sleep 5

until curl -s http://localhost:$LOCAL_PORT/api_jsonrpc.php >/dev/null 2>&1; do
    echo "   Aguardando Zabbix..."
    sleep 5
done

echo "✅ Zabbix disponível!"

# Fazer login e obter auth token
echo "🔑 Fazendo login no Zabbix API..."

AUTH_RESPONSE=$(curl -s -X POST http://localhost:$LOCAL_PORT/api_jsonrpc.php \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "user.login",
        "params": {
            "username": "'$ZABBIX_USER'",
            "password": "'$ZABBIX_PASSWORD'"
        },
        "id": 1
    }')

AUTH_TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

if [ -z "$AUTH_TOKEN" ]; then
    echo "❌ Erro ao fazer login no Zabbix API"
    echo "Resposta: $AUTH_RESPONSE"
    exit 1
fi

echo "✅ Login realizado com sucesso!"

# Buscar host "Zabbix server"
echo "🔍 Buscando host 'Zabbix server'..."

HOST_RESPONSE=$(curl -s -X POST http://localhost:$LOCAL_PORT/api_jsonrpc.php \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "host.get",
        "params": {
            "filter": {
                "host": ["Zabbix server"]
            }
        },
        "auth": "'$AUTH_TOKEN'",
        "id": 2
    }')

HOST_ID=$(echo "$HOST_RESPONSE" | grep -o '"hostid":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$HOST_ID" ]; then
    echo "❌ Host 'Zabbix server' não encontrado"
    exit 1
fi

echo "✅ Host encontrado (ID: $HOST_ID)"

# Buscar interface do host
echo "🔍 Buscando interface do host..."

INTERFACE_RESPONSE=$(curl -s -X POST http://localhost:$LOCAL_PORT/api_jsonrpc.php \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "hostinterface.get",
        "params": {
            "hostids": "'$HOST_ID'"
        },
        "auth": "'$AUTH_TOKEN'",
        "id": 3
    }')

INTERFACE_ID=$(echo "$INTERFACE_RESPONSE" | grep -o '"interfaceid":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$INTERFACE_ID" ]; then
    echo "❌ Interface não encontrada"
    exit 1
fi

echo "✅ Interface encontrada (ID: $INTERFACE_ID)"

# Alterar interface para usar DNS
echo "🔧 Configurando interface para usar DNS (zabbix-agent2-service)..."

UPDATE_INTERFACE=$(curl -s -X POST http://localhost:$LOCAL_PORT/api_jsonrpc.php \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "hostinterface.update",
        "params": {
            "interfaceid": "'$INTERFACE_ID'",
            "useip": 0,
            "dns": "zabbix-agent2-service",
            "port": "10050"
        },
        "auth": "'$AUTH_TOKEN'",
        "id": 4
    }')

if echo "$UPDATE_INTERFACE" | grep -q '"result"'; then
    echo "✅ Interface Agent configurada para usar DNS!"
    echo "   DNS: zabbix-agent2-service"
    echo "   Porta: 10050"
    echo "   Modo: Connect to DNS"
else
    echo "❌ Erro ao atualizar interface"
    echo "Resposta: $UPDATE_INTERFACE"
    exit 1
fi

# Buscar templates necessários
echo "🔍 Buscando templates..."
echo "ℹ️  ICMP Ping não suportado no Kubernetes (bloqueado por padrão)"

# Template Zabbix server health
TEMPLATE_HEALTH_RESPONSE=$(curl -s -X POST http://localhost:$LOCAL_PORT/api_jsonrpc.php \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "template.get",
        "params": {
            "filter": {
                "host": ["Zabbix server health"]
            }
        },
        "auth": "'$AUTH_TOKEN'",
        "id": 6
    }')

TEMPLATE_HEALTH_ID=$(echo "$TEMPLATE_HEALTH_RESPONSE" | grep -o '"templateid":"[^"]*"' | head -1 | cut -d'"' -f4)

# Template Linux by Zabbix agent active
TEMPLATE_LINUX_RESPONSE=$(curl -s -X POST http://localhost:$LOCAL_PORT/api_jsonrpc.php \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "template.get",
        "params": {
            "filter": {
                "host": ["Linux by Zabbix agent active"]
            }
        },
        "auth": "'$AUTH_TOKEN'",
        "id": 7
    }')

TEMPLATE_LINUX_ID=$(echo "$TEMPLATE_LINUX_RESPONSE" | grep -o '"templateid":"[^"]*"' | head -1 | cut -d'"' -f4)

# Verificar se todos os templates foram encontrados
if [ -z "$TEMPLATE_HEALTH_ID" ]; then
    echo "❌ Template 'Zabbix server health' não encontrado"
    exit 1
fi

if [ -z "$TEMPLATE_LINUX_ID" ]; then
    echo "❌ Template 'Linux by Zabbix agent active' não encontrado"
    exit 1
fi

echo "✅ Templates encontrados:"
echo "   • Zabbix server health (ID: $TEMPLATE_HEALTH_ID)"
echo "   • Linux by Zabbix agent active (ID: $TEMPLATE_LINUX_ID)"

# Aplicar templates ao host (sem ICMP Ping)
echo "📋 Aplicando templates ao host 'Zabbix server'..."

LINK_RESPONSE=$(curl -s -X POST http://localhost:$LOCAL_PORT/api_jsonrpc.php \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "host.update",
        "params": {
            "hostid": "'$HOST_ID'",
            "templates": [
                {
                    "templateid": "'$TEMPLATE_HEALTH_ID'"
                },
                {
                    "templateid": "'$TEMPLATE_LINUX_ID'"
                }
            ],
            "status": 0
        },
        "auth": "'$AUTH_TOKEN'",
        "id": 8
    }')

# Verificar resultado da aplicação dos templates
if echo "$LINK_RESPONSE" | grep -q '"result"'; then
    echo "✅ Templates aplicados com sucesso!"
    echo "📊 Templates ativos no host 'Zabbix server':"
    echo "   • Zabbix server health (saúde do servidor)"
    echo "   • Linux by Zabbix agent active (métricas do sistema)"
else
    echo "❌ Erro ao aplicar templates"
    echo "Resposta: $LINK_RESPONSE"
    exit 1
fi

echo ""
echo "🎉 Configuração completa!"
echo "📋 Verificar em: Configuration → Hosts → Zabbix server"
echo "   Interface: Agent zabbix-agent2-service Connect to DNS"
echo "   Templates aplicados:"
echo "   • Zabbix server health (saúde do servidor)"
echo "   • Linux by Zabbix agent active (métricas do sistema)"
echo ""
echo "ℹ️  Template ICMP Ping NÃO aplicado (ICMP bloqueado no Kubernetes)"
echo "📊 Aguarde alguns minutos para coleta de dados começar..."
