#!/bin/bash

# Script para monitorar deploy em tempo real
# Execute em outro terminal durante o deploy

NAMESPACE="monitoring"

echo "🔍 Monitoramento em Tempo Real - AWS EKS"
echo "=========================================="
echo ""
echo "📊 Atualizando a cada 5 segundos..."
echo "📌 Pressione Ctrl+C para sair"
echo ""

while true; do
    clear
    
    echo "🔍 MONITORAMENTO AWS EKS - $(date '+%H:%M:%S')"
    echo "=================================================="
    echo ""
    
    # Nodes
    echo "📦 NODES DO CLUSTER:"
    kubectl get nodes 2>/dev/null || echo "   ⏳ Aguardando cluster..."
    echo ""
    
    # Pods
    echo "🚀 PODS (namespace: $NAMESPACE):"
    if kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
        kubectl get pods -n $NAMESPACE 2>/dev/null | grep -v "NAME" | while read line; do
            pod_name=$(echo $line | awk '{print $1}')
            status=$(echo $line | awk '{print $3}')
            
            # Colorir por status
            case $status in
                Running)
                    echo "   ✅ $line"
                    ;;
                Completed)
                    echo "   ✅ $line"
                    ;;
                ContainerCreating|PodInitializing|Pending)
                    echo "   ⏳ $line"
                    ;;
                Error|CrashLoopBackOff|ImagePullBackOff)
                    echo "   ❌ $line"
                    ;;
                *)
                    echo "   🔄 $line"
                    ;;
            esac
        done
        
        # Contar pods por status
        total=$(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
        running=$(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | grep -c "Running")
        completed=$(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | grep -c "Completed")
        errors=$(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | grep -cE "Error|CrashLoop|ImagePull")
        
        echo ""
        echo "   📊 Total: $total | Running: $running | Completed: $completed | Errors: $errors"
    else
        echo "   ⏳ Namespace $NAMESPACE ainda não criado"
    fi
    
    echo ""
    
    # ExternalSecrets
    echo "🔐 EXTERNAL SECRETS:"
    if kubectl get externalsecrets -n $NAMESPACE >/dev/null 2>&1; then
        kubectl get externalsecrets -n $NAMESPACE --no-headers 2>/dev/null | while read line; do
            name=$(echo $line | awk '{print $1}')
            status=$(echo $line | awk '{print $4}')
            
            if [ "$status" = "True" ]; then
                echo "   ✅ $line"
            else
                echo "   ⏳ $line"
            fi
        done
    else
        echo "   ⏳ Ainda não criados"
    fi
    
    echo ""
    
    # PVCs
    echo "💾 PERSISTENT VOLUMES:"
    if kubectl get pvc -n $NAMESPACE >/dev/null 2>&1; then
        kubectl get pvc -n $NAMESPACE --no-headers 2>/dev/null | while read line; do
            status=$(echo $line | awk '{print $2}')
            
            if [ "$status" = "Bound" ]; then
                echo "   ✅ $line"
            else
                echo "   ⏳ $line"
            fi
        done
    else
        echo "   ⏳ Ainda não criados"
    fi
    
    echo ""
    
    # Logs recentes de erros
    echo "📋 ÚLTIMOS EVENTOS (erros/warnings):"
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' 2>/dev/null | \
        grep -iE "error|warning|failed" | tail -5 | \
        sed 's/^/   ⚠️  /' || echo "   ✅ Nenhum erro recente"
    
    echo ""
    echo "=================================================="
    echo "🔄 Próxima atualização em 5s... (Ctrl+C para sair)"
    
    sleep 5
done
