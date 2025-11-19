#!/bin/bash

# Script para publicar o projeto no GitHub
# Repository: https://github.com/jlui70/monitoring-security-level5

set -e

echo "📦 Publicando Monitoring Security Level 5 no GitHub"
echo "=================================================="
echo ""

# Verificar se estamos no diretório correto
if [ ! -f "README.md" ] || [ ! -d "kubernetes" ]; then
    echo "❌ Execute este script no diretório raiz do projeto!"
    exit 1
fi

# Verificar se git está instalado
if ! command -v git &> /dev/null; then
    echo "❌ Git não encontrado. Instale o git primeiro."
    exit 1
fi

# 1. Inicializar repositório git (se necessário)
if [ ! -d ".git" ]; then
    echo "🔧 Inicializando repositório Git..."
    git init
    echo "✅ Repositório inicializado"
else
    echo "ℹ️  Repositório Git já existe"
fi

# 2. Configurar remote (se necessário)
if ! git remote get-url origin &> /dev/null; then
    echo "🔗 Configurando remote origin..."
    git remote add origin https://github.com/jlui70/monitoring-security-level5.git
    echo "✅ Remote configurado"
else
    echo "ℹ️  Remote origin já configurado:"
    git remote get-url origin
fi

# 3. Verificar branch
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ "$current_branch" != "main" ] && [ "$current_branch" != "master" ]; then
    echo "🔀 Criando/mudando para branch main..."
    git checkout -b main 2>/dev/null || git checkout main
    echo "✅ Branch main ativa"
else
    echo "ℹ️  Branch atual: $current_branch"
fi

# 4. Verificar arquivos ignorados
echo ""
echo "📋 Verificando .gitignore..."
if [ -f ".gitignore" ]; then
    echo "✅ .gitignore existe"
    
    # Verificar se há arquivos sensíveis
    sensitive_files=$(git status --porcelain | grep -E "credentials.txt|\.log|\.env" || true)
    if [ -n "$sensitive_files" ]; then
        echo "⚠️  ATENÇÃO: Arquivos sensíveis detectados:"
        echo "$sensitive_files"
        echo ""
        read -p "Deseja continuar mesmo assim? (s/N): " confirm
        if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
            echo "❌ Publicação cancelada"
            exit 1
        fi
    fi
else
    echo "⚠️  .gitignore não encontrado!"
fi

# 5. Adicionar arquivos
echo ""
echo "📁 Adicionando arquivos..."
git add .
echo "✅ Arquivos adicionados"

# 6. Mostrar status
echo ""
echo "📊 Status do repositório:"
git status --short

# 7. Confirmar commit
echo ""
echo "💾 Arquivos prontos para commit. Verifique acima se está tudo correto."
read -p "Deseja fazer o commit? (s/N): " do_commit

if [ "$do_commit" != "s" ] && [ "$do_commit" != "S" ]; then
    echo "⏸️  Commit cancelado. Execute manualmente quando estiver pronto:"
    echo ""
    echo "   git commit -m 'feat: Initial commit - Monitoring Security Level 5'"
    echo "   git push -u origin main"
    exit 0
fi

# 8. Fazer commit
echo ""
echo "💾 Fazendo commit..."
git commit -m "feat: Initial commit - Monitoring Security Level 5

Stack completa de monitoramento em Kubernetes com:
- HashiCorp Vault para gestão centralizada de secrets
- External Secrets Operator para sincronização automática
- Zabbix 7.0 + Prometheus + Grafana
- Deploy automatizado em Kind cluster
- ZERO arquivos .env (consumo direto do Vault)

Principais features:
✅ Automação completa (./setup.sh)
✅ Auto-recovery de problemas comuns
✅ Documentação completa em PT-BR
✅ Configuração automática de dashboards e templates
✅ Auditoria e versionamento de secrets via Vault
" || echo "ℹ️  Nada para commitar (arquivos já commitados)"

# 9. Push para GitHub
echo ""
read -p "Deseja fazer push para o GitHub agora? (s/N): " do_push

if [ "$do_push" == "s" ] || [ "$do_push" == "S" ]; then
    echo "🚀 Fazendo push para GitHub..."
    git push -u origin main
    
    echo ""
    echo "=========================================="
    echo "✅ PROJETO PUBLICADO COM SUCESSO!"
    echo "=========================================="
    echo ""
    echo "🌐 Repositório: https://github.com/jlui70/monitoring-security-level5"
    echo ""
    echo "📋 Próximos passos recomendados:"
    echo "1. Acesse o repositório no GitHub"
    echo "2. Adicione descrição do projeto nas configurações"
    echo "3. Adicione topics/tags: kubernetes, vault, monitoring, zabbix, prometheus, grafana, external-secrets"
    echo "4. Considere criar uma release v1.0.0"
    echo "5. Atualize os READMEs dos outros levels (1-4) com o link deste projeto"
    echo ""
else
    echo "⏸️  Push cancelado. Execute manualmente quando estiver pronto:"
    echo ""
    echo "   git push -u origin main"
fi

echo ""
echo "🎉 Script finalizado!"
