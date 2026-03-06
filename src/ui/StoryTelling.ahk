; StoryTelling.ahk — Menu de Histórias com Evidências para análise por IA
; Permite documentar fluxos passo a passo com evidências e contexto narrativo
; Gera prompt formatado para colar no chat da IA
; Usa state machine inline — sem InputBox (Enter hotkey bloquearia dialogs)

class StoryTelling {
    static gui := ""
    static listView := ""
    static inputBox := ""
    static headerCtrl := ""
    static helpCtrl := ""
    static footerText := ""
    static promptLabel := ""
    ; Modal overlay controls
    static modalBg := ""
    static modalLabel := ""
    static modalInput := ""
    static modalHint := ""
    static modalVisible := false
    static stories := []
    static activeIndex := 0      ; index into stories[] (1-based)
    static configDir := ""
    static configPath := ""
    static isVisible := false

    ; State machine: "normal", "naming", "context", "editing", "listing"
    static mode := "normal"
    static pendingEvidence := ""
    static pendingType := ""
    static editingStep := 0

    static Init() {
        this.configDir := EnvGet("USERPROFILE") "\.lazywindow"
        this.configPath := this.configDir "\stories.json"
        this.Load()
    }

    static Toggle() {
        if (this.isVisible)
            this.Hide()
        else
            this.Show()
    }

    static Show() {
        if (this.gui) {
            try this.gui.Destroy()
            this.gui := ""
        }
        this.mode := "normal"
        this.modalVisible := false
        this.CreateGui()
        this.isVisible := true
    }

    static Hide() {
        if (this.gui) {
            try Hotkey("*Enter", "Off")
            try this.gui.Destroy()
            this.gui := ""
        }
        this.mode := "normal"
        this.modalVisible := false
        this.isVisible := false
    }

    ; ── Quick-Add: cola clipboard como evidência + pede contexto ──
    static QuickAdd() {
        clip := A_Clipboard
        if (clip = "") {
            ToolTip("Clipboard vazio — copie uma evidência primeiro")
            SetTimer(() => ToolTip(), -2000)
            return
        }
        if (this.stories.Length = 0) {
            this.stories.Push({name: "História " FormatTime(, "yyyyMMdd_HHmmss"), createdAt: this._Now(), steps: []})
            this.activeIndex := 1
        }
        type := this._DetectType(clip)
        story := this.stories[this.activeIndex]
        story.steps.Push({order: story.steps.Length + 1, type: type, evidence: clip, context: "(sem contexto)"})
        this.Persist()
        ToolTip("Passo " story.steps.Length " adicionado (" type ") — abra Ctrl+F4 para editar contexto")
        SetTimer(() => ToolTip(), -3000)
        if (this.isVisible)
            this.PopulateList()
    }

    ; ── Flush: gerar prompt e copiar para clipboard ──
    static Flush() {
        if (this.stories.Length = 0 || this.activeIndex < 1) {
            ToolTip("Nenhuma história ativa")
            SetTimer(() => ToolTip(), -2000)
            return
        }
        story := this.stories[this.activeIndex]
        if (story.steps.Length = 0) {
            ToolTip("História sem passos — adicione evidências primeiro")
            SetTimer(() => ToolTip(), -2000)
            return
        }
        prompt := this._GeneratePrompt(story)
        A_Clipboard := prompt
        ToolTip("Prompt copiado para clipboard (" story.steps.Length " passos)")
        SetTimer(() => ToolTip(), -3000)
    }

    ; ══════════════════════════════════════════════════════════════
    ; GUI
    ; ══════════════════════════════════════════════════════════════

