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
│   │   └── LazyVimHelpWindow.ahk # Atalhos do LazyVim (F11)
│   ├── snippets/
│   │   ├── SnippetManager.ahk # GUI do gestor de snippets (Ctrl+Alt+F10)
│   │   ├── SnippetStore.ahk   # Armazena e carrega snippets
│   │   └── ContextDetector.ahk # Detecta linguagem e palavra sob cursor
│   └── utils/
│       ├── Monitor.ahk       # Detecção e informações de monitores
│       ├── ScreenshotRegion.ahk # Seleção interativa de região para screenshot
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
2. Verifique a StatusBar acima da taskbar (exibe "Cursor: Desligado | Vel: 25 dpi")
3. Pressione `Ctrl+End` para testar grid no monitor 1
4. Navegue com `A/S/D/Z/X/C`
5. Pressione `Backspace` para clique esquerdo
6. Pressione `Ctrl+Home` para testar seletor de janelas
7. Pressione `Ctrl+PgUp` para testar grid na janela ativa
8. Pressione `Alt+PgUp` para testar grid ao redor do cursor
9. Pressione `Alt+Home` para ativar Modo Setas e verificar StatusBar atualiza
10. Pressione `Shift+End` para testar toggle de velocidade 5 dpi
11. Pressione `Ctrl+Alt+F10` para testar Snippet Manager
12. Pressione `F3` para ver a ajuda completa
