# LazyWindow 🖱️⌨️

**Controle completo do mouse usando apenas o teclado**

LazyWindow é um aplicativo para Windows que permite usuários navegarem e clicarem em qualquer área da tela sem usar o mouse, através de um sistema de grid recursivo e atalhos de teclado intuitivos.

---

## ✨ Funcionalidades

### ⬆️ Modo Setas (Arrow Mouse Mode)

Ative um modo onde as **setas do teclado movem o mouse** continuamente. Você pode segurar duas setas ao mesmo tempo para movimento diagonal (45°).

**Atalhos:**
- `Alt+Home` (liga/desliga)
- `Ctrl+F12` abre um modal para ajustar a **velocidade** (DPI 1–50)
- `Alt+F12` define velocidade em 8 dpi
- `Ctrl+Ins` diminui 1 ponto na velocidade
- `Alt+Ins` aumenta 1 ponto na velocidade

Enquanto o modo estiver ativo:
- `F1` = clique direito
- `F2` = clique esquerdo
- `Ctrl` + `Setas` = arrastar (segura clique esquerdo enquanto move)
- `Alt+-` = scroll horizontal para esquerda
- `Alt+=` = scroll horizontal para direita

---

### 🎯 Navegação por Grid (Matrix Navigation)

Ative um grid visual semi-transparente que divide a tela em 6 áreas. Selecione uma área para subdividir recursivamente até alcançar a precisão desejada.

**Atalhos de Ativação:**
| Atalho | Ação |
|--------|------|
| `Ctrl+End` | Ativa grid no Monitor 1 |
| `Ctrl+Del` | Ativa grid no Monitor 2 |
| `Ctrl+PgDn` | Ativa grid no Monitor 3 |
| `Ctrl+PgUp` | Ativa grid na janela ativa |
| `Alt+PgUp` | Ativa grid ao redor do cursor (400x400px) |

**Layout do Grid (2x3):**
```
┌───────┬───────┬───────┐
│   A   │   S   │   D   │
├───────┼───────┼───────┤
│   Z   │   X   │   C   │
└───────┴───────┴───────┘
```

**Teclas de Navegação:**
- `A`, `S`, `D` - Seleciona célula da linha superior
- `Z`, `X`, `C` - Seleciona célula da linha inferior

**Ações:**
| Tecla | Ação |
|-------|------|
| `Enter` | Clique direito do mouse no centro da área atual |
| `Backspace` | Clique esquerdo do mouse no centro da área atual |
| `ESC` | Cancela e fecha o grid |

### 🪟 Seletor de Janelas (Window Switcher)

Alterne rapidamente entre janelas abertas e posicione o mouse em pontos específicos da janela.

**Atalho:** `Ctrl+Home`

A lista exibe 3 colunas: **#** (número), **Processo** (nome do programa) e **Janela** (título).

> Dica: se o **Modo Setas** estiver ativo, `Ctrl+Home` desativa o modo antes de abrir o seletor.

**Uso:**
1. Pressione `Ctrl+Home` para abrir a lista de janelas
2. Digite o número da janela desejada
3. (Opcional) Digite a posição do mouse:
   - `C` - Centro
   - `T` - Topo
   - `E` - Esquerda
   - `D` - Direita
   - `R` - Rodapé (bottom)
4. Pressione `Enter` para confirmar

**Combinações de Posição:**
| Código | Posição |
|--------|---------|
| `C` | Centro da janela |
| `T` | Centro do topo |
| `R` | Centro do rodapé |
| `E` | Centro da esquerda |
| `D` | Centro da direita |
| `TE` | Canto superior esquerdo |
| `TD` | Canto superior direito |
| `RE` | Canto inferior esquerdo |
| `RD` | Canto inferior direito |

**Exemplos:**
- `1` ou `1C` → Foca janela 1, mouse no centro
- `2TD` → Foca janela 2, mouse no canto superior direito
- `3RE` → Foca janela 3, mouse no canto inferior esquerdo

---

### 📝 Snippet Manager

