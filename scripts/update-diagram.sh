#!/bin/bash

# Script para atualizar diagrama no GitHub após edição no Draw.io

set -e

echo "📊 Atualizador de Diagrama de Arquitetura"
echo "=========================================="
echo ""

# Verificar se arquivo PNG existe
if [ ! -f "docs/architecture.png" ]; then
    echo "❌ Arquivo docs/architecture.png não encontrado!"
    echo ""
    echo "📋 Passos para criar:"
    echo "1. Abra https://app.diagrams.net"
    echo "2. Abra o arquivo: docs/architecture-diagram.drawio"
    echo "3. Faça suas edições"
    echo "4. File → Export as → PNG"
    echo "5. Salve como: docs/architecture.png"
    echo "6. Execute este script novamente"
    echo ""
    exit 1
fi

echo "✅ Arquivo PNG encontrado!"
echo ""

# Verificar tamanho do arquivo
size=$(du -h docs/architecture.png | cut -f1)
echo "📦 Tamanho do arquivo: $size"
echo ""

# Confirmar
read -p "Deseja fazer commit e push? (s/N): " confirm

if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
    echo "❌ Cancelado"
    exit 0
fi

# Git add
echo "📁 Adicionando arquivos ao git..."
git add docs/architecture.png docs/architecture-diagram.drawio

# Commit
echo "💾 Fazendo commit..."
git commit -m "docs: Atualizar diagrama de arquitetura

- Diagrama editado no Draw.io
- PNG exportado para melhor visualização
- Mantido arquivo .drawio para futuras edições"

# Push
echo "🚀 Enviando para GitHub..."
git push

echo ""
echo "✅ Diagrama atualizado com sucesso!"
echo ""
echo "🌐 Acesse: https://github.com/jlui70/monitoring-security-level5"
echo ""
echo "📋 Próximo passo: Atualizar README.md para usar a imagem PNG"
echo "Execute: ./scripts/update-readme-diagram.sh"
