#!/bin/bash

# 📊 Script de importação de dashboards para Grafana
# Importa dashboards iniciais mas deixa eles editáveis (não provisionados)

GRAFANA_USER="admin"

# Obter senha do Vault
GRAFANA_PASS=$(kubectl exec -n monitoring vault-0 -- sh -c 'export VAULT_TOKEN=vault-dev-root-token && vault kv get -field=admin-password secret/grafana' 2>/dev/null || echo "K8s_GrafanaAdmin_Vault_2025!@#")

echo "📊 Importando dashboards iniciais para o Grafana..."
echo "🔐 Usando senha obtida do Vault..."

# Aguardar Grafana estar disponível
echo "⏳ Aguardando Grafana estar disponível..."
until curl -s http://localhost:30300/api/health >/dev/null 2>&1; do
    echo "   Aguardando Grafana..."
    sleep 5
done

echo "✅ Grafana disponível!"

# Configurar datasources se necessário
echo "🔗 Configurando datasources..."

# Verificar se Prometheus já existe
PROMETHEUS_EXISTS=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASS" http://localhost:30300/api/datasources/name/Prometheus 2>/dev/null | grep -o '"name":"Prometheus"' || echo "")

if [ -z "$PROMETHEUS_EXISTS" ]; then
    echo "📈 Adicionando datasource Prometheus..."
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        http://localhost:30300/api/datasources \
        -d '{
            "name": "Prometheus",
            "type": "prometheus",
            "url": "http://prometheus.monitoring.svc.cluster.local:9090",
            "access": "proxy",
            "isDefault": false
        }' >/dev/null
    echo "✅ Prometheus adicionado!"
else
    echo "✅ Prometheus já configurado!"
fi

# Verificar se Zabbix já existe
ZABBIX_EXISTS=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASS" http://localhost:30300/api/datasources/name/Zabbix 2>/dev/null | grep -o '"name":"Zabbix"' || echo "")

# Obter senha do Zabbix Admin do Vault
ZABBIX_ADMIN_PASS=$(kubectl exec -n monitoring vault-0 -- sh -c 'export VAULT_TOKEN=vault-dev-root-token && vault kv get -field=admin-password secret/zabbix' 2>/dev/null || echo "ComplexP@ssw0rd__L5!@")

if [ -z "$ZABBIX_EXISTS" ]; then
    echo "🎯 Adicionando datasource Zabbix..."
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        http://localhost:30300/api/datasources \
        -d '{
            "name": "Zabbix",
            "type": "alexanderzobnin-zabbix-datasource",
            "url": "http://zabbix-web.monitoring.svc.cluster.local:8080/api_jsonrpc.php",
            "access": "proxy",
            "isDefault": true,
            "jsonData": {
                "username": "Admin",
                "trends": true,
                "trendsFrom": "7d",
                "cacheTTL": "1h",
                "timeout": 60
            },
            "secureJsonData": {
                "password": "'"$ZABBIX_ADMIN_PASS"'"
            }
        }' >/dev/null
    echo "✅ Zabbix adicionado!"
else
    echo "✅ Zabbix já configurado!"
    echo "🔄 Atualizando senha do datasource Zabbix..."
    
    # Obter ID do datasource
    ZABBIX_ID=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASS" http://localhost:30300/api/datasources/name/Zabbix 2>/dev/null | grep -o '"id":[0-9]*' | cut -d':' -f2)
    
    if [ -n "$ZABBIX_ID" ]; then
        curl -s -X PUT \
            -H "Content-Type: application/json" \
            -u "$GRAFANA_USER:$GRAFANA_PASS" \
            http://localhost:30300/api/datasources/$ZABBIX_ID \
            -d '{
                "name": "Zabbix",
                "type": "alexanderzobnin-zabbix-datasource",
                "url": "http://zabbix-web.monitoring.svc.cluster.local:8080/api_jsonrpc.php",
                "access": "proxy",
                "isDefault": true,
                "jsonData": {
                    "username": "Admin",
                    "trends": true,
                    "trendsFrom": "7d",
                    "cacheTTL": "1h",
                    "timeout": 60
                },
                "secureJsonData": {
                    "password": "'"$ZABBIX_ADMIN_PASS"'"
                }
            }' >/dev/null
        echo "✅ Senha atualizada!"
    fi
fi

# Importar dashboards
echo "📋 Importando dashboards..."

DASHBOARD_DIR="/home/luiz7/monitoring-security-level5/grafana/dashboards"

if [ ! -d "$DASHBOARD_DIR" ]; then
    echo "⚠️  Pasta de dashboards não encontrada: $DASHBOARD_DIR"
    echo "📝 Nenhum dashboard para importar"
    exit 0
fi

for dashboard_file in "$DASHBOARD_DIR"/*.json; do
    if [ -f "$dashboard_file" ]; then
        dashboard_name=$(basename "$dashboard_file" .json)
        echo "📊 Importando dashboard: $dashboard_name"
        
        # Descobrir UID do datasource Zabbix
        ZABBIX_UID=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASS" "http://localhost:30300/api/datasources" | grep -o '"uid":"[^"]*"[^}]*"type":"alexanderzobnin-zabbix-datasource"' | grep -o '"uid":"[^"]*"' | cut -d'"' -f4)
        
        if [ -z "$ZABBIX_UID" ]; then
            echo "   ⚠️  Não foi possível descobrir UID do datasource Zabbix, usando dashboard original"
            dashboard_content=$(cat "$dashboard_file")
        else
            echo "   UID Zabbix detectado: $ZABBIX_UID"
            # Substituir UID hardcoded pelo UID real e remover id/uid do dashboard
            dashboard_content=$(cat "$dashboard_file" | sed "s/PA67C5EADE9207728/$ZABBIX_UID/g" | sed 's/"id":[0-9]*,//g; s/"uid":"[^"]*",//g')
        fi
        
        # Criar payload temporário para evitar "Argument list too long"
        temp_payload="/tmp/dashboard_payload_$$.json"
        echo "{" > "$temp_payload"
        echo "\"dashboard\": $dashboard_content," >> "$temp_payload"
        echo "\"overwrite\": true" >> "$temp_payload"
        echo "}" >> "$temp_payload"
        
        # Importar dashboard usando arquivo temporário
        curl -s -X POST \
            -H "Content-Type: application/json" \
            -u "$GRAFANA_USER:$GRAFANA_PASS" \
            http://localhost:30300/api/dashboards/db \
            -d @"$temp_payload" >/dev/null
        
        # Limpar arquivo temporário
        rm -f "$temp_payload"
        
        echo "✅ Dashboard $dashboard_name importado!"
    fi
done

echo ""
echo "🎉 Configuração completa!"
echo "📊 Dashboards importados e totalmente editáveis!"
echo "🔗 Acesse: http://localhost:30300 (${GRAFANA_USER}/${GRAFANA_PASS})"
echo ""
echo "💡 Dashboards disponíveis:"
echo "   • Node Exporter (métricas Prometheus)"
echo "   • Zabbix Overview (métricas Zabbix)"
