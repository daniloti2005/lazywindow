# LazyWindow - Copilot Context

## Sobre o Projeto

LazyWindow é um aplicativo de acessibilidade para Windows escrito em **AutoHotkey v2** que permite controlar o mouse usando apenas o teclado através de um sistema de grid recursivo.

## Tecnologia

- **Linguagem:** AutoHotkey v2 (NÃO v1)
- **Plataforma:** Windows 10/11
- **Paradigma:** Orientado a objetos (classes AHK v2)

## Estrutura do Projeto

```
lazywindow/
├── src/
│   ├── main.ahk              # Entry point - inicialização e hotkeys principais
│   ├── grid/
│   │   ├── GridOverlay.ahk   # Classe GUI do overlay semi-transparente
│   │   └── GridNavigation.ahk # Lógica de navegação e subdivisão recursiva
│   ├── window/
│   │   ├── WindowSwitcher.ahk # Seletor de janelas (mostra processo + título)
│   │   └── WindowList.ahk    # Enumeração de janelas abertas
│   ├── mouse/
│   │   ├── MouseController.ahk # Movimentação, cliques e SmoothMove humanizado
│   │   ├── ArrowMouse.ahk    # Modo setas para mover mouse
│   │   └── MouseMarkers.ahk  # 9 marcadores de posição persistentes
│   ├── ui/
│   │   ├── StatusBar.ahk     # Barra de status acima da taskbar (sempre visível)
│   │   ├── SpeedDialog.ahk   # Modal para ajustar velocidade do Modo Setas
│   │   ├── HelpWindow.ahk    # Janela de ajuda principal (F3)
│   │   ├── TeamsHelpWindow.ahk # Atalhos do Microsoft Teams (F10)
│   │   ├── LazyVimHelpWindow.ahk # Atalhos do LazyVim (F11)
│   │   ├── CommandPalette.ahk # Busca unificada de comandos (Ctrl+Shift+P)
│   │   ├── ProjectBookmarks.ahk # Marcadores de projetos (Ctrl+Shift+O)
│   │   └── PromptManager.ahk  # Gestor de prompts de terminal (Ctrl+Shift+F8)
│   ├── snippets/
│   │   ├── SnippetManager.ahk # GUI do gestor de snippets (Ctrl+Alt+F10)
│   │   ├── SnippetStore.ahk   # Armazena e carrega snippets
│   │   └── ContextDetector.ahk # Detecta linguagem e palavra sob cursor
│   └── utils/
│       ├── Monitor.ahk       # Detecção e informações de monitores
│       ├── ScreenshotRegion.ahk # Seleção interativa de região para screenshot
│       └── GifRecorder.ahk      # Gravação de tela como GIF animado (segue monitor do mouse)
│       ├── CodeBeautify.ahk  # Formatador JSON/XML/YAML
│       ├── Base64.ahk        # Encode/Decode Base64
│       └── Timestamp.ahk     # Conversor Epoch <-> Data
├── README.md
├── ToggleLazyWindow.ps1      # Script para ligar/desligar LazyWindow
└── .github/
    └── copilot-instructions.md
```

## Convenções de Código

### AutoHotkey v2

```autohotkey
; Classes usam PascalCase
class GridOverlay {
    ; Propriedades
    x := 0
    y := 0
    width := 0
    height := 0
    
    ; Construtor
    __New(x, y, width, height) {
        this.x := x
        this.y := y
        this.width := width
        this.height := height
    }
    
    ; Métodos
    Show() {
        ; implementação
    }
}

; Variáveis locais usam camelCase
myVariable := "value"

; Hotkeys
^End::ActivateGrid(1)  ; Ctrl+End

; Funções
ActivateGrid(monitorNumber) {
    ; implementação
}
```

### Padrões Importantes

1. **Sempre usar AHK v2 syntax** - Não usar comandos v1 obsoletos
2. **GUI com classes** - Usar `Gui()` constructor, não comando `Gui`
3. **Hotkeys condicionais** - Usar `#HotIf` não `#IfWinActive`
4. **Strings** - Aspas obrigatórias para strings
5. **Expressões** - Usar `:=` para atribuições

