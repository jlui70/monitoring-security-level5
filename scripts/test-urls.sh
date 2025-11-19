#!/bin/bash

echo "🧪 Testando URLs do Monitoring Stack..."
echo ""

test_url() {
    local url=$1
    local name=$2
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response" = "200" ] || [ "$response" = "302" ]; then
        echo "✅ $name: $url (HTTP $response)"
    else
        echo "❌ $name: $url (HTTP $response)"
    fi
}

test_url "http://localhost:30080" "Zabbix Web"
test_url "http://localhost:30300" "Grafana"
test_url "http://localhost:30900" "Prometheus"

echo ""
echo "📊 Status dos Pods:"
kubectl get pods -n monitoring

echo ""
echo "🔐 Status dos ExternalSecrets:"
kubectl get externalsecrets -n monitoring
