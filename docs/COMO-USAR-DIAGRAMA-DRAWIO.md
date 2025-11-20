# 📊 Como Usar Diagrama DrawIO no GitHub

## 🎯 Três Formas de Usar

---

### **Opção 1: PNG no README (Recomendada)** ⭐

**Vantagens:**
- ✅ Visualização imediata no GitHub
- ✅ Alta qualidade
- ✅ Funciona em qualquer dispositivo
- ✅ Carregamento rápido

**Passos:**

1. **Exportar do Draw.io:**
   ```
   1. Abra https://app.diagrams.net
   2. File → Open → Selecione docs/architecture-diagram.drawio
   3. Faça suas edições
   4. File → Export as → PNG
   5. Configurações:
      - Zoom: 100%
      - Border Width: 10
      - Selection Only: Não
      - Transparent Background: Não
      - Shadow: Sim
   6. Salve como: architecture.png
   ```

2. **Copiar para o projeto:**
   ```bash
   # Mova o arquivo exportado para:
   mv ~/Downloads/architecture.png ~/monitoring-security-level5/docs/
   ```

3. **Atualizar README.md:**
   ```markdown
   ## 🏗️ **Arquitetura**
   
   ![Arquitetura do Sistema](docs/architecture.png)
   
   *Diagrama editável disponível em: [architecture-diagram.drawio](docs/architecture-diagram.drawio)*
   ```

4. **Fazer commit:**
   ```bash
   cd ~/monitoring-security-level5
   ./scripts/update-diagram.sh
   ```

---

### **Opção 2: SVG no README** (Melhor para Zoom)

**Vantagens:**
- ✅ Vetorial (zoom infinito sem perder qualidade)
- ✅ Arquivo menor que PNG
- ✅ Melhor para diagramas técnicos

**Passos:**

1. **Exportar como SVG:**
   ```
   Draw.io → File → Export as → SVG
   Salve como: docs/architecture.svg
   ```

2. **Usar no README:**
   ```markdown
   ![Arquitetura](docs/architecture.svg)
   ```

---

### **Opção 3: Embed DrawIO no GitHub** (Avançado)

**Vantagens:**
- ✅ GitHub pode renderizar .drawio diretamente
- ✅ Versionamento do diagrama

**Como funciona:**
- GitHub detecta arquivos `.drawio` automaticamente
- Ao clicar, abre preview interativo
- Pode baixar ou editar

**Uso:**
```markdown
[📊 Ver Diagrama Interativo](docs/architecture-diagram.drawio)
```

Usuários podem:
- Clicar no link
- GitHub abre preview
- Baixar para editar localmente

---

## 🚀 **Workflow Recomendado**

### **Sempre que atualizar o diagrama:**

```bash
# 1. Edite no Draw.io (web ou desktop)
# 2. Salve o .drawio (versionamento)
# 3. Exporte como PNG (visualização)
# 4. Execute:

cd ~/monitoring-security-level5
./scripts/update-diagram.sh
```

Isso vai:
1. Verificar se PNG existe
2. Fazer commit de ambos (.drawio + .png)
3. Push para GitHub
4. README já mostra o PNG

---

## 📋 **Estrutura Ideal de Arquivos**

```
docs/
├── architecture-diagram.drawio  # Editável (fonte)
├── architecture.png             # Visual (README)
└── architecture.svg             # Opcional (vetorial)
```

---

## 🎨 **Dicas de Exportação (Draw.io)**

### **Para PNG de alta qualidade:**
```
✅ Zoom: 100% ou 200% (se quiser maior)
✅ Border Width: 10 (margem ao redor)
✅ Transparent: Não (fundo branco é melhor)
✅ Shadow: Sim (profissional)
✅ Grid: Não
```

### **Para SVG:**
```
✅ Embed Fonts: Sim
✅ Include a copy of my diagram: Não (já tem .drawio)
```

---

## 🔄 **Manter Sincronizado**

### **Regra de Ouro:**

1. **Edite SEMPRE** o `.drawio` (fonte da verdade)
2. **Exporte SEMPRE** para PNG/SVG após editar
3. **Commit AMBOS** os arquivos juntos

**Por quê?**
- `.drawio` = Editável (futuras mudanças)
- `.png/.svg` = Visualização (GitHub README)

---

## ❌ **Erros Comuns**

### **"Imagem não aparece no GitHub"**

**Causas:**
- ❌ Caminho errado no README
- ❌ Arquivo não foi commitado
- ❌ Cache do navegador

**Solução:**
```bash
# Verificar se arquivo existe
ls -lh docs/architecture.png

# Verificar se foi commitado
git status

# Forçar atualização no GitHub
git add docs/architecture.png
git commit --amend --no-edit
git push --force
```

### **"Imagem muito grande no README"**

**Solução:**
```markdown
<!-- Adicione width para controlar tamanho -->
<img src="docs/architecture.png" width="800" alt="Arquitetura">
```

---

## 📱 **Exemplo Completo no README**

```markdown
## 🏗️ **Arquitetura**

### Visão Geral

<div align="center">
  <img src="docs/architecture.png" width="900" alt="Diagrama de Arquitetura">
  <p><em>Diagrama editável disponível em: <a href="docs/architecture-diagram.drawio">architecture-diagram.drawio</a></em></p>
</div>

### Componentes

[... explicação dos componentes ...]

### Fluxo de Dados

1. Vault armazena secrets
2. ESO sincroniza para K8s Secrets
3. Pods consomem como env vars
...
```

---

## 🛠️ **Ferramentas Úteis**

### **Draw.io Desktop (Offline):**
```bash
# Linux
sudo snap install drawio

# Windows
winget install drawio

# macOS
brew install --cask drawio
```

### **VSCode Extension:**
```
Nome: Draw.io Integration
ID: hediet.vscode-drawio
```

Permite editar `.drawio` direto no VSCode!

---

## ✅ **Checklist Final**

Antes de fazer commit:

- [ ] Editei o arquivo `.drawio`
- [ ] Salvei o `.drawio`
- [ ] Exportei como PNG (ou SVG)
- [ ] PNG está em `docs/architecture.png`
- [ ] Testei localmente (abri o PNG)
- [ ] README.md aponta para o arquivo correto
- [ ] Executei `./scripts/update-diagram.sh`

---

## 🌐 **Resultado Esperado no GitHub**

Quando alguém abrir seu README:

✅ **Vê a imagem** renderizada automaticamente  
✅ **Imagem bonita** (alta qualidade, cores, sombras)  
✅ **Pode clicar** no link do .drawio para baixar  
✅ **Pode editar** localmente e contribuir  

---

**Criado em:** 2025-01-20  
**Projeto:** Monitoring Security Level 5  
**Repositório:** https://github.com/jlui70/monitoring-security-level5