Gestor de snippets de código que funciona em qualquer editor ou terminal. Detecta automaticamente a linguagem baseado na janela ativa e substitui placeholders com contexto.

**Atalho:** `Ctrl+Alt+F10`

**Linguagens Suportadas:**
- TypeScript/JavaScript
- Python
- SQL
- PowerShell
- Bash/Shell
- Go

**Snippets Incluídos:**

| Categoria | Exemplos |
|-----------|----------|
| SOLID | Single Responsibility, Open/Closed, Liskov, Interface Segregation, Dependency Inversion |
| Clean Code | Guard Clauses, Extract Method, Null Object, Constants |
| Design Patterns | Singleton, Factory, Observer |
| TypeScript | Interface, Async/Await, React useState |
| Python | Class, Dataclass |
| SQL | SELECT JOIN, CTE |
| PowerShell | Try-Catch, REST API |
| Bash | Function, AWS CLI |
| Go | Struct, HTTP Handler |

**Como usar:**
1. (Opcional) Selecione uma palavra no editor (nome de classe/função)
2. Pressione `Ctrl+Alt+F10`
3. A linguagem é detectada automaticamente pela janela ativa
4. Busque ou navegue pelos snippets
5. Pressione Enter para inserir

**Placeholders automáticos:**
- `${ClassName}`, `${FunctionName}` → palavra selecionada
- `${date}` → data atual
- `${user}` → nome do usuário

---

### 📍 Marcadores de Posição (Mouse Bookmarks)

Salve até **9 posições do mouse** e volte para elas rapidamente. Os marcadores são persistidos em arquivo e sobrevivem ao reiniciar.

**Atalhos:**
| Atalho | Ação |
|--------|------|
| `Ctrl+1..9` | Salvar posição atual no marcador |
| `Alt+1..9` | Mover cursor para o marcador |
| `Ctrl+Alt+1..9` | Mover e clicar no marcador |

**Arquivo de persistência:** `~/.lazywindow/markers.json`

---

## 📋 Casos de Uso

### UC01: Clicar em um botão específico na tela
**Ator:** Usuário sem mouse  
**Pré-condição:** LazyWindow está em execução  
**Fluxo Principal:**
1. Usuário pressiona `Ctrl+End` (Monitor 1)
2. Grid 2x3 aparece cobrindo toda a tela
3. Usuário pressiona `S` (área central superior)
4. Grid redesenha apenas na área selecionada
5. Usuário pressiona `X` (área central inferior da nova subdivisão)
6. Grid redesenha novamente
7. Usuário pressiona `Backspace` para clique esquerdo
8. Mouse move para o centro e executa clique esquerdo
9. Grid fecha

### UC02: Abrir menu de contexto em área específica
**Ator:** Usuário sem mouse  
**Fluxo Principal:**
1. Usuário ativa grid no monitor desejado
2. Navega até a área alvo usando `A/S/D/Z/X/C`
3. Pressiona `Enter` para clique direito
4. Menu de contexto abre na posição

### UC03: Cancelar navegação
**Ator:** Usuário sem mouse  
**Fluxo Principal:**
1. Usuário ativa grid
2. Navega algumas subdivisões
3. Pressiona `ESC`
4. Grid fecha sem executar ação

### UC04: Alternar para outra janela
**Ator:** Usuário sem mouse  
**Fluxo Principal:**
1. Usuário pressiona `Ctrl+Home`
2. Lista de janelas aparece numerada
3. Usuário digita `3` e pressiona Enter
4. Foco muda para janela 3, mouse no centro

### UC05: Alternar para janela e posicionar mouse no canto
**Ator:** Usuário sem mouse  
**Fluxo Principal:**
1. Usuário pressiona `Ctrl+Home`
2. Lista de janelas aparece
3. Usuário digita `2RD` (janela 2, rodapé direito)
4. Pressiona Enter
5. Foco muda para janela 2, mouse no canto inferior direito

### UC06: Trabalhar com múltiplos monitores
**Ator:** Usuário com setup multi-monitor  
**Fluxo Principal:**
1. Usuário precisa clicar em algo no Monitor 2
2. Pressiona `Ctrl+Del`
3. Grid aparece apenas no Monitor 2
4. Navega e clica normalmente

