#Requires AutoHotkey v2.0

class HelpWindow {
    static gui := ""
    static edit := ""
    static footer := ""
    static isVisible := false
    static wasArrowMouseOn := false

    static Toggle() {
        if (this.isVisible) {
            this.Hide()
        } else {
            this.Show()
        }
    }

    static Show() {
        ; If ArrowMouse is active, disable it while Help is open to avoid conflicts.
        if (ArrowMouse.IsEnabled()) {
            this.wasArrowMouseOn := true
            ArrowMouse.Disable()
        } else {
            this.wasArrowMouseOn := false
        }

        if (!this.gui) {
            this.CreateGui()
        }

        this.edit.Value := this.GetHelpText()
        this.ShowFullScreen()
        this.edit.Focus()
        this.isVisible := true
    }

    static Hide() {
        if (this.gui) {
            try this.gui.Hide()
        }
        this.isVisible := false

        if (this.wasArrowMouseOn) {
            this.wasArrowMouseOn := false
            ArrowMouse.Enable()
        }
    }

    static CreateGui() {
        this.gui := Gui("+AlwaysOnTop +ToolWindow +Resize", "LazyWindow - Ajuda")
        this.gui.Opt("-DPIScale")
        this.gui.BackColor := "1a1a2e"
        this.gui.SetFont("s10 cFFFFFF", "Consolas")

        this.edit := this.gui.AddEdit("x10 y10 w740 h460 +ReadOnly +VScroll +Multi -Wrap")
        this.edit.Opt("Background16213e")

        this.gui.SetFont("s10 cFFFFFF", "Segoe UI")
        this.footer := this.gui.AddText("x10 y478 w740", "Use [ / ] (scroll), PgUp/PgDn ou a barra de rolagem | ESC fecha")

        this.gui.OnEvent("Size", (guiObj, minMax, width, height) => this.OnResize(width, height))
        this.gui.OnEvent("Escape", (*) => this.Hide())
        this.gui.OnEvent("Close", (*) => this.Hide())
    }

    static ShowFullScreen() {
        monitorNum := this.GetMonitorFromMouse()
        work := Monitor.GetWorkArea(monitorNum)
        if (!work) {
            this.gui.Show("Maximize")
            return
        }

        this.gui.Show("x" work.x " y" work.y " w" work.width " h" work.height)
        this.OnResize(work.width, work.height)
        WinMaximize("ahk_id " this.gui.Hwnd)
    }

    static OnResize(width, height) {
        margin := 10
        footerH := 26
        editW := Max(50, width - (margin * 2))
        editH := Max(50, height - (margin * 2) - footerH)

        try this.edit.Move(margin, margin, editW, editH)
        try this.footer.Move(margin, height - footerH - margin, editW)
    }

    static GetMonitorFromMouse() {
        MouseGetPos(&mx, &my)
        cnt := Monitor.GetCount()
        Loop cnt {
            b := Monitor.GetBounds(A_Index)
            if (b && mx >= b.x && mx < b.right && my >= b.y && my < b.bottom) {
                return A_Index
            }
        }
        try return MonitorGetPrimary()
        return 1
    }

