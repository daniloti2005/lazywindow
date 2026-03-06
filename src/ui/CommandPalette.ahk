#Requires AutoHotkey v2.0

class CommandPalette {
    static gui := ""
    static listView := ""
    static searchEdit := ""
    static footerText := ""
    static isVisible := false
    static commands := []
    static filtered := []
    static wasArrowMouseOn := false

    static Init() {
        this.RegisterCommands()
    }

    static RegisterCommands() {
        this.commands := []

        ; -- Grid (sempre ativo) --
        this.Add("Grid Monitor 1", "Ctrl+End", "Ativa grid no monitor 1", (*) => ActivateGrid(1))
        this.Add("Grid Monitor 2", "Ctrl+Del", "Ativa grid no monitor 2", (*) => ActivateGrid(2))
        this.Add("Grid Monitor 3", "Ctrl+PgDn", "Ativa grid no monitor 3", (*) => ActivateGrid(3))
        this.Add("Grid Janela Ativa", "Ctrl+PgUp", "Ativa grid na janela ativa", (*) => ActivateGridOnWindow())
        this.Add("Grid Cursor (400px)", "Alt+PgUp", "Grid 400x400px ao redor do cursor", (*) => ActivateGridAroundCursor())

        ; -- Toggle --
        this.Add("Toggle Comandos ON/OFF", "Alt+Home", "Liga/desliga todos os comandos e modo setas", (*) => ArrowMouse.Toggle())

        ; -- Ajuda (sempre ativo) --
        this.Add("Ajuda LazyWindow", "F3", "Janela de ajuda completa", (*) => HelpWindow.Toggle())
        this.Add("Ajuda Microsoft Teams", "F10", "Atalhos do Microsoft Teams", (*) => TeamsHelpWindow.Toggle())
        this.Add("Ajuda LazyVim/Neovim", "F11", "Atalhos do LazyVim", (*) => LazyVimHelpWindow.Toggle())

        ; -- Janelas --
        this.Add("Seletor de Janelas", "Ctrl+Home", "Alternar foco entre janelas abertas", (*) => OpenWindowSwitcher())
        this.Add("Maximizar Janela", "F7", "Maximiza a janela ativa", (*) => WinMaximize("A"))
        this.Add("Minimizar Janela", "F6", "Minimiza a janela ativa", (*) => WinMinimize("A"))
        this.Add("Fechar Janela", "F8", "Fecha a janela ativa", (*) => WinClose("A"))

        ; -- Velocidade do Mouse --
        this.Add("Velocidade Mouse (Modal)", "Ctrl+F12", "Modal para ajustar DPI 1-50", (*) => SpeedDialog.Show())
        this.Add("Velocidade 8 dpi", "Alt+F12", "Define velocidade fixa 8 dpi", (*) => SetSpeed8())
        this.Add("Diminuir Velocidade (-1)", "Ctrl+Ins", "Diminui 1 dpi na velocidade", (*) => DecreaseSpeed())
        this.Add("Aumentar Velocidade (+1)", "Alt+Ins", "Aumenta 1 dpi na velocidade", (*) => IncreaseSpeed())
        this.Add("Toggle 5 dpi", "Shift+End", "Alterna entre 5 dpi e velocidade anterior", (*) => ArrowMouse.ToggleSpeed5())

        ; -- Screenshot --
        this.Add("Print Janela Ativa", "Ctrl+F6", "Captura janela ativa (clipboard + arquivo)", (*) => TakeActiveWindowShot())
        this.Add("Print Janela (Caminho)", "Ctrl+Shift+F6", "Caminho do arquivo no clipboard", (*) => TakeWindowShotPathOnly())
        this.Add("Screenshot Região", "Ctrl+F7", "Selecionar região (clipboard + arquivo)", (*) => TakeRegionShot())
        this.Add("Screenshot Região (Caminho)", "Ctrl+Shift+F7", "Caminho da região no clipboard", (*) => TakeRegionShotPathOnly())

        ; -- Utilitários DevOps --
        this.Add("Beautify JSON/XML/YAML", "Ctrl+Shift+B", "Formata conteúdo do clipboard", (*) => CodeBeautify.Beautify())
        this.Add("Base64 Encode", "Ctrl+Shift+A", "Codifica clipboard em Base64", (*) => Base64.Encode())
        this.Add("Base64 Decode", "Ctrl+Alt+A", "Decodifica Base64 do clipboard", (*) => Base64.Decode())
        this.Add("Data para Epoch", "Ctrl+Shift+T", "Converte data para Unix timestamp", (*) => Timestamp.ToEpoch())
        this.Add("Epoch para Data", "Ctrl+Alt+T", "Converte timestamp para ISO 8601", (*) => Timestamp.FromEpoch())

        ; -- Snippets --
        this.Add("Snippet Manager", "Ctrl+Alt+F10", "Gestor de snippets de código", (*) => SnippetManager.Toggle())

        ; -- Project Bookmarks --
        this.Add("Project Bookmarks", "Ctrl+Shift+O", "Abrir lista de projetos marcados", (*) => ProjectBookmarks.Toggle())
        this.Add("Quick-Add Projeto", "Ctrl+Alt+O", "Adiciona pasta atual do terminal como projeto", (*) => ProjectBookmarks.QuickAddFromTerminal())

        ; -- Prompt Manager --
        this.Add("Prompt Manager", "Ctrl+Shift+F8", "Gerenciar prompts de terminal", (*) => PromptManager.Toggle())
        this.Add("Quick-Apply Prompt", "Ctrl+F8", "Aplica prompt favorito no terminal ativo", (*) => PromptManager.QuickApply())
        this.Add("Quick-Save Prompt", "Ctrl+Alt+F8", "Salva prompt atual do terminal ativo", (*) => PromptManager.QuickSave())

        ; -- Story Telling --
        this.Add("Story Telling", "Ctrl+F4", "Documentar história com evidências e contexto", (*) => StoryTelling.Toggle())
        this.Add("Quick-Add Passo", "Ctrl+Shift+F4", "Adiciona clipboard como evidência do próximo passo", (*) => StoryTelling.QuickAdd())
        this.Add("Flush Prompt", "Ctrl+Alt+F4", "Gera prompt com a história completa para clipboard", (*) => StoryTelling.Flush())

        ; -- Download Version Manager --
        this.Add("Download Version Manager", "Ctrl+Shift+D", "Versionar duplicatas da pasta Downloads", (*) => DownloadVersionManager.Toggle())

        ; -- Sistema --
        this.Add("Recarregar LazyWindow", "", "Recarrega o script completamente", (*) => Reload())
        this.Add("Sair do LazyWindow", "", "Encerra o aplicativo", (*) => ExitApp())
    }