## Funcionalidades Principais

### Grid Navigation (Navegação por Matriz)

- **Propósito:** Dividir tela em grid 2x3 recursivo para posicionamento preciso
- **Hotkeys de ativação:**
  - `Ctrl+End` → Monitor 1
  - `Ctrl+Del` → Monitor 2
  - `Ctrl+PgDn` → Monitor 3
  - `Ctrl+PgUp` → Janela ativa
  - `Alt+PgUp` → Área 400x400px ao redor do cursor
- **Layout do grid:**
  ```
  | A | S | D |
  | Z | X | C |
  ```
- **Ações:**
  - `Enter` → Clique direito no centro
  - `Backspace` → Clique esquerdo no centro
  - `ESC` → Cancelar

### Window Switcher (Seletor de Janelas)

- **Propósito:** Trocar foco entre janelas e posicionar mouse
- **Hotkey:** `Ctrl+Home`
- **Exibe:** # | Processo | Título da janela
- **Posições do mouse:**
  - `C` = Centro
  - `T` = Topo
  - `E` = Esquerda
  - `D` = Direita
  - `R` = Rodapé
- **Combinações:** `TE`, `TD`, `RE`, `RD`

### Toggle Global de Comandos

- **Hotkey:** `Alt+Home` (liga/desliga TODOS os comandos + Modo Setas)
- **Estado inicial:** Desligado — ao iniciar, apenas Grid, Ajuda e `Alt+Home` estão ativos
- **Implementação:** Variável `g_hotkeysEnabled` + `#HotIf` no `main.ahk`
- **Sempre ativos:** Grid (Ctrl+End/Del/PgDn/PgUp), Alt+PgUp, F3/F10/F11, Alt+Home
- **Pass-through Enter:** `~*Enter::return` dentro do bloco `#HotIf` garante que Enter chega às aplicações mesmo com cursor ligado (o keyboard hook do AHK pode suprimir teclas quando muitos hotkeys `*` estão ativos)

### Arrow Mouse (Modo Setas)

- **Hotkey:** `Alt+Home` (toggle — liga/desliga junto com todos os comandos)
- **Movimento:** Setas movem o mouse continuamente; duas setas simultâneas = diagonal normalizada
- **Velocidade:** `Ctrl+F12` (modal 1–50 dpi), `Alt+F12` (8 dpi fixo), `Ctrl+Ins`/`Alt+Ins` (±1 dpi), `Shift+End` (toggle 5 dpi / restaura anterior)
- **Cliques:** `F1` (direito), `F2` (esquerdo)
- **Arrastar:** `Ctrl+Setas` (segura clique esquerdo enquanto move)
- **Scroll horizontal:** `Alt+-` (esq), `Alt+=` (dir)

### Mouse Markers (Marcadores)

- **Salvar:** `Ctrl+1..9`
- **Ir para:** `Alt+1..9`
- **Ir e clicar:** `Ctrl+Alt+1..9`
- **Persistência:** `~/.lazywindow/markers.json`

### Utilitários para DevOps

- **Code Beautify:** `Ctrl+Shift+B` - Formata JSON/XML/YAML do clipboard
- **Base64:** `Ctrl+Shift+A` (encode), `Ctrl+Alt+A` (decode)
- **Timestamp:** `Ctrl+Shift+T` (data→epoch), `Ctrl+Alt+T` (epoch→data)
- **Screenshot:** `Ctrl+F6` (janela ativa → clipboard + PNG), `Ctrl+Shift+F6` (janela ativa → PNG + caminho no clipboard), `Ctrl+F7` (seleção de região → clipboard + PNG), `Ctrl+Shift+F7` (seleção de região → PNG + caminho no clipboard)
- **GIF Recorder:** `Ctrl+Shift+F5` (iniciar gravação, 50% resolução, 15 FPS, máx 5 min), `Ctrl+F5` (parar e copiar caminho). Segue o mouse entre monitores. Cursor do mouse e cliques (círculo amarelo) aparecem no GIF. Fallback System.Drawing se FFmpeg ausente.