    static GetHelpText() {
        help := "
(
LAZYWINDOW - AJUDA (ROLAVEL)

BARRA SUPERIOR (STATUS):
  ON | Vel: XX dpi | ...     (quando comandos ligados)
  OFF | Alt+Home=LIGAR       (quando comandos desligados)

TOGGLE GERAL (Alt+Home):
  Alt+Home    = Liga/Desliga TODOS os comandos abaixo
  Ao iniciar, todos os comandos estao DESLIGADOS.
  Grid (Ctrl+End/Del/PgDn/PgUp), Alt+PgUp, F3/F10/F11 funcionam sempre.

GRID DE NAVEGACAO (MATRIZ) [SEMPRE ATIVO]:
  Ctrl+End    = Ativar grid no Monitor 1
  Ctrl+Del    = Ativar grid no Monitor 2
  Ctrl+PgDn   = Ativar grid no Monitor 3
  Ctrl+PgUp   = Ativar grid na janela ativa
  Alt+PgUp    = Ativar grid ao redor do cursor (400x400px)

  Navegacao no grid:
    A S D       = Selecionar celula superior
    Z X C       = Selecionar celula inferior

  Acoes no grid:
    Backspace   = Clique esquerdo no centro da area atual
    Enter       = Clique direito no centro da area atual
    ESC         = Cancelar/fechar grid

SELETOR DE JANELAS [requer Alt+Home]:
  Ctrl+Home   = Abrir seletor (mostra # | Processo | Titulo)
  Digite: [numero][posicao] e Enter

  Posicoes:
    C = Centro
    T = Topo
    E = Esquerda
    D = Direita
    R = Rodape

  Combinacoes (2 letras):
    TE = topo-esquerda
    TD = topo-direita
    RE = rodape-esquerda
    RD = rodape-direita

  Exemplos:
    1     = janela 1 (centro)
    2C    = janela 2 (centro)
    3RD   = janela 3 (rodape-direita)

MODO SETAS (MOVER MOUSE) [requer Alt+Home]:
  Alt+Home    = Liga/Desliga todos os comandos + modo setas
  Setas       = Move o mouse (segure 2 setas para diagonal 45)
  Ctrl + Setas = Arrastar (segura clique esquerdo enquanto move)
  Soltar Ctrl = Soltar o arrasto

  Cliques (quando Modo Setas esta ativo):
    F1         = Clique direito
    F2         = Clique esquerdo

  Scroll horizontal (quando Modo Setas esta ativo):
    Alt+-      = Scroll para esquerda
    Alt+=      = Scroll para direita

  Velocidade do Modo Setas:
    Ctrl+F12    = Abre modal para digitar DPI 1..50
    Alt+F12     = Define velocidade em 8 dpi
    Ctrl+Ins    = Diminuir 1 ponto na velocidade
    Alt+Ins     = Aumentar 1 ponto na velocidade
    Shift+End   = Toggle velocidade 5 dpi (alterna com anterior)

SCROLL [requer Alt+Home]:
  [           = Scroll para cima
  ]           = Scroll para baixo

ZOOM [requer Alt+Home]:
  Ctrl +      = Zoom +
  Ctrl -      = Zoom -

JANELA ATIVA [requer Alt+Home]:
  F7          = Maximizar
  F6          = Minimizar
  F8          = Fechar
  Ctrl+F6     = Print da janela ativa (clipboard + arquivo em ~\.screenshot)
  Ctrl+Shift+F6 = Print da janela ativa (caminho do arquivo no clipboard)
  Ctrl+F7     = Selecionar região com mouse (imagem no clipboard + arquivo)
  Ctrl+Shift+F7 = Selecionar região com mouse (caminho do arquivo no clipboard)

MARCADORES DE POSICAO [requer Alt+Home]:
  Ctrl+1..9   = Salvar posicao atual no marcador
  Alt+1..9    = Mover cursor para o marcador
  Ctrl+Alt+1..9 = Mover e clicar no marcador
  (marcadores persistem em ~/.lazywindow/markers.json)

BEAUTIFY CODIGO [requer Alt+Home]:
  Ctrl+Shift+B = Formata o conteudo do clipboard e sobrescreve
                 (detecta JSON, XML ou YAML automaticamente)

BASE64 [requer Alt+Home]:
  Ctrl+Shift+A = Encode texto do clipboard para Base64
  Ctrl+Alt+A   = Decode Base64 do clipboard para texto

TIMESTAMP [requer Alt+Home]:
  Ctrl+Shift+T = Data para Epoch (clipboard vazio = agora)
  Ctrl+Alt+T   = Epoch para Data ISO 8601

AJUDA [SEMPRE ATIVO]:
  F3          = Abre/Fecha esta janela
  F10         = Ajuda de atalhos do Microsoft Teams
  F11         = Ajuda de atalhos do LazyVim

SNIPPET MANAGER [requer Alt+Home]:
  Ctrl+Alt+F10 = Abre/Fecha o Snippet Manager

COMMAND PALETTE [requer Alt+Home]:
  Ctrl+Shift+P = Abre busca unificada de todos os comandos
                 Digite para filtrar, setas para navegar, Enter para executar

PROJECT BOOKMARKS [requer Alt+Home]:
  Ctrl+Shift+O = Abre lista de projetos (fullscreen)
                 Digite [numero][acao] + Enter:
                   1 ou 1N = nvim no projeto 1
                   2S = shell (terminal) no projeto 2
                   3R = remover projeto 3
                   4G = editar tag do projeto 4
                   5P = mudar perfil do terminal do projeto 5
                   A = adicionar projeto (digitar caminho)
                   B = browse pasta (selecionar pasta)
                   Texto livre = filtrar por nome/caminho
                 Terminal por projeto = perfil do Windows Terminal
                 Ordenado por ultimo aberto (mais recente primeiro)
                 Persistido em ~/.lazywindow/projects.json
  Ctrl+Alt+O  = Quick-add: marca pasta atual do terminal como projeto

PROMPT MANAGER [requer Alt+Home]:
  Ctrl+Shift+F8 = Abre gestor de prompts (fullscreen)
                  Digite [numero][acao] + Enter:
                    1 ou 1A = aplicar prompt 1 na sessao (temporario)
                    1W = persistir prompt 1 no arquivo de config
                         PowerShell: escreve no $PROFILE
                         Bash: escreve no ~/.bashrc (user/root/ambos)
                    2E = editar codigo do prompt 2
                    3D = deletar prompt 3 (so custom)
                    4F = toggle favorito do prompt 4
                    5S = definir prompt 5 como default
                    N = novo prompt customizado
                  13 prompts built-in:
                    PS: Minimal, Git Branch, Timestamp, Jedi, Sith, Powerline, Dragon Ball
                    Bash: Minimal, Git Color, Jedi, Sith, Powerline, Dragon Ball
                  Dragon Ball: auto-detect user/root (Goku ↔ Super Saiyan)
  Ctrl+F8     = Quick-Apply: aplica prompt favorito/default no terminal
  Ctrl+Alt+F8 = Quick-Save: captura prompt atual do terminal e salva
  (persistido em ~/.lazywindow/prompts.json)

SNIPPET MANAGER [requer Alt+Home]:
  Ctrl+Alt+F10 = Abre/Fecha o Snippet Manager
  
  Linguagens suportadas: TypeScript, Python, SQL, PowerShell, Bash, Go, Windows
  
  Snippets incluidos:
    - SOLID (SRP, OCP, LSP, ISP, DIP com exemplos)
    - Clean Code (Guard Clauses, Extract Method, Null Object, Constants)
    - Design Patterns (Singleton, Factory, Observer)
    - TypeScript (Interface, Async/Await, React useState)
    - Python (Class, Dataclass)
    - SQL (SELECT JOIN, CTE)
    - PowerShell (Try-Catch, REST API)
    - Bash (Function, AWS CLI)
    - Go (Struct, HTTP Handler)
    - Windows (ms-settings URIs, comandos de sistema, rede, dispositivos, apps, shell)
  
  Como usar:
    1. Selecione uma palavra (nome de classe/funcao) no editor
    2. Pressione Ctrl+Alt+F10
    3. O sistema detecta a linguagem pela janela ativa
    4. Busque ou navegue pelos snippets
    5. Pressione Enter para inserir (substitui placeholders)
  
  Placeholders automaticos:
    - ${ClassName}, ${FunctionName} = palavra selecionada
    - ${date} = data atual
    - ${user} = nome do usuario

NOTA: Enter funciona normalmente em qualquer aplicacao com cursor ligado.
      O LazyWindow usa pass-through para nao bloquear o Enter do sistema.
)"
        return Trim(help)
    }
}