    static CreateGui() {
        this.gui := Gui("+AlwaysOnTop +ToolWindow +Resize +OwnDialogs", "📖 StoryTelling — LazyWindow")
        this.gui.Opt("-DPIScale")
        this.gui.BackColor := "1B2838"

        ; ── Title bar ──
        this.gui.SetFont("s14 cE8EDF3 Bold", "Cascadia Code")
        this.headerCtrl := this.gui.AddText("x20 y12 w1800", "")
        this._RefreshHeader()

        ; ── Separator line ──
        this.gui.SetFont("s6 c3A5068", "Consolas")
        this.gui.AddText("x20 y42 w1800", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        ; ── Input area (commands only — normal/listing modes) ──
        this.gui.SetFont("s12 c7EB8DA", "Cascadia Code")
        this.promptLabel := this.gui.AddText("x20 y55 w110 h30 +0x200", "❯ Comando")
        this.gui.SetFont("s12 cA8D8B9", "Cascadia Code")
        this.inputBox := this.gui.AddEdit("x140 y53 w500 h30 Background152230 cA8D8B9 -E0x200")

        ; ── Dynamic command help panel ──
        this.gui.SetFont("s9 c5A7A94", "Cascadia Code")
        this.helpCtrl := this.gui.AddText("x20 y88 w1800", "")

        ; ── Separator ──
        this.gui.SetFont("s6 c2A3F54", "Consolas")
        this.gui.AddText("x20 y106 w1800", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        ; ── ListView ──
        this.gui.SetFont("s11 cD0D8E0", "Cascadia Code")
        this.listView := this.gui.AddListView("x20 y118 w1800 h570 +Report -Multi -E0x200 +LV0x10020 Background0D1926 c7EB8DA"
            , ["#", "Tipo", "Evidência", "Contexto"])
        this._StyleDarkListView(this.listView)
        this.listView.ModifyCol(1, 45)
        this.listView.ModifyCol(2, 80)
        this.listView.ModifyCol(3, 700)
        this.listView.ModifyCol(4, 900)

        ; ── Modal overlay (hidden — appears over ListView for text input) ──
        this.modalBg := this.gui.AddText("x20 y118 w1800 h570 Background0D1926 +Hidden", "")
        this.gui.SetFont("s16 c7EB8DA Bold", "Cascadia Code")
        this.modalLabel := this.gui.AddText("x300 y280 w1200 h35 +Center +Hidden +BackgroundTrans", "")
        this.gui.SetFont("s14 cA8D8B9", "Cascadia Code")
        this.modalInput := this.gui.AddEdit("x300 y325 w1200 h35 Background152230 cA8D8B9 -E0x200 +Hidden", "")
        this.gui.SetFont("s10 c5A7A94", "Cascadia Code")
        this.modalHint := this.gui.AddText("x300 y370 w1200 h25 +Center +Hidden +BackgroundTrans", "")

        ; ── Footer / Status bar ──
        this.gui.SetFont("s10 c5A7A94", "Cascadia Code")
        this.footerText := this.gui.AddText("x20 y700 w1800 h25", "")

        this.inputBox.OnEvent("Change", (*) => this._OnInputChange())
        this.gui.OnEvent("Size", (g, m, w, h) => this._OnResize(w, h))
        this.gui.OnEvent("Escape", (*) => this._OnEscape())
        this.gui.OnEvent("Close", (*) => this.Hide())

        this.PopulateList()
        this._UpdateHelp()
        this._ShowFullScreen()
        this.inputBox.Focus()
        Hotkey("*Enter", (*) => this._Execute(), "On")
    }

    ; ── Dynamic help text based on mode ──

    static _UpdateHelp() {
        if (!this.helpCtrl)
            return
        switch this.mode {
            case "listing":
                this.helpCtrl.Value := "  [nº] Ativar história    [nº]R Remover história    ESC Voltar aos passos"
            default:
                this.helpCtrl.Value := "  N Nova    A Evidência    L Histórias    F Flush    [nº]E Editar    [nº]V Ver    [nº]U ↑    [nº]D ↓    [nº]R Remover    ESC Sair"
        }
    }

    ; ── Modal overlay methods ──

    static _ShowModal(title, hint, defaultText := "") {
        this.modalVisible := true
        this.modalBg.Visible := true
        this.modalLabel.Visible := true
        this.modalLabel.Value := title
        this.modalInput.Visible := true
        this.modalInput.Value := defaultText
        this.modalHint.Visible := true
        this.modalHint.Value := hint
        ; Hide command input
        this.inputBox.Visible := false
        this.promptLabel.Visible := false
        this.helpCtrl.Value := ""
        ; Focus modal input and select all
        this.modalInput.Focus()
        SendMessage(0x00B1, 0, -1, this.modalInput)
    }

    static _HideModal() {
        this.modalVisible := false
        this.modalBg.Visible := false
        this.modalLabel.Visible := false
        this.modalInput.Visible := false
        this.modalHint.Visible := false
        this.modalInput.Value := ""
        ; Restore command input
        this.inputBox.Visible := true
        this.promptLabel.Visible := true
        this.inputBox.Value := ""
        this.promptLabel.Value := "❯ Comando"
        this._UpdateHelp()
        this.inputBox.Focus()
    }

    static _RefreshHeader() {
        if (!this.headerCtrl)
            return
        storyName := this.activeIndex > 0 ? this.stories[this.activeIndex].name : "(nenhuma)"
        this.headerCtrl.Value := "📖 STORY TELLING  ·  " storyName
    }

    static _ShowFullScreen() {
        monNum := this._GetMonitorFromMouse()
        MonitorGetWorkArea(monNum, &wL, &wT, &wR, &wB)
        w := wR - wL
        h := wB - wT
        this.gui.Show("x" wL " y" wT " w" w " h" h)
        WinMaximize("ahk_id " this.gui.Hwnd)
        WinSetTransparent(215, this.gui)
    }

    static _StyleDarkListView(lv) {
        ; DarkMode_Explorer: dark headers, dark scrollbars (Win10/11)
        DllCall("uxtheme\SetWindowTheme", "Ptr", lv.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
        ; BG #0D1926 → BGR 0x26190D
        SendMessage(0x1001, 0, 0x26190D, lv)   ; LVM_SETBKCOLOR
        SendMessage(0x1026, 0, 0x26190D, lv)   ; LVM_SETTEXTBKCOLOR
        ; Text #7EB8DA → BGR 0xDAB87E
        SendMessage(0x1024, 0, 0xDAB87E, lv)   ; LVM_SETTEXTCOLOR
    }

    static _GetMonitorFromMouse() {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mx, &my)
        count := MonitorGetCount()
        Loop count {
            MonitorGet(A_Index, &l, &t, &r, &b)
            if (mx >= l && mx < r && my >= t && my < b)
                return A_Index
        }
        return MonitorGetPrimary()
    }

    static _OnResize(w, h) {
        if (!this.listView)
            return
        try {
            listH := h - 170
            this.listView.Move(20, 118, w - 40, listH)
            this.footerText.Move(20, h - 38, w - 40, 25)
            colW := w - 40 - 45 - 80 - 20
            this.listView.ModifyCol(3, Round(colW * 0.45))
            this.listView.ModifyCol(4, Round(colW * 0.55))
            ; Modal overlay follows ListView area
            this.modalBg.Move(20, 118, w - 40, listH)
            mX := Round(w * 0.15)
            mW := Round(w * 0.7)
            mY := 118 + Round(listH / 2) - 50
            this.modalLabel.Move(mX, mY, mW, 35)
            this.modalInput.Move(mX, mY + 45, mW, 35)
            this.modalHint.Move(mX, mY + 90, mW, 25)
        }
    }

    static _OnEscape() {
        if (this.modalVisible) {
            ; Close modal and return to previous state
            this._HideModal()
            if (this.mode = "naming" || this.mode = "context" || this.mode = "editing") {
                this.mode := "normal"
                this.PopulateList()
            }
            return
        }
        if (this.mode = "listing") {
            this.mode := "normal"
            this.inputBox.Value := ""
            this.promptLabel.Value := "❯ Comando"
            this.PopulateList()
        } else {
            this.Hide()
        }
    }

    static PopulateList() {
        if (!this.listView)
            return
        this.listView.Delete()
        this._UpdateHelp()
        if (this.activeIndex < 1 || this.activeIndex > this.stories.Length) {
            this.footerText.Value := "  Nenhuma história ativa  ·  N + Enter para criar"
            return
        }
        story := this.stories[this.activeIndex]
        for step in story.steps {
            evidPreview := StrLen(step.evidence) > 80 ? SubStr(step.evidence, 1, 80) "…" : step.evidence
            evidPreview := StrReplace(evidPreview, "`n", " ")
            ctxPreview := StrLen(step.context) > 100 ? SubStr(step.context, 1, 100) "…" : step.context
            ctxPreview := StrReplace(ctxPreview, "`n", " ")
            this.listView.Add("", A_Index, step.type, evidPreview, ctxPreview)
        }
        this.footerText.Value := "  " story.steps.Length " passos  ·  📖 " story.name "  ·  F Flush prompt → clipboard"
    }

    ; ══════════════════════════════════════════════════════════════
    ; Input Handling — State Machine
    ; ══════════════════════════════════════════════════════════════

    static _OnInputChange() {
        if (this.mode != "normal")
            return
        text := this.inputBox.Value
        if (RegExMatch(text, "^(\d+)", &match)) {
            num := Integer(match[1])
            if (this.activeIndex > 0 && num >= 1 && num <= this.stories[this.activeIndex].steps.Length)
                this.listView.Modify(num, "Select Focus Vis")
        }
    }

    static _Execute() {
        if (!this.isVisible)
            return

        ; Route: modal input for naming/context/editing, command input for normal/listing
        if (this.modalVisible) {
            text := Trim(this.modalInput.Value)
        } else {
            text := Trim(this.inputBox.Value)
        }

        ; Handle state machine modes
        switch this.mode {
            case "naming":
                this._FinishNaming(text)
                return
            case "context":
                this._FinishContext(text)
                return
            case "editing":
                this._FinishEditing(text)
                return
            case "listing":
                this._FinishListing(text)
                return
        }

        ; Normal mode
        this.inputBox.Value := ""
        if (text = "")
            return

        upper := StrUpper(text)

        ; Single-letter commands
        if (upper = "N") {
            this._StartNaming()
            return
        }
        if (upper = "A") {
            this._StartAddStep()
            return
        }
        if (upper = "L") {
            this._StartListing()
            return
        }
        if (upper = "F") {
            this.Flush()
            return
        }

        ; Number + letter commands: 1E, 2U, 3D, etc.
        if (RegExMatch(upper, "^(\d+)([EUVDR])$", &m)) {
            num := Integer(m[1])
            cmd := m[2]
            if (this.activeIndex < 1) {
                this.footerText.Value := "⚠ Nenhuma história ativa — pressione N"
                return
            }
            story := this.stories[this.activeIndex]
            if (num < 1 || num > story.steps.Length) {
                this.footerText.Value := "⚠ Passo " num " não existe (total: " story.steps.Length ")"
                return
            }
            switch cmd {
                case "E": this._StartEditing(num)
                case "V": this._CmdViewEvidence(num)
                case "U": this._CmdMoveUp(num)
                case "D": this._CmdMoveDown(num)
                case "R": this._CmdRemoveStep(num)
            }
            return
        }
    }

    ; ── State: Naming (create new story) ──

    static _StartNaming() {
        this.mode := "naming"
        this._ShowModal("✦ Nome da Nova História", "Enter confirmar  ·  ESC cancelar")
    }

    static _FinishNaming(text) {
        this.mode := "normal"
        this._HideModal()
        if (Trim(text) = "")
            text := "História " FormatTime(, "yyyyMMdd_HHmmss")
        story := {name: Trim(text), createdAt: this._Now(), steps: []}
        this.stories.Push(story)
        this.activeIndex := this.stories.Length
        this.Persist()
        this._RefreshHeader()
        this.PopulateList()
    }

    ; ── State: Add step (open evidence picker) ──

    static _StartAddStep() {
        if (this.stories.Length = 0) {
            this.footerText.Value := "⚠ Crie uma história primeiro  ·  N + Enter"
            return
        }
        ; Disable our Enter hotkey before opening picker
        try Hotkey("*Enter", "Off")
        ; Open evidence picker
        EvidencePicker.Show(
            (item) => this._OnEvidenceSelected(item),
            () => this._OnEvidenceCancelled()
        )
    }

    static _OnEvidenceSelected(item) {
        ; Re-enable our Enter hotkey
        Hotkey("*Enter", (*) => this._Execute(), "On")
        this.pendingType := item.type
        this.pendingEvidence := item.path
        this.mode := "context"
        evidPreview := StrLen(item.path) > 60 ? SubStr(item.path, 1, 60) "..." : item.path
        evidPreview := StrReplace(evidPreview, "`n", " ")
        this._ShowModal("✦ Contexto — " item.type, "📎 " evidPreview "  ·  Enter confirmar  ·  ESC cancelar")
    }

    static _OnEvidenceCancelled() {
        ; Re-enable our Enter hotkey and return to normal
        Hotkey("*Enter", (*) => this._Execute(), "On")
        this.mode := "normal"
        this._UpdateHelp()
        this.inputBox.Value := ""
        this.promptLabel.Value := "❯ Comando"
        this.inputBox.Focus()
    }

    static _FinishContext(text) {
        this.mode := "normal"
        this._HideModal()
        if (Trim(text) = "")
            text := "(sem contexto)"
        story := this.stories[this.activeIndex]
        story.steps.Push({order: story.steps.Length + 1, type: this.pendingType, evidence: this.pendingEvidence, context: Trim(text)})
        this.pendingEvidence := ""
        this.pendingType := ""
        this.Persist()
        this.PopulateList()
    }

    ; ── State: Editing context ──

    static _StartEditing(num) {
        this.mode := "editing"
        this.editingStep := num
        story := this.stories[this.activeIndex]
        step := story.steps[num]
        this._ShowModal("✎ Editando Contexto — Passo " num, "Enter salvar  ·  ESC cancelar", step.context)
    }

    static _FinishEditing(text) {
        num := this.editingStep
        this.mode := "normal"
        this._HideModal()
        this.editingStep := 0
        if (this.activeIndex < 1)
            return
        story := this.stories[this.activeIndex]
        if (num < 1 || num > story.steps.Length)
            return
        story.steps[num].context := Trim(text)
        this.Persist()
        this.PopulateList()
    }

    ; ── State: Listing stories ──

    static _StartListing() {
        if (this.stories.Length = 0) {
            this.footerText.Value := "⚠ Nenhuma história salva  ·  N + Enter para criar"
            return
        }
        this.mode := "listing"
        this.inputBox.Value := ""
        this.promptLabel.Value := "✦ Nº"
        this._UpdateHelp()
        this.listView.Delete()
        for i, s in this.stories {
            marker := (i = this.activeIndex) ? "● ATIVA" : ""
            this.listView.Add("", i, marker, s.name, s.steps.Length " passos  ·  " s.createdAt)
        }
        this.footerText.Value := this.stories.Length " histórias"
    }

    static _FinishListing(text) {
        upper := StrUpper(Trim(text))

        ; Support [nº]R to remove a story from listing mode
        if (RegExMatch(upper, "^(\d+)R$", &m)) {
            num := Integer(m[1])
            if (num >= 1 && num <= this.stories.Length) {
                this.stories.RemoveAt(num)
                if (this.activeIndex > this.stories.Length)
                    this.activeIndex := this.stories.Length
                else if (this.activeIndex = num)
                    this.activeIndex := this.stories.Length > 0 ? Min(num, this.stories.Length) : 0
                else if (this.activeIndex > num)
                    this.activeIndex--
                this.Persist()
                this._RefreshHeader()
                if (this.stories.Length > 0) {
                    this._StartListing()
                } else {
                    this.mode := "normal"
                    this.promptLabel.Value := "❯ Comando"
                    this.inputBox.Value := ""
                    this.PopulateList()
                }
            } else {
                this.footerText.Value := "⚠ História " num " não existe (total: " this.stories.Length ")"
                this.inputBox.Value := ""
            }
            return
        }

        this.mode := "normal"
        this.promptLabel.Value := "❯ Comando"
        this.inputBox.Value := ""
        num := 0
        try num := Integer(Trim(text))
        if (num >= 1 && num <= this.stories.Length) {
            this.activeIndex := num
            this.Persist()
            this._RefreshHeader()
        }
        this.PopulateList()
    }

    ; ── Immediate commands (no state change) ──

    static _CmdViewEvidence(num) {
        story := this.stories[this.activeIndex]
        step := story.steps[num]
        this.listView.Delete()
        lines := StrSplit(SubStr(step.evidence, 1, 3000), "`n")
        this.listView.Add("", "", step.type, "── EVIDÊNCIA DO PASSO " num " ──", step.context)
        for i, line in lines {
            this.listView.Add("", "", "", StrReplace(line, "`r", ""), "")
        }
        this.footerText.Value := "Visualizando passo " num " (" step.type ") | Pressione ESC para voltar"
        this.mode := "listing"  ; ESC will return to normal and repopulate
    }

    static _CmdMoveUp(num) {
        if (num <= 1)
            return
        story := this.stories[this.activeIndex]
        temp := story.steps[num]
        story.steps[num] := story.steps[num - 1]
        story.steps[num - 1] := temp
        this._ReorderSteps(story)
        this.Persist()
        this.PopulateList()
    }

    static _CmdMoveDown(num) {
        story := this.stories[this.activeIndex]
        if (num >= story.steps.Length)
            return
        temp := story.steps[num]
        story.steps[num] := story.steps[num + 1]
        story.steps[num + 1] := temp
        this._ReorderSteps(story)
        this.Persist()
        this.PopulateList()
    }

    static _CmdRemoveStep(num) {
        story := this.stories[this.activeIndex]
        story.steps.RemoveAt(num)
        this._ReorderSteps(story)
        this.Persist()
        this.PopulateList()
    }

    static _ReorderSteps(story) {
        for i, step in story.steps {
            step.order := i
        }
    }

    ; ══════════════════════════════════════════════════════════════
    ; Helpers
    ; ══════════════════════════════════════════════════════════════

    static _DetectType(text) {
        clean := Trim(text)
        if (DirExist(clean))
            return "Pasta"
        if (FileExist(clean)) {
            SplitPath(clean, , , &ext)
            if (RegExMatch(ext, "i)^(png|jpg|jpeg|gif|bmp|webp)$"))
                return "Imagem"
            return "Arquivo"
        }
        return "Texto"
    }

    static _Now() {
        return FormatTime(, "yyyy-MM-ddTHH:mm:ss")
    }

    ; ══════════════════════════════════════════════════════════════
    ; Prompt Generation (Flush)
    ; ══════════════════════════════════════════════════════════════

    static _GeneratePrompt(story) {
        prompt := "# História: " story.name "`n`n"
        prompt .= "Analise esta história passo a passo. Cada passo contém uma evidência (texto, imagem ou pasta de imagens) e o contexto explicativo do usuário.`n`n"

        for i, step in story.steps {
            prompt .= "## Passo " i "`n"
            prompt .= "**Contexto:** " step.context "`n"

            switch step.type {
                case "Texto":
                    prompt .= "**Evidência (Texto):**`n``````n" step.evidence "`n```````n"
                case "Imagem":
                    prompt .= "**Evidência (Imagem):** ``" step.evidence "```n"
                    prompt .= "→ Leia esta imagem com a ferramenta view para analisar o conteúdo visual.`n"
                case "Pasta":
                    prompt .= "**Evidência (Pasta de imagens):** ``" step.evidence "```n"
                    prompt .= "→ Liste os arquivos desta pasta e leia as imagens em sequência para analisar o fluxo visual.`n"
                case "Arquivo":
                    prompt .= "**Evidência (Arquivo):** ``" step.evidence "```n"
                    prompt .= "→ Leia este arquivo para analisar o conteúdo.`n"
                default:
                    prompt .= "**Evidência:** " step.evidence "`n"
            }
            prompt .= "`n"
        }

        prompt .= "---`n"
        prompt .= "Por favor, analise todos os passos em ordem e forneça uma análise completa da história com base nas evidências e contextos apresentados.`n"
        return prompt
    }

    ; ══════════════════════════════════════════════════════════════
    ; Persistence (JSON)
    ; ══════════════════════════════════════════════════════════════

    static Persist() {
        DirCreate(this.configDir)
        json := '{"activeIndex": ' this.activeIndex ', "stories": ['
        for i, story in this.stories {
            if (i > 1)
                json .= ","
            json .= '{"name": "' this._EscJson(story.name) '", "createdAt": "' story.createdAt '", "steps": ['
            for j, step in story.steps {
                if (j > 1)
                    json .= ","
                json .= '{"order": ' step.order ', "type": "' this._EscJson(step.type) '", '
                json .= '"evidence": "' this._EscJson(step.evidence) '", '
                json .= '"context": "' this._EscJson(step.context) '"}'
            }
            json .= "]}"
        }
        json .= "]}"

        f := FileOpen(this.configPath, "w", "UTF-8")
        f.Write(json)
        f.Close()
    }

    static Load() {
        this.stories := []
        this.activeIndex := 0
        if (!FileExist(this.configPath))
            return

        try {
            content := FileRead(this.configPath, "UTF-8")
        } catch {
            return
        }

        ; Extract activeIndex
        if (RegExMatch(content, '"activeIndex"\s*:\s*(\d+)', &m))
            this.activeIndex := Integer(m[1])

        ; Parse stories
        pos := 1
        while (pos := InStr(content, '"name"', , pos)) {
            if (!RegExMatch(content, '"name"\s*:\s*"((?:[^"\\]|\\.)*)"', &mName, pos))
                break
            name := this._UnescJson(mName[1])

            createdAt := ""
            if (RegExMatch(content, '"createdAt"\s*:\s*"([^"]*)"', &mCA, pos))
                createdAt := mCA[1]

            stepsStart := InStr(content, '"steps"', , pos)
            if (!stepsStart)
                break
            bracketStart := InStr(content, "[", , stepsStart)
            if (!bracketStart)
                break

            depth := 1
            bracketEnd := bracketStart
            Loop {
                bracketEnd++
                if (bracketEnd > StrLen(content))
                    break
                ch := SubStr(content, bracketEnd, 1)
                if (ch = "[")
                    depth++
                else if (ch = "]") {
                    depth--
                    if (depth = 0)
                        break
                }
            }

            stepsJson := SubStr(content, bracketStart, bracketEnd - bracketStart + 1)

            steps := []
            stepPos := 1
            while (stepPos := InStr(stepsJson, '"order"', , stepPos)) {
                order := 0
                if (RegExMatch(stepsJson, '"order"\s*:\s*(\d+)', &mOrd, stepPos))
                    order := Integer(mOrd[1])
                type := ""
                if (RegExMatch(stepsJson, '"type"\s*:\s*"((?:[^"\\]|\\.)*)"', &mType, stepPos))
                    type := this._UnescJson(mType[1])
                evidence := ""
                if (RegExMatch(stepsJson, '"evidence"\s*:\s*"((?:[^"\\]|\\.)*)"', &mEvid, stepPos))
                    evidence := this._UnescJson(mEvid[1])
                context := ""
                if (RegExMatch(stepsJson, '"context"\s*:\s*"((?:[^"\\]|\\.)*)"', &mCtx, stepPos))
                    context := this._UnescJson(mCtx[1])

                steps.Push({order: order, type: type, evidence: evidence, context: context})
                stepPos += 10
            }

            this.stories.Push({name: name, createdAt: createdAt, steps: steps})
            pos := bracketEnd + 1
        }

        if (this.activeIndex < 1 || this.activeIndex > this.stories.Length)
            this.activeIndex := this.stories.Length > 0 ? 1 : 0
    }

    static _EscJson(s) {
        s := StrReplace(s, "\", "\\")
        s := StrReplace(s, '"', '\"')
        s := StrReplace(s, "`n", "\n")
        s := StrReplace(s, "`r", "\r")
        s := StrReplace(s, "`t", "\t")
        return s
    }

    static _UnescJson(s) {
        s := StrReplace(s, "\n", "`n")
        s := StrReplace(s, "\r", "`r")
        s := StrReplace(s, "\t", "`t")
        s := StrReplace(s, '\"', '"')
        s := StrReplace(s, "\\", "\")
        return s
    }
}