### StatusBar (Barra de Status)

- **Módulo:** `ui/StatusBar.ahk`
- **Propósito:** Barra semi-transparente sempre visível acima da taskbar do monitor primário
- **Exibe:** Estado dos comandos (ON/OFF), velocidade atual em dpi quando ligado
- **Atualização:** Refresca a cada 200 ms via `SetTimer`
- **Inicialização:** Chamada em `main.ahk` via `StatusBar.Init()`

### Snippet Manager (Gestor de Snippets)

- **Hotkey:** `Ctrl+Alt+F10`
- **Propósito:** Inserir snippets de código com placeholders automáticos
- **Linguagens:** TypeScript, Python, SQL, PowerShell, Bash, Go, Windows
- **Modos de busca:** `Nome` (busca por nome/descrição) e `Código` (busca no conteúdo do snippet) — alternável pelo botão ou `Tab`
- **Snippets incluídos:**
  - SOLID: SRP, OCP, LSP, ISP, DIP (com exemplos práticos)
  - Clean Code: Guard Clauses, Extract Method, Null Object, Constants
  - Design Patterns: Singleton, Factory, Observer
  - TypeScript: Interface, Async/Await, React useState
  - Python: Class, Dataclass
  - SQL: SELECT JOIN, CTE
  - PowerShell: Try-Catch, REST API
  - Bash: Function, AWS CLI
  - Go: Struct, HTTP Handler
  - Windows: ms-settings URIs, comandos de sistema, rede, dispositivos, apps, shell
- **Detecção automática:** Linguagem baseada no título da janela
- **Placeholders:** `${ClassName}`, `${FunctionName}`, `${date}`, `${user}` → substituídos pela palavra selecionada / data / usuário

### Command Palette (Busca Unificada)

- **Hotkey:** `Ctrl+Shift+P` (requer `g_hotkeysEnabled`)
- **Propósito:** Campo de busca fuzzy que lista todos os comandos do LazyWindow pelo nome, hotkey e descrição
- **Módulo:** `ui/CommandPalette.ahk`
- **Funcionalidades:**
  - Filtro multi-palavras em tempo real (ex: "base64 encode", "grid mon")
  - Navegação com ↑↓ mantendo foco no campo de busca
  - Enter executa o comando selecionado, ESC fecha
  - DoubleClick na lista também executa
  - Footer mostra "X de Y comandos" ao filtrar
  - Pausa ArrowMouse automaticamente ao abrir
- **Registro de comandos:** Todos os comandos são registrados em `Init()` via `this.Add(nome, hotkey, descrição, ação)`
- **Inicialização:** Chamada em `main.ahk` via `CommandPalette.Init()`

### Project Bookmarks (Marcadores de Projetos)

- **Hotkey:** `Ctrl+Shift+O` (requer `g_hotkeysEnabled`)
- **Quick-Add:** `Ctrl+Alt+O` — adiciona pasta atual do terminal ativo como projeto (detecta shell pelo título do WT, obtém path via clipboard)
- **Propósito:** Lista persistente de projetos de software para abertura rápida no Neovim ou terminal via Windows Terminal
- **Módulo:** `ui/ProjectBookmarks.ahk`
- **GUI:** Janela fullscreen, input por `[nº][letra]` + Enter (estilo WindowSwitcher)
- **Funcionalidades:**
  - Adicionar projetos via input manual (`A`) ou browse de pasta (`B`)
  - Cada projeto tem: nome, caminho, tag e **perfil do Windows Terminal**
  - Perfis do WT detectados automaticamente do `settings.json` (PowerShell, Ubuntu, Fedora, etc.)
  - Tipo Windows/WSL inferido pelo perfil — determina como o wt.exe abre:
    - **Windows:** `wt.exe -p "PowerShell" -d "C:\path" pwsh -NoExit -Command "nvim ."`
    - **WSL:** `wt.exe -p "Ubuntu 22.04.3 LTS" wsl -e bash -c "cd ~/path && nvim ."`
  - Ações por input: `1N`=nvim, `2S`=shell, `3R`=remover, `4G`=tag, `5P`=perfil
  - Busca por nome/caminho (texto livre), filtro por tag (dropdown)
  - Ordenação automática por último aberto (mais recente primeiro)
  - Exibe tempo desde última abertura (agora, 2h, 3d, 1sem, 2mes)
  - Migração automática de projetos com shell antigo (powershell/wsl → perfil real)
