# 🤝 Contribuindo para o Monitoring Security Evolution - Nível 5

Obrigado pelo seu interesse em contribuir! Este documento fornece diretrizes para contribuir com este projeto.

## 🎯 Como Contribuir

### Reportando Problemas

1. **Verifique issues existentes** - Busque para evitar duplicatas
2. **Use templates de issue** - Forneça todas as informações solicitadas
3. **Seja específico** - Inclua mensagens de erro, logs e detalhes do ambiente

### Sugerindo Funcionalidades

1. Abra uma issue com o label "Feature Request"
2. Descreva a funcionalidade e seus benefícios
3. Forneça exemplos ou mockups se aplicável

### Contribuições de Código

#### Antes de Começar

1. Faça fork do repositório
2. Clone seu fork: `git clone https://github.com/SEU-USUARIO/monitoring-security-level5.git`
3. Crie uma branch de feature: `git checkout -b feature/nome-da-sua-feature`

#### Fluxo de Desenvolvimento

1. **Faça alterações** na sua branch de feature
2. **Teste completamente**:
   ```bash
   # Ambiente limpo
   ./scripts/cleanup.sh
   
   # Deploy fresh
   ./setup.sh
   
   # Verifique todos os pods Running
   kubectl get pods -n monitoring
   
   # Cheque ExternalSecrets sincronizados
   kubectl get externalsecrets -n monitoring
   
   # Teste as interfaces web
   ./scripts/test-urls.sh
   ```

3. **Siga o estilo de código**:
   - Use 2 espaços para indentação YAML
   - Use 4 espaços para scripts Bash
   - Adicione comentários para lógica complexa
   - Use nomes de variáveis significativos

4. **Atualize a documentação**:
   - Atualize README.md se adicionar novas features
   - Adicione entradas de troubleshooting se corrigir bugs
   - Atualize docs/ conforme necessário

5. **Faça commit das suas alterações**:
   ```bash
   git add .
   git commit -m "feat: Adiciona descrição da nova funcionalidade"
   ```

#### Diretrizes de Mensagens de Commit

Use conventional commits:

- `feat:` - Nova funcionalidade
- `fix:` - Correção de bug
- `docs:` - Alterações na documentação
- `refactor:` - Refatoração de código
- `test:` - Adição de testes
- `chore:` - Tarefas de manutenção

Exemplos:
```
feat: Adiciona suporte a PostgreSQL para Zabbix
fix: Resolve problema de MySQL CrashLoopBackOff
docs: Atualiza guia de troubleshooting
refactor: Melhora tratamento de erros no deploy.sh
```

#### Processo de Pull Request

1. **Push para seu fork**: `git push origin feature/nome-da-sua-feature`
2. **Abra um Pull Request** no GitHub
3. **Preencha o template do PR** completamente
4. **Aguarde review** - Atenda qualquer feedback
5. **Garanta que CI passa** (se configurado)

### Diretrizes de Testes

#### Requisitos Mínimos de Teste

Todas as contribuições DEVEM passar:

```bash
# 1. Verificação de ambiente
./scripts/check-environment.sh

# 2. Deploy limpo
./scripts/cleanup.sh
./setup.sh

# 3. Validação
kubectl get pods -n monitoring
# Todos os pods devem estar Running/Completed

kubectl get externalsecrets -n monitoring
# Todos devem mostrar SecretSynced e Ready=True

# 4. Testes de UI web
curl -s http://localhost:30300 | grep -q "Grafana" && echo "✅ Grafana OK"
curl -s http://localhost:30080 | grep -q "Zabbix" && echo "✅ Zabbix OK"
curl -s http://localhost:30900 | grep -q "Prometheus" && echo "✅ Prometheus OK"
```

#### O que Testar

