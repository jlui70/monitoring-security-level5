#!/bin/bash

# Script para verificar se o ambiente está pronto para deployment

echo "🔍 Verificação de Ambiente - Level 5"
echo "====================================="
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

checks_passed=0
checks_total=0

check() {
    ((checks_total++))
    if eval "$2"; then
        echo -e "${GREEN}✅${NC} $1"
        ((checks_passed++))
        return 0
    else
        echo -e "${RED}❌${NC} $1"
        return 1
    fi
}

warn() {
    echo -e "${YELLOW}⚠️${NC}  $1"
}

info() {
    echo -e "ℹ️  $1"
}

echo "📦 Ferramentas Necessárias:"
echo "----------------------------"
check "Kind instalado" "command -v kind &>/dev/null" || info "  Instale: curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64 && chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind"
check "Kubectl instalado" "command -v kubectl &>/dev/null" || info "  Instale: curl -LO https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/"
check "Helm instalado (opcional)" "command -v helm &>/dev/null" || warn "  Helm não é obrigatório mas recomendado"
check "Docker rodando" "docker ps &>/dev/null" || info "  Inicie o Docker Desktop/Daemon"

echo ""
echo "💾 Recursos do Sistema:"
echo "------------------------"

# Memória
total_mem=$(free -g | awk '/^Mem:/{print $2}')
if [ "$total_mem" -ge 4 ]; then
    check "Memória RAM ($total_mem GB >= 4GB)" "true"
else
    check "Memória RAM ($total_mem GB >= 4GB)" "false"
    warn "  Configure mais RAM no WSL2: .wslconfig com memory=4GB"
fi

# CPU
cpu_cores=$(nproc)
if [ "$cpu_cores" -ge 2 ]; then
    check "CPU Cores ($cpu_cores >= 2)" "true"
else
    check "CPU Cores ($cpu_cores >= 2)" "false"
    warn "  Configure mais CPUs no WSL2/Docker"
fi

# Espaço em disco
disk_avail=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
if [ "$disk_avail" -ge 10 ]; then
    check "Espaço em disco (${disk_avail}GB >= 10GB)" "true"
else
    check "Espaço em disco (${disk_avail}GB >= 10GB)" "false"
    warn "  Libere espaço em disco"
fi

echo ""
echo "🔌 Portas Necessárias:"
echo "----------------------"

ports_ok=true
for port in 30080 30300 30900; do
    if ! ss -tuln 2>/dev/null | grep -q ":$port " && ! netstat -tuln 2>/dev/null | grep -q ":$port "; then
        check "Porta $port disponível" "true"
    else
        check "Porta $port disponível" "false"
        warn "  Porta $port em uso. Pare o serviço que está usando ou mude a porta no Kind config"
        ports_ok=false
    fi
done

echo ""
echo "🌐 Conectividade:"
echo "------------------"

# DNS
if ping -c 1 8.8.8.8 &>/dev/null; then
    check "Conectividade internet" "true"
else
    check "Conectividade internet" "false"
    warn "  Necessário para baixar imagens Docker"
fi

echo ""
echo "📊 Cluster Kind Existente:"
echo "--------------------------"

if kind get clusters 2>/dev/null | grep -q "^kind$"; then
    warn "Cluster 'kind' JÁ EXISTE"
    info "  Será solicitado deletar e recriar durante setup"
    info "  Ou execute: kind delete cluster"
else
    check "Nenhum cluster existente" "true"
fi

echo ""
echo "═══════════════════════════════════"
echo "Resultado: $checks_passed/$checks_total verificações passaram"
echo "═══════════════════════════════════"

if [ "$checks_passed" -eq "$checks_total" ]; then
    echo -e "${GREEN}✅ Sistema pronto para deployment!${NC}"
    echo ""
    echo "Execute: ./setup.sh"
    exit 0
elif [ "$checks_passed" -ge $((checks_total - 2)) ]; then
    echo -e "${YELLOW}⚠️  Sistema parcialmente pronto${NC}"
    echo "Alguns avisos foram encontrados mas deploy pode funcionar"
    echo ""
    echo "Execute por sua conta e risco: ./setup.sh"
    exit 0
else
    echo -e "${RED}❌ Sistema NÃO está pronto${NC}"
    echo "Corrija os problemas acima antes de continuar"
    exit 1
fi
