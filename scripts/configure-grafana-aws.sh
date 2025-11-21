#!/bin/bash

# 🔧 Script de configuração automática do Grafana para AWS EKS
# Versão AWS do configure-grafana.sh - faz EXATAMENTE a mesma coisa via port-forward

NAMESPACE="monitoring"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="K8s_Grafana__Vault2024!@"
LOCAL_PORT=33000

echo "🔧 Configurando Grafana automaticamente (AWS EKS)..."

# Criar port-forward em background
kubectl port-forward -n $NAMESPACE svc/grafana $LOCAL_PORT:3000 > /dev/null 2>&1 &
PF_PID=$!
trap "kill $PF_PID 2>/dev/null || true" EXIT

# Aguardar Grafana estar disponível
echo "⏳ Aguardando Grafana estar disponível..."
sleep 5

until curl -s http://localhost:$LOCAL_PORT/api/health >/dev/null 2>&1; do
    echo "   Aguardando Grafana..."
    sleep 5
done

echo "✅ Grafana disponível!"

# Configurar credenciais
AUTH="$GRAFANA_USER:$GRAFANA_PASSWORD"

# ========== ETAPA 1: Datasource Prometheus ==========
echo "📊 Configurando datasource Prometheus..."

PROMETHEUS_DS_JSON='{
  "name": "Prometheus",
  "type": "prometheus",
  "access": "proxy",
  "url": "http://prometheus.monitoring.svc.cluster.local:9090",
  "basicAuth": false,
  "isDefault": false,
  "jsonData": {
    "timeInterval": "5s",
    "queryTimeout": "60s",
    "httpMethod": "POST"
  }
}'

PROMETHEUS_RESPONSE=$(curl -s -X POST http://localhost:$LOCAL_PORT/api/datasources \
    -u "$AUTH" \
    -H "Content-Type: application/json" \
    -d "$PROMETHEUS_DS_JSON")

if echo "$PROMETHEUS_RESPONSE" | grep -q '"id"'; then
    PROMETHEUS_DS_ID=$(echo "$PROMETHEUS_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    echo "✅ Datasource Prometheus criado! (ID: $PROMETHEUS_DS_ID)"
elif echo "$PROMETHEUS_RESPONSE" | grep -q '"message":"Data source with the same name already exists"'; then
    echo "ℹ️  Datasource Prometheus já existe"
else
    echo "⚠️  Aviso ao criar datasource Prometheus"
    echo "Resposta: $PROMETHEUS_RESPONSE"
fi

# ========== ETAPA 2: Datasource Zabbix ==========
echo "📊 Configurando datasource Zabbix..."

ZABBIX_DS_JSON='{
  "name": "Zabbix",
  "type": "alexanderzobnin-zabbix-datasource",
  "access": "proxy",
  "url": "http://zabbix-web.monitoring.svc.cluster.local:8080/api_jsonrpc.php",
  "basicAuth": false,
  "isDefault": true,
  "jsonData": {
    "username": "Admin",
    "trends": true,
    "trendsFrom": "7d",
    "trendsRange": "4d"
  },
  "secureJsonData": {
    "password": "ComplexP@ssw0rd__L5!@"
  }
}'

ZABBIX_RESPONSE=$(curl -s -X POST http://localhost:$LOCAL_PORT/api/datasources \
    -u "$AUTH" \
    -H "Content-Type: application/json" \
    -d "$ZABBIX_DS_JSON")