- **Instalação fresh** - Deploy em ambiente limpo
- **Idempotência** - Executar `./setup.sh` duas vezes sem erros
- **Recuperação** - Testar features de auto-recovery (ex: volumes corrompidos)
- **Configuração** - Verificar se configs do Zabbix e Grafana aplicam corretamente
- **UIs Web** - Garantir que todos os serviços estão acessíveis

### Padrões de Qualidade de Código

#### Scripts Bash

```bash
#!/bin/bash

# Use modo estrito
set -e  # Sai em caso de erro

# Adicione comentários descritivos
# Esta função faz deploy da stack de monitoramento
deploy_monitoring() {
    echo "📊 Fazendo deploy dos componentes de monitoramento..."
    
    # Verifique pré-requisitos
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl não encontrado"
        exit 1
    fi
    
    # Deploy com tratamento de erro
    kubectl apply -f kubernetes/monitoring/ || {
        echo "❌ Deploy falhou"
        return 1
    }
}
```

#### Manifestos Kubernetes

```yaml
# Use labels apropriados
apiVersion: v1
kind: Service
metadata:
  name: monitoring-service
  labels:
    app: monitoring
    component: frontend
    managed-by: monitoring-security-level5
spec:
  # Adicione comentários para configurações não óbvias
  # ClusterIP para acesso somente interno
  type: ClusterIP
```

#### Documentação

- Use títulos claros
- Adicione exemplos de código
- Inclua outputs esperados
- Forneça passos de troubleshooting

## 🔒 Segurança

### Reportando Problemas de Segurança

**NÃO** abra issues públicas para vulnerabilidades de segurança.

Em vez disso:
1. Envie email aos mantenedores privativamente
2. Forneça descrição detalhada
3. Inclua passos de reprodução
4. Aguarde confirmação antes de divulgar

### Boas Práticas de Segurança

- Nunca faça commit de secrets ou credenciais
- Use Vault para todos os dados sensíveis
- Siga o princípio do menor privilégio
- Mantenha dependências atualizadas

## 📋 Estrutura do Projeto

```
monitoring-security-level5/
├── scripts/                # Scripts de automação
│   ├── deploy.sh          # Lógica principal de deployment
│   ├── cleanup.sh         # Script de limpeza
│   └── configure-*.sh     # Scripts de configuração
├── kubernetes/            # Manifestos K8s (numerados para ordem de deploy)
│   ├── 01-namespace/
│   ├── 02-vault/
│   └── ...
├── docs/                  # Documentação
│   ├── guides/           # Guias de usuário
│   └── troubleshooting/  # Docs de troubleshooting
└── README.md             # Documentação principal
```

### Adicionando Novos Componentes

1. Crie diretório em `kubernetes/` com número apropriado
2. Adicione lógica de deployment em `scripts/deploy.sh`
3. Atualize diagrama de arquitetura no `README.md`
4. Adicione script de configuração se necessário
5. Documente em `docs/guides/`

## 🎓 Recursos de Aprendizado

### Entendendo a Stack

- [Documentação Vault](https://www.vaultproject.io/docs)
- [External Secrets Operator](https://external-secrets.io/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Documentação Zabbix](https://www.zabbix.com/documentation/current/)
- [Documentação Prometheus](https://prometheus.io/docs/)
- [Documentação Grafana](https://grafana.com/docs/)

### Ambiente de Desenvolvimento

Ferramentas recomendadas:
- VS Code com extensões YAML e Kubernetes
- kubectl com auto-completion
- k9s para gerenciamento de cluster
- Docker Desktop ou Podman

## ❓ Dúvidas?

- Abra uma discussão no GitHub
- Verifique issues e PRs existentes
- Revise a documentação em `docs/`

## 🌟 Reconhecimento

Contribuidores serão:
- Listados em CONTRIBUTORS.md
- Mencionados nas notas de release
- Creditados na documentação relevante

---

Obrigado por contribuir! 🙏

Toda contribuição, não importa quão pequena, ajuda a melhorar este projeto para todos.