---

## 🔧 Requisitos

- Windows 10/11
- [AutoHotkey v2](https://www.autohotkey.com/)

## 📦 Instalação

1. Instale o AutoHotkey v2
2. Clone ou baixe este repositório
3. Execute `src/main.ahk`

## 🚀 Início Rápido

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/lazywindow.git

# Execute
cd lazywindow
start src/main.ahk
```

### 🔁 Atalho para ligar/desligar (toggle) via atalho do Windows

Se você quer **um único atalho** que **abre o LazyWindow** quando não estiver rodando e **fecha** quando já estiver rodando, use o script:

- `ToggleLazyWindow.ps1`

Crie um atalho do Windows apontando para:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\caminho\para\lazywindow\ToggleLazyWindow.ps1"
```

Depois, nas propriedades do atalho, você pode definir uma **tecla de atalho** (hotkey) para chamar esse toggle.

---

## ⌨️ Referência Rápida de Atalhos

| Atalho | Função |
|--------|--------|
| `Ctrl+End` | Grid no Monitor 1 |
| `Ctrl+Del` | Grid no Monitor 2 |
| `Ctrl+PgDn` | Grid no Monitor 3 |
| `Ctrl+PgUp` | Grid na janela ativa |
| `Alt+PgUp` | Grid ao redor do cursor (400x400px) |
| `Ctrl+Home` | Seletor de Janelas (mostra processo + título) |
| `Alt+Home` | Modo Setas (mover mouse) |
| `Ctrl+F12` | Ajustar velocidade do Modo Setas (DPI 1..50) |
| `Alt+F12` | Define velocidade em 8 dpi |
| `Ctrl+Ins` | Diminuir 1 ponto na velocidade |
| `Alt+Ins` | Aumentar 1 ponto na velocidade |
| `F1` | Clique direito (no Modo Setas) |
| `F2` | Clique esquerdo (no Modo Setas) |
| `Ctrl` + `Setas` | Arrastar (segura clique esquerdo enquanto move) |
| `Alt+-` | Scroll horizontal esquerda (no Modo Setas) |
| `Alt+=` | Scroll horizontal direita (no Modo Setas) |
| `F3` | Ajuda (LazyWindow) |
| `F10` | Ajuda de atalhos do Microsoft Teams |
| `F11` | Ajuda de atalhos do LazyVim |
| `[` | Scroll para cima |
| `]` | Scroll para baixo |
| `Ctrl +` | Zoom + (Ctrl+Scroll) |
| `Ctrl -` | Zoom - (Ctrl+Scroll) |
| `F7` | Maximizar janela ativa |
| `F6` | Minimizar janela ativa |
| `F8` | Fechar janela ativa |
| `Ctrl+F6` | Print da janela ativa (clipboard + salva PNG em `~\.screenshot`) |
| `Ctrl+Shift+B` | Beautify clipboard (formata JSON/XML/YAML automaticamente) |
| `Ctrl+Shift+A` | Encode clipboard para Base64 |
| `Ctrl+Alt+A` | Decode Base64 do clipboard |
| `Ctrl+Shift+T` | Data para Epoch (clipboard vazio = agora) |
| `Ctrl+Alt+T` | Epoch para Data ISO 8601 |
| `Ctrl+Alt+F10` | Snippet Manager (gestor de snippets de código) |
| `Ctrl+1..9` | Salvar posição do mouse no marcador |
| `Alt+1..9` | Mover cursor para o marcador |
| `Ctrl+Alt+1..9` | Mover e clicar no marcador |
| `A/S/D` | Selecionar célula linha 1 |
| `Z/X/C` | Selecionar célula linha 2 |
| `Enter` | Clique direito |
| `Backspace` | Clique esquerdo |
| `ESC` | Cancelar/Fechar |

---

## 📄 Licença

MIT License - Veja [LICENSE](LICENSE) para detalhes.

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor, abra uma issue ou pull request.
