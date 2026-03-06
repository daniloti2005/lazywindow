#Requires AutoHotkey v2.0

class LazyVimHelpWindow {
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
        this.gui := Gui("+AlwaysOnTop +ToolWindow +Resize", "LazyVim - Ajuda")
        this.gui.Opt("-DPIScale")
        this.gui.BackColor := "1B2838"
        this.gui.SetFont("s10 cD0D8E0", "Cascadia Code")

        this.edit := this.gui.AddEdit("x10 y10 w740 h460 +ReadOnly +VScroll +Multi -Wrap")
        this.edit.Opt("Background0D1926")

        this.gui.SetFont("s10 c5A7A94", "Cascadia Code")
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
        WinSetTransparent(215, this.gui)
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
LAZYVIM - AJUDA (ROLAVEL)

IMPORTANTE:
  - LazyVim e uma distribuicao do Neovim: atalhos podem variar conforme plugins/extras e sua configuracao.
  - Para ver *todos* os atalhos reais no seu LazyVim, use as secoes 'Como listar atalhos' abaixo.

NOTACAO:
  <leader>      = Space (padrao do LazyVim)
  <localleader> = \ (frequentemente, pode variar)
  <C-x>         = Ctrl+x
  <S-x>         = Shift+x
  Modo Normal/Insercao/Visual: muitos atalhos dependem do modo.

COMO LISTAR TODOS OS ATALHOS (NO PROPRIO LAZYVIM):
  1) WhichKey (descobrir menus por tecla):
     - Pressione <leader> e espere o popup (ou digite mais teclas)
     - :WhichKey

  2) Telescope - Keymaps (lista pesquisavel):
     - :Telescope keymaps

  3) Mapas do Vim (texto puro):
     - :map      (todos)
     - :nmap     (normal)   | :imap (insert) | :vmap (visual) | :cmap (command)
     - :verbose nmap <tecla>   (mostra de onde veio o mapeamento)

  4) Ajuda interna do Neovim:
     - :help key-notation
     - :help index

ATALHOS MAIS USADOS (CHEAT SHEET - PADROES COMUNS DO LAZYVIM):

  GERAL
    :q / :qa        = sair
    :w              = salvar
    :wq             = salvar e sair
    u               = desfazer
    <C-r>           = refazer

  MOVIMENTOS (NORMAL)
    h j k l         = esquerda/baixo/cima/direita
    w / b           = proxima/anterior palavra
    gg / G          = inicio/fim do arquivo
    0 / ^ / $       = inicio da linha / 1o caractere / fim da linha
    f{char}         = vai ate o caractere na linha
    /texto          = buscar
    n / N           = proxima/anterior ocorrencia

  JANELAS (SPLITS)
    <C-w>v          = split vertical
    <C-w>s          = split horizontal
    <C-w>h/j/k/l    = mover foco entre splits
    <C-w>c          = fechar split atual

  BUFFERS / ARQUIVOS (LAZYVIM)
    <leader>ff      = procurar arquivos (find files)
    <leader>fg      = procurar texto (live grep)
    <leader>fb      = buffers abertos
    <leader>fr      = arquivos recentes
    <leader>e       = explorador de arquivos (Neo-tree)
    <S-h> / <S-l>   = buffer anterior / proximo (comum em configs LazyVim)
    <leader>bd      = fechar buffer (delete)

  LSP / CODIGO (NORMAL)
    K               = hover / documentacao
    gd              = ir para definicao
    gD              = ir para declaracao
    gr              = referencias
    gi              = implementacao
    <leader>ca      = code action
    <leader>cr      = rename
    <leader>cf      = formatar (pode variar)

  DIAGNOSTICOS
    ]d / [d         = proximo/anterior diagnostico
    <leader>cd      = diagnosticos (pode variar)

  GIT (COMUM NO LAZYVIM)
    <leader>gg      = LazyGit (se disponivel)
    ]h / [h         = proximo/anterior hunk (gitsigns)
    <leader>gh      = acoes de hunk (pode variar)

DICAS RAPIDAS:
  - Se voce nao lembra um atalho: <leader> (WhichKey) + digite a proxima letra e veja as opcoes.
  - Para descobrir exatamente o que uma tecla faz: :verbose nmap <tecla>
)"
        return Trim(help)
    }
}