- **Persistência:** `~/.lazywindow/projects.json`
- **Inicialização:** Chamada em `main.ahk` via `ProjectBookmarks.Init()`

### Prompt Manager (Gestor de Prompts)

- **Hotkeys:** `Ctrl+Shift+F8` (GUI), `Ctrl+F8` (quick-apply), `Ctrl+Alt+F8` (quick-save) — requerem `g_hotkeysEnabled`
- **Propósito:** Salvar, visualizar e aplicar prompts customizados no terminal ativo
- **Módulo:** `ui/PromptManager.ahk`
- **GUI:** Janela fullscreen, input por `[nº][letra]` + Enter (estilo ProjectBookmarks)
- **Funcionalidades:**
  - 13 prompts built-in: Minimal, Git Branch, Timestamp, 💻 Modern, ⚔ Star Wars, ⚡ Powerline, 🐉 Dragon Ball (PowerShell) + Minimal Color, Git Color, 🐧 Modern, ⚔ Star Wars, ⚡ Powerline, 🐉 Dragon Ball (Bash)
  - Modern: powerline com duração do último comando, git branch, user/host/hora
    - PS: segmentos azul (esq) + marrom (dir), right-aligned, seta powerline (E0B0)
    - Bash: segmentos verde (esq) + marrom (dir), timer via trap DEBUG + PROMPT_COMMAND
  - Star Wars e Dragon Ball: auto-detect user/root (Bash) ou normal/admin (PowerShell)
  - Animações ASCII full-screen (6 frames, ~17s) ao virar root/admin — uma vez por sessão:
    - Star Wars: Anakin → Conflito Luz/Trevas → Queda → Cirurgia → Vader Rises → Close-up Vader
    - Dragon Ball: Goku/Nimbus → 7 Esferas → Céu Escurece → Shenlong Emerge → Shenlong Full → Poder Total
  - Ações por input: `1A`=sessão, `1W`=persistir, `2E`=editar, `3D`=deletar, `4F`=favorito, `5S`=default, `N`=novo
  - `W` (Write): persiste prompt permanentemente no arquivo de config:
    - PowerShell: escreve no `$PROFILE` (remove anterior + appenda + dot-source)
    - Bash user: escreve no `~/.bashrc` (remove anterior + appenda via temp file + cat)
    - Bash root: escreve no `/root/.bashrc` via sudo tee
    - Para Bash, pergunta destino: User / Root / Ambos
  - Quick-Apply (`Ctrl+F8`): aplica prompt favorito/default no terminal ativo sem abrir GUI
  - Quick-Save (`Ctrl+Alt+F8`): captura prompt atual do terminal e salva
  - Detecta tipo de shell (PowerShell/Bash) pelo título do Windows Terminal
  - Apply envia comando direto ao terminal via SendInput({Text}) para enviar literalmente
  - PowerShell: `function prompt { ... }`, Bash: `export PS1='...'`
- **Persistência:** `~/.lazywindow/prompts.json`
- **Inicialização:** Chamada em `main.ahk` via `PromptManager.Init()`

## Guia de Implementação

### Criar GUI Semi-Transparente

```autohotkey
class GridOverlay {
    gui := ""
    
    __New(x, y, w, h) {
        this.gui := Gui("+AlwaysOnTop -Caption +ToolWindow")
        this.gui.BackColor := "000000"
        this.gui.Show("x" x " y" y " w" w " h" h " NoActivate")
        WinSetTransparent(150, this.gui)
    }
    
    Destroy() {
        this.gui.Destroy()
    }
}
```

