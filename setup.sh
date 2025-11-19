#!/bin/bash

# 🚀 Setup completo - Monitoring Security Level 5
# Kubernetes + HashiCorp Vault + External Secrets Operator

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     🚀 Monitoring Security Evolution - Level 5 Setup          ║"
echo "║     Kubernetes + Vault + External Secrets Operator            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    if ! command -v kind &> /dev/null; then
        log_error "kind não encontrado. Instale com:"
        echo "  curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64"
        echo "  chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind"
        exit 1
    fi
    log_success "kind encontrado: $(kind version)"
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl não encontrado. Instale com:"
        echo "  curl -LO https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        echo "  chmod +x kubectl && sudo mv kubectl /usr/local/bin/"
        exit 1
    fi
    log_success "kubectl encontrado: $(kubectl version --client --short 2>/dev/null | head -1)"
    
    if ! command -v helm &> /dev/null; then
        log_warning "helm não encontrado - External Secrets será instalado via kubectl"
    else
        log_success "helm encontrado: $(helm version --short)"
    fi
}

# Executar deployment
run_deployment() {
    log_info "Executando deployment completo..."
    
    cd "$SCRIPT_DIR"
    
    if [ ! -x scripts/deploy.sh ]; then
        chmod +x scripts/*.sh
    fi
    
    ./scripts/deploy.sh
    
    log_success "Deployment concluído!"
}

# Aguardar serviços ficarem prontos
wait_for_services() {
    log_info "Aguardando todos os pods ficarem Running..."
    
    local max_wait=300
    local elapsed=0
    
    while [ $elapsed -lt $max_wait ]; do
        local pending=$(kubectl get pods -n monitoring --no-headers 2>/dev/null | grep -v "Running\|Completed" | wc -l)
        
        if [ "$pending" -eq 0 ]; then
            log_success "Todos os pods estão Running!"
            break
        fi
        
        log_info "Aguardando $pending pod(s)... (${elapsed}s/${max_wait}s)"
        sleep 10
        elapsed=$((elapsed + 10))
    done
    
    if [ $elapsed -ge $max_wait ]; then
        log_warning "Timeout aguardando pods - continuando mesmo assim"
    fi
    
    # Aguardar serviços estarem respondendo
    log_info "Aguardando serviços responderem..."
    
    log_info "Testando Zabbix Web (porta 30080)..."
    local zabbix_ready=false
    for i in {1..30}; do
        if curl -s --max-time 5 http://localhost:30080 >/dev/null 2>&1; then
            log_success "Zabbix Web está respondendo!"
            zabbix_ready=true
            break
        fi
        sleep 5
    done
    
    if [ "$zabbix_ready" = false ]; then
        log_error "Zabbix Web não respondeu em 150 segundos"
        exit 1
    fi
    
    log_info "Testando Grafana (porta 30300)..."
    local grafana_ready=false
    for i in {1..30}; do
        if curl -s --max-time 5 http://localhost:30300/api/health >/dev/null 2>&1; then
            log_success "Grafana está respondendo!"
            grafana_ready=true
            break
        fi
        sleep 5
    done
    
    if [ "$grafana_ready" = false ]; then
        log_error "Grafana não respondeu em 150 segundos"
        exit 1
    fi
    
    log_success "Todos os serviços estão prontos!"
}

# Configurar Zabbix
configure_zabbix() {
    log_info "Configurando Zabbix (templates, DNS, agent)..."
    
    cd "$SCRIPT_DIR"
    
    if ./scripts/configure-zabbix.sh; then
        log_success "Zabbix configurado com sucesso!"
    else
        log_error "Falha ao configurar Zabbix"
        return 1
    fi
}

# Configurar Grafana
configure_grafana() {
    log_info "Configurando Grafana (datasources e dashboards)..."
    
    cd "$SCRIPT_DIR"
    
    if ./scripts/configure-grafana.sh; then
        log_success "Grafana configurado com sucesso!"
    else
        log_error "Falha ao configurar Grafana"
        return 1
    fi
}

# Validar deployment
validate_deployment() {
    log_info "Validando deployment..."
    
    echo ""
    log_info "Status dos Pods:"
    kubectl get pods -n monitoring
    
    echo ""
    log_info "Testando endpoints..."
    
    if curl -s http://localhost:30080 | grep -q "Zabbix"; then
        log_success "✅ Zabbix Web acessível"
    else
        log_warning "⚠️  Zabbix Web pode ter problemas"
    fi
    
    if curl -s http://localhost:30300/api/health | grep -q "ok"; then
        log_success "✅ Grafana acessível"
    else
        log_warning "⚠️  Grafana pode ter problemas"
    fi
    
    if curl -s http://localhost:30900/-/ready | grep -q "ready"; then
        log_success "✅ Prometheus acessível"
    else
        log_warning "⚠️  Prometheus pode ter problemas"
    fi
    
    # Verificar se dashboards foram importados
    log_info "Verificando dashboards Grafana..."
    local grafana_pass=$(kubectl exec -n monitoring vault-0 -- sh -c 'export VAULT_TOKEN=vault-dev-root-token && vault kv get -field=admin-password secret/grafana' 2>/dev/null || echo "K8s_Grafana__Vault2024!@")
    local dash_count=$(curl -s -u admin:"$grafana_pass" http://localhost:30300/api/search?type=dash-db 2>/dev/null | grep -o '"title"' | wc -l)
    if [ "$dash_count" -ge 2 ]; then
        log_success "✅ Dashboards Grafana importados ($dash_count dashboards)"
    else
        log_warning "⚠️  Dashboards podem não ter sido importados"
    fi
    
    # Verificar se Zabbix está coletando dados
    log_info "Aguardando coleta inicial de dados (30 segundos)..."
    sleep 30
    
    log_info "Verificando coleta de dados do Zabbix..."
    local zbx_pass=$(kubectl exec -n monitoring vault-0 -- sh -c 'export VAULT_TOKEN=vault-dev-root-token && vault kv get -field=admin-password secret/zabbix' 2>/dev/null || echo "ComplexP@ssw0rd__L5!@")
    
    local item_count=$(curl -s -X POST http://localhost:30080/api_jsonrpc.php \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"user.login","params":{"username":"Admin","password":"'"$zbx_pass"'"},"id":1}' \
        | grep -o '"result":"[^"]*"' | cut -d'"' -f4 > /tmp/zbx_token.tmp 2>/dev/null && \
        curl -s -X POST http://localhost:30080/api_jsonrpc.php \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"item.get\",\"params\":{\"hostids\":\"10084\",\"output\":[\"itemid\"],\"filter\":{\"status\":\"0\"},\"countOutput\":true},\"auth\":\"$(cat /tmp/zbx_token.tmp)\",\"id\":4}" \
        | grep -o '"result":[0-9]*' | cut -d':' -f2)
    
    if [ "$item_count" -gt 50 ]; then
        log_success "✅ Zabbix coletando dados ($item_count itens ativos)"
    else
        log_warning "⚠️  Zabbix pode ainda estar inicializando coleta"
    fi
}

# Mostrar informações de acesso
show_access_info() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                🎉 Setup Concluído com Sucesso!                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Obter credenciais do Vault
    log_info "Obtendo credenciais geradas pelo Vault..."
    sleep 3
    
    ZABBIX_PASS=$(kubectl exec -n monitoring vault-0 -- sh -c 'export VAULT_TOKEN=vault-dev-root-token && vault kv get -field=admin-password secret/zabbix' 2>/dev/null || echo "⚠️ Executar: ./scripts/show-credentials.sh")
    GRAFANA_PASS=$(kubectl exec -n monitoring vault-0 -- sh -c 'export VAULT_TOKEN=vault-dev-root-token && vault kv get -field=admin-password secret/grafana' 2>/dev/null || echo "⚠️ Executar: ./scripts/show-credentials.sh")
    
    echo "🌐 URLs de Acesso:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📊 Zabbix Web Interface:"
    echo "   URL: http://localhost:30080"
    echo "   Usuário: Admin"
    echo "   Senha: $ZABBIX_PASS"
    echo ""
    echo "📈 Grafana:"
    echo "   URL: http://localhost:30300"
    echo "   Usuário: admin"
    echo "   Senha: $GRAFANA_PASS"
    echo ""
    echo "⚡ Prometheus:"
    echo "   URL: http://localhost:30900"
    echo ""
    echo "🔐 HashiCorp Vault:"
    echo "   Pod: kubectl exec -it vault-0 -n monitoring -- /bin/sh"
    echo "   Token: vault-dev-root-token"
    echo ""
    echo "💡 Informações Importantes:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   • Aguarde 5-10 minutos para coleta completa de dados"
    echo "   • Dashboards serão populados gradualmente"
    echo "   • Zabbix Agent: 140+ itens monitorados"
    echo "   • External Secrets sincronizando do Vault"
    echo "   • ⚠️  SENHAS GERADAS AUTOMATICAMENTE - Guarde com segurança!"
    echo ""
    echo "🔧 Comandos Úteis:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   ./scripts/show-credentials.sh               # Ver credenciais novamente"
    echo "   kubectl get pods -n monitoring              # Ver pods"
    echo "   kubectl logs -f <pod> -n monitoring         # Ver logs"
    echo "   kubectl get externalsecrets -n monitoring   # Ver secrets sincronizados"
    echo "   ./scripts/cleanup.sh                        # Limpar tudo"
    echo ""
    
    # Salvar credenciais em arquivo seguro
    cat > credentials.txt << EOF
╔═══════════════════════════════════════════════════════════╗
║       🔐 CREDENCIAIS DE ACESSO - LEVEL 5                 ║
║          GERADAS AUTOMATICAMENTE PELO VAULT              ║
╚═══════════════════════════════════════════════════════════╝

📊 ZABBIX WEB
   URL: http://localhost:30080
   Usuário: Admin
   Senha: $ZABBIX_PASS

📈 GRAFANA
   URL: http://localhost:30300
   Usuário: admin
   Senha: $GRAFANA_PASS

⚡ PROMETHEUS
   URL: http://localhost:30900
   (Sem autenticação)

🔐 VAULT
   Token: vault-dev-root-token
   
💾 Para recuperar posteriormente:
   ./scripts/show-credentials.sh

⚠️  ATENÇÃO: Guarde este arquivo em local seguro!
   Gerado em: $(date)
EOF
    
    chmod 600 credentials.txt
    log_success "Credenciais salvas em: credentials.txt"
}

# Verificar e limpar cluster existente
check_existing_cluster() {
    if kind get clusters 2>/dev/null | grep -q "^kind$"; then
        log_warning "Cluster 'kind' já existe!"
        echo ""
        read -t 15 -p "Deseja deletar e recriar? (s/N): " response || response="n"
        echo ""
        
        if [[ "$response" =~ ^[sS]$ ]]; then
            log_info "Deletando cluster existente..."
            kind delete cluster
            log_success "Cluster deletado!"
            sleep 2
        else
            log_info "Usando cluster existente (pode ter problemas se configuração estiver incompleta)"
            log_warning "Para instalação limpa, execute: kind delete cluster && ./setup.sh"
            sleep 3
        fi
    fi
}

# Função principal
main() {
    check_prerequisites
    check_existing_cluster
    
    log_info "Iniciando setup completo..."
    echo ""
    
    # 1. Deploy da infraestrutura
    run_deployment
    
    # 2. Aguardar serviços
    wait_for_services
    
    # 3. Configurar Zabbix
    configure_zabbix
    
    # 4. Configurar Grafana
    configure_grafana
    
    # 5. Validar
    validate_deployment
    
    # 6. Mostrar info
    show_access_info
    
    log_success "Setup completo! Ambiente pronto para uso."
}

# Executar
main "$@"
