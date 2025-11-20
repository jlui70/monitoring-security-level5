# 📊 Opções para Mostrar Diagrama no README

## Opção 1: Imagem PNG (Simples e Direta) ⭐

```markdown
## 🏗️ **Arquitetura**

![Arquitetura do Sistema](docs/architecture.png)

*Diagrama editável: [architecture-diagram.drawio](docs/architecture-diagram.drawio)*
```

---

## Opção 2: Imagem PNG com Tamanho Controlado

```markdown
## 🏗️ **Arquitetura**

<div align="center">
  <img src="docs/architecture.png" width="900" alt="Diagrama de Arquitetura">
  <p><em>📝 Diagrama editável: <a href="docs/architecture-diagram.drawio">architecture-diagram.drawio</a></em></p>
</div>
```

---

## Opção 3: Manter Mermaid + Link para PNG

```markdown
## 🏗️ **Arquitetura**

### Diagrama Interativo (Mermaid)

```mermaid
[... código Mermaid atual ...]
```

### Diagrama Detalhado (DrawIO)

![Arquitetura Detalhada](docs/architecture.png)

*📝 Edite o diagrama: [architecture-diagram.drawio](docs/architecture-diagram.drawio)*
```

---

## Opção 4: Apenas Link (Mais Clean)

```markdown
## 🏗️ **Arquitetura**

📊 **[Ver Diagrama de Arquitetura](docs/architecture.png)**

*Diagrama editável em: [architecture-diagram.drawio](docs/architecture-diagram.drawio)*

### Componentes Principais

[... explicação textual ...]
```

---

## ✅ Recomendação

Use **Opção 2** (imagem centralizada com tamanho controlado):
- ✅ Visual profissional
- ✅ Tamanho adequado
- ✅ Link para editar
- ✅ Centralizado

---

## 🔄 Workflow Completo

### Sempre que atualizar o diagrama:

```bash
# 1. Edite no Draw.io
# 2. Exporte como PNG → docs/architecture.png
# 3. Execute:
cd ~/monitoring-security-level5
./scripts/update-diagram.sh

# 4. O README já mostrará automaticamente!
```

---

## 📝 Nota Importante

**Você ainda não tem o arquivo PNG!**

Precisa:
1. Abrir Draw.io
2. Exportar seu diagrama editado como PNG
3. Salvar em `docs/architecture.png`
4. Executar `./scripts/update-diagram.sh`

Então eu posso atualizar o README para mostrar a imagem!