if echo "$ZABBIX_RESPONSE" | grep -q '"uid"'; then
    ZABBIX_DS_UID=$(echo "$ZABBIX_RESPONSE" | grep -o '"uid":"[^"]*"' | head -1 | cut -d'"' -f4)
    ZABBIX_DS_ID=$(echo "$ZABBIX_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    echo "✅ Datasource Zabbix criado! (ID: $ZABBIX_DS_ID, UID: $ZABBIX_DS_UID)"
elif echo "$ZABBIX_RESPONSE" | grep -q '"message":"Data source with the same name already exists"'; then
    echo "ℹ️  Datasource Zabbix já existe, buscando UID..."
    
    # Buscar UID do datasource existente
    EXISTING_DS=$(curl -s http://localhost:$LOCAL_PORT/api/datasources/name/Zabbix -u "$AUTH")
    ZABBIX_DS_UID=$(echo "$EXISTING_DS" | grep -o '"uid":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "   UID encontrado: $ZABBIX_DS_UID"
else
    echo "⚠️  Aviso ao criar datasource Zabbix"
    echo "Resposta: $ZABBIX_RESPONSE"
fi

# ========== ETAPA 3: Importar Dashboards ==========
echo "📊 Importando dashboards personalizados..."

# Diretório dos dashboards
DASHBOARDS_DIR="/home/luiz7/monitoring-security-level5/grafana/dashboards"

if [ ! -d "$DASHBOARDS_DIR" ]; then
    echo "❌ Diretório de dashboards não encontrado: $DASHBOARDS_DIR"
    exit 1
fi

# Contador de dashboards importados
IMPORTED_COUNT=0

# Processar cada dashboard JSON
for DASHBOARD_FILE in "$DASHBOARDS_DIR"/*.json; do
    if [ ! -f "$DASHBOARD_FILE" ]; then
        continue
    fi
    
    DASHBOARD_NAME=$(basename "$DASHBOARD_FILE")
    echo "📄 Processando: $DASHBOARD_NAME"
    
    # Ler conteúdo do dashboard
    DASHBOARD_CONTENT=$(cat "$DASHBOARD_FILE")
    
    # Substituir UIDs antigos pelo UID real do datasource Zabbix (se tiver)
    if [ ! -z "$ZABBIX_DS_UID" ]; then
        # Substituir placeholder padrão
        DASHBOARD_CONTENT=$(echo "$DASHBOARD_CONTENT" | sed "s/PA67C5EADE9207728/$ZABBIX_DS_UID/g")
        # Substituir UID antigo de deploy anterior (se existir)
        DASHBOARD_CONTENT=$(echo "$DASHBOARD_CONTENT" | sed "s/bd1254e1-49d4-4b8a-88ac-c765639245a3/$ZABBIX_DS_UID/g")
    fi
    
    # Remover IDs hardcoded e UIDs antigos (deixar Grafana gerar novos)
    # Usar arquivo temporário para evitar "Argument list too long"
    TEMP_FILE=$(mktemp)
    echo "$DASHBOARD_CONTENT" | sed 's/"id":[0-9]*,//g; s/"uid":"[^"]*",//g' > "$TEMP_FILE"
    
    # Preparar JSON para importação
    IMPORT_JSON=$(cat <<EOF
{
  "dashboard": $(cat "$TEMP_FILE"),
  "overwrite": true,
  "inputs": [],
  "folderId": 0
}
EOF
)
    
    # Salvar em arquivo temporário para importação
    IMPORT_FILE=$(mktemp)
    echo "$IMPORT_JSON" > "$IMPORT_FILE"
    
    # Importar dashboard
    IMPORT_RESPONSE=$(curl -s -X POST http://localhost:$LOCAL_PORT/api/dashboards/db \
        -u "$AUTH" \
        -H "Content-Type: application/json" \
        -d @"$IMPORT_FILE")
    
    # Verificar resultado
    if echo "$IMPORT_RESPONSE" | grep -q '"status":"success"'; then
        DASHBOARD_UID=$(echo "$IMPORT_RESPONSE" | grep -o '"uid":"[^"]*"' | head -1 | cut -d'"' -f4)
        echo "   ✅ Dashboard importado! (UID: $DASHBOARD_UID)"
        IMPORTED_COUNT=$((IMPORTED_COUNT + 1))
    elif echo "$IMPORT_RESPONSE" | grep -q '"message":"Dashboard already exists"'; then
        echo "   ℹ️  Dashboard já existe"
        IMPORTED_COUNT=$((IMPORTED_COUNT + 1))
    else
        echo "   ⚠️  Aviso ao importar dashboard"
        echo "   Resposta: $IMPORT_RESPONSE"
    fi
    
    # Limpar arquivos temporários
    rm -f "$TEMP_FILE" "$IMPORT_FILE"
done

echo ""
echo "🎉 Configuração completa!"
echo "📊 Resumo:"
echo "   • Datasources: Prometheus + Zabbix (alexanderzobnin plugin)"
echo "   • Dashboards importados: $IMPORTED_COUNT"
echo "   • Zabbix definido como datasource padrão"
echo ""
echo "🌐 Acesse Grafana em: http://localhost:3000"
echo "   Login: admin"
echo "   Password: K8s_Grafana__Vault2024!@"
echo ""
echo "📈 Dashboards disponíveis:"
echo "   • Zabbix Overview (visão geral do monitoramento)"
echo "   • Node Exporter (métricas detalhadas dos nodes)"
echo ""
echo "ℹ️  UID placeholder substituído: PA67C5EADE9207728 → $ZABBIX_DS_UID"
echo "📊 Os dashboards já estão conectados aos datasources corretos!"