### Detectar Monitores

```autohotkey
GetMonitorBounds(monitorNum) {
    if (monitorNum > MonitorGetCount()) {
        return false
    }
    MonitorGet(monitorNum, &left, &top, &right, &bottom)
    return {x: left, y: top, width: right - left, height: bottom - top}
}
```

### Mover e Clicar Mouse

```autohotkey
class MouseController {
    static MoveTo(x, y) {
        MouseMove(x, y)
    }
    
    static LeftClick() {
        Click("Left")
    }
    
    static RightClick() {
        Click("Right")
    }
    
    static SmoothMove(targetX, targetY, duration := 200) {
        ; Ease-in-out movement for humanized motion
        MouseGetPos(&startX, &startY)
        steps := Max(20, duration // 4)
        Loop steps {
            t := A_Index / steps
            progress := t < 0.5 ? 2 * t * t : 1 - ((-2 * t + 2) ** 2) / 2
            MouseMove(startX + (targetX - startX) * progress, startY + (targetY - startY) * progress)
            Sleep(duration // steps)
        }
        MouseMove(targetX, targetY)
    }
}
```

### Listar Janelas

```autohotkey
GetWindowList() {
    windows := []
    for hwnd in WinGetList() {
        title := WinGetTitle(hwnd)
        if (title != "" && WinGetStyle(hwnd) & 0x10000000) {  ; WS_VISIBLE
            windows.Push({hwnd: hwnd, title: title})
        }
    }
    return windows
}
```

## Regras ao Gerar Código

1. **Sempre testar se monitor existe** antes de ativar grid
2. **Sempre destruir GUI anterior** antes de criar nova
3. **Não bloquear hotkeys do sistema** - usar `~` prefix se necessário
4. **Tratar DPI scaling** - usar `A_ScreenDPI` quando relevante
5. **Manter estado global mínimo** - preferir classes e instâncias

## Testes

Para testar manualmente:
1. Execute `src/main.ahk` ou use `ToggleLazyWindow.ps1`
2. Verifique a StatusBar acima da taskbar (exibe "OFF | Alt+Home=LIGAR | F3=AJUDA")
3. Pressione `Alt+Home` para ligar todos os comandos (StatusBar muda para "ON | Vel: 25 dpi | ...")
4. **Teste Enter pass-through:** com cursor ligado, pressione Enter em qualquer app (ex: chat/browser) — deve funcionar normalmente
5. Pressione `Ctrl+End` para testar grid no monitor 1
6. Navegue com `A/S/D/Z/X/C`
7. Pressione `Backspace` para clique esquerdo
8. Pressione `Ctrl+Home` para testar seletor de janelas
9. Pressione `Ctrl+PgUp` para testar grid na janela ativa
10. Pressione `Alt+PgUp` para testar grid ao redor do cursor
11. Pressione `Shift+End` para testar toggle de velocidade 5 dpi
12. Pressione `Ctrl+F7` para testar screenshot por região (clique e arraste)
13. Pressione `Ctrl+Shift+F7` para testar screenshot por região (caminho no clipboard)
14. Pressione `Ctrl+Shift+F5` para testar gravação GIF (mova o mouse e depois pare com `Ctrl+F5`)
15. Pressione `Ctrl+Alt+F10` para testar Snippet Manager
15. Pressione `Ctrl+Shift+P` para testar Command Palette (buscar "grid", "base64", etc.)
16. Pressione `Ctrl+Shift+O` para testar Project Bookmarks (adicionar projeto, abrir com nvim)
17. Pressione `Ctrl+Shift+F8` para testar Prompt Manager (aplicar prompt, criar custom)
18. Pressione `Ctrl+F8` no terminal para testar Quick-Apply de prompt
19. Pressione `F3` para ver a ajuda completa
20. Pressione `Alt+Home` para desligar todos os comandos e verificar StatusBar volta a "OFF"