    static Add(name, hotkey, description, action) {
        this.commands.Push({name: name, hotkey: hotkey, description: description, action: action})
    }

    static Toggle() {
        if (this.isVisible) {
            this.Hide()
        } else {
            this.Show()
        }
    }

    static Show() {
        if (this.isVisible) {
            this.Hide()
            return
        }

        ; Pause ArrowMouse if active to free arrow keys
        if (ArrowMouse.IsEnabled()) {
            this.wasArrowMouseOn := true
            ArrowMouse.PauseForSwitcher()
        } else {
            this.wasArrowMouseOn := false
        }

        if (this.commands.Length = 0) {
            this.RegisterCommands()
        }

        this.CreateGui()
        this.isVisible := true
    }

    static Hide() {
        try Hotkey("*Enter", "Off")
        try Hotkey("Up", "Off")
        try Hotkey("Down", "Off")
        if (this.gui) {
            this.gui.Destroy()
            this.gui := ""
        }
        this.isVisible := false

        ; Resume ArrowMouse if it was paused
        if (this.wasArrowMouseOn) {
            this.wasArrowMouseOn := false
            ArrowMouse.Enable()
        }
    }

    static CreateGui() {
        this.gui := Gui("+AlwaysOnTop -MinimizeBox +ToolWindow", "LazyWindow - Command Palette")
        this.gui.BackColor := "1B2838"

        this.gui.SetFont("s11 c7EB8DA", "Cascadia Code")
        this.gui.AddText("x10 y10 w580", "Digite para buscar comandos (↑↓ navegar, Enter executar):")

        this.gui.SetFont("s12 cA8D8B9", "Cascadia Code")
        this.searchEdit := this.gui.AddEdit("x10 y40 w580 h30 Background152230")
        this.searchEdit.OnEvent("Change", (*) => this.OnSearchChange())

        this.gui.SetFont("s10 cD0D8E0", "Cascadia Code")
        this.listView := this.gui.AddListView("x10 y80 w580 h340 +Report -Multi -E0x200 +LV0x10020 Background0D1926 c7EB8DA", ["Nome", "Hotkey", "Descrição"])
        this.listView.ModifyCol(1, 190)
        this.listView.ModifyCol(2, 120)
        this.listView.ModifyCol(3, 250)
        DllCall("uxtheme\SetWindowTheme", "Ptr", this.listView.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
        SendMessage(0x1001, 0, 0x26190D, this.listView)
        SendMessage(0x1026, 0, 0x26190D, this.listView)
        SendMessage(0x1024, 0, 0xDAB87E, this.listView)
        this.listView.OnEvent("DoubleClick", (*) => this.Execute())

        this.gui.SetFont("s9 c5A7A94", "Cascadia Code")
        this.footerText := this.gui.AddText("x10 y425 w580 h20", this.commands.Length " comandos disponíveis")

        ; Populate with all commands
        this.filtered := this.commands.Clone()
        this.PopulateList()

        this.gui.OnEvent("Escape", (*) => this.Hide())
        this.gui.OnEvent("Close", (*) => this.Hide())

        this.gui.Show("w600 h450")
        this.searchEdit.Focus()

        ; Temporary hotkeys while palette is open
        Hotkey("*Enter", (*) => this.Execute(), "On")
        Hotkey("Up", (*) => this.NavigateList(-1), "On")
        Hotkey("Down", (*) => this.NavigateList(1), "On")
    }

    static PopulateList() {
        this.listView.Delete()
        for cmd in this.filtered {
            this.listView.Add("", cmd.name, cmd.hotkey, cmd.description)
        }
        if (this.filtered.Length > 0) {
            this.listView.Modify(1, "Select Focus Vis")
        }
    }

    static OnSearchChange() {
        query := Trim(this.searchEdit.Value)

        if (query = "") {
            this.filtered := this.commands.Clone()
        } else {
            this.filtered := []
            queryLower := StrLower(query)
            words := StrSplit(queryLower, " ")

            for cmd in this.commands {
                searchText := StrLower(cmd.name . " " . cmd.hotkey . " " . cmd.description)
                allMatch := true
                for word in words {
                    if (word != "" && !InStr(searchText, word)) {
                        allMatch := false
                        break
                    }
                }
                if (allMatch) {
                    this.filtered.Push(cmd)
                }
            }
        }

        this.PopulateList()
        this.footerText.Value := this.filtered.Length " de " this.commands.Length " comandos"
    }

    static NavigateList(direction) {
        if (this.filtered.Length = 0) {
            return
        }

        currentRow := this.listView.GetNext(0, "Focused")
        if (currentRow = 0) {
            currentRow := 1
        }

        newRow := currentRow + direction
        if (newRow < 1)
            newRow := this.filtered.Length
        if (newRow > this.filtered.Length)
            newRow := 1

        this.listView.Modify(currentRow, "-Select -Focus")
        this.listView.Modify(newRow, "Select Focus Vis")

        ; Keep focus on search edit so user can keep typing
        this.searchEdit.Focus()
    }

    static Execute() {
        selectedRow := this.listView.GetNext(0, "Focused")
        if (selectedRow = 0 && this.filtered.Length > 0) {
            selectedRow := 1
        }
        if (selectedRow = 0 || selectedRow > this.filtered.Length) {
            return
        }

        cmd := this.filtered[selectedRow]
        this.Hide()
        Sleep(50)

        try {
            cmd.action.Call()
        } catch as e {
            ToolTip("Erro ao executar: " cmd.name)
            SetTimer(() => ToolTip(), -2500)
        }
    }
}
