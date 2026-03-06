#Requires AutoHotkey v2.0

class TeamsHelpWindow {
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
        this.gui := Gui("+AlwaysOnTop +ToolWindow +Resize", "Microsoft Teams - Atalhos")
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
MICROSOFT TEAMS - ATALHOS (WINDOWS) - AJUDA (ROLAVEL)

Fonte: lista de atalhos dentro do Teams (Ctrl+.) e documentacao oficial da Microsoft.
Observacao: alguns atalhos variam no Teams Web e podem ser personalizados.

GERAL
  Ctrl+.               = Mostrar atalhos de teclado
  Ctrl+N               = Novo chat
  Ctrl+Shift+N         = Novo chat em nova janela
  Ctrl+,               = Configuracoes
  F1                   = Ajuda
  Esc                  = Fechar/voltar
  Ctrl+E               = Ir para Pesquisar
  Ctrl+Shift+F         = Abrir filtro

NAVEGACAO (BARRA LATERAL)
  Ctrl+1 .. Ctrl+9      = Abrir o 1o..9o app na barra
    * Dica: se voce reordenou os apps, a posicao muda.
  Ctrl+F6               = Proxima secao
  Ctrl+Shift+F6         = Secao anterior
  Alt+Seta esquerda     = Voltar
  Alt+Seta direita      = Avancar

MENSAGENS / CHAT
  Ctrl+R               = Ir para caixa de composicao
  Ctrl+Shift+X         = Expandir caixa de composicao
  Ctrl+Enter           = Enviar mensagem
  Shift+Enter          = Nova linha
  Ctrl+F               = Pesquisar no chat/canal atual
  Ctrl+K               = Inserir link
  Ctrl+Shift+I         = Marcar como importante
  Ctrl+J               = Pular para ultima mensagem nao lida/mais recente

REUNIOES / LIGACOES (DURANTE CHAMADA)
  Ctrl+Shift+M         = Alternar mudo (microfone)
  Win+Alt+K            = Alternar mudo (atalho global, quando suportado)
  Ctrl+Barra de espaco = Desmutar temporariamente (push-to-talk)
  Ctrl+Shift+O         = Alternar video (camera)
  Ctrl+Shift+K         = Levantar/baixar a mao
  Ctrl+Shift+L         = Anunciar maos levantadas (leitor de tela)

CHAMADAS (ATENDER / RECUSAR / ENCERRAR)
  Ctrl+Shift+A         = Aceitar chamada de video
  Ctrl+Shift+S         = Aceitar chamada de audio
  Ctrl+Shift+D         = Recusar chamada
  Ctrl+Shift+H         = Encerrar chamada (audio/video)

CALENDARIO (ALGUNS)
  Ctrl+3               = Abrir calendario (padrao, se estiver na 3a posicao)
  Ctrl+O               = Criar novo compromisso/evento
  Enter                = Abrir item selecionado
  Delete               = Excluir item selecionado

DICA PARA TODOS OS ATALHOS:
  Use Ctrl+. dentro do Teams para ver a lista completa e atualizada.
)"
        return Trim(help)
    }
}
