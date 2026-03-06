; StoryTelling.ahk — Menu de Histórias com Evidências para análise por IA
; Permite documentar fluxos passo a passo com evidências e contexto narrativo
; Gera prompt formatado para colar no chat da IA

class StoryTelling {
    static gui := ""
    static listView := ""
    static inputBox := ""
    static footerText := ""
    static stories := []
    static activeIndex := 0      ; index into stories[] (1-based)
    static configDir := ""
    static configPath := ""
    static isVisible := false

    static Init() {
        this.configDir := EnvGet("USERPROFILE") "\.lazywindow"
        this.configPath := this.configDir "\stories.json"
        this.Load()
    }

    static Toggle() {
        if (this.isVisible) {
            this.Hide()
        } else {
            this.Show()
        }
    }

    static Show() {
        if (this.gui) {
            try this.gui.Destroy()
            this.gui := ""
        }
        this.CreateGui()
        this.isVisible := true
    }

    static Hide() {
        if (this.gui) {
            try Hotkey("*Enter", "Off")
            try this.gui.Destroy()
            this.gui := ""
        }
        this.isVisible := false
    }

    ; ── Quick-Add: cola clipboard como evidência + pede contexto ──
    static QuickAdd() {
        if (this.stories.Length = 0) {
            this._EnsureStory()
        }
        clip := A_Clipboard
        if (clip = "") {
            ToolTip("Clipboard vazio — copie uma evidência primeiro")
            SetTimer(() => ToolTip(), -2000)
            return
        }
        type := this._DetectType(clip)
        context := this._AskContext()
        if (context = false)
            return
        story := this.stories[this.activeIndex]
        story.steps.Push({order: story.steps.Length + 1, type: type, evidence: clip, context: context})
        this.Persist()
        ToolTip("Passo " story.steps.Length " adicionado à história '" story.name "'")
        SetTimer(() => ToolTip(), -2000)
        if (this.isVisible) {
            this.PopulateList()
        }
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
        this.gui := Gui("+AlwaysOnTop +ToolWindow +Resize +OwnDialogs", "StoryTelling — LazyWindow")
        this.gui.Opt("-DPIScale")
        this.gui.BackColor := "1a1a2e"
        this.gui.SetFont("s12 c00ff88", "Consolas")

        storyName := this.activeIndex > 0 ? this.stories[this.activeIndex].name : "(nenhuma)"
        headerText := "STORY TELLING — História: " storyName "`n"
        headerText .= "N=Nova | A=Add passo | L=Listar | F=Flush prompt | [nº]E=Editar | [nº]U/D=Mover | [nº]R=Remover | [nº]V=Ver | ESC=Fechar"

        this.gui.SetFont("s11 cAAAAAA", "Consolas")
        this.gui.AddText("x15 y10 w1800", headerText)

        this.gui.SetFont("s12 c00ff88", "Consolas")
        this.gui.AddText("x15 y65 w100 h32", "Comando:")
        this.inputBox := this.gui.AddEdit("x120 y62 w400 h32 Background0f3460 c00ff88")

        this.gui.SetFont("s11 cDDDDDD", "Consolas")
        this.listView := this.gui.AddListView("x15 y105 w1800 h600 +Report -Multi +Grid Background0f3460 cDDDDDD"
            , ["#", "Tipo", "Evidência", "Contexto"])
        this.listView.ModifyCol(1, 50)
        this.listView.ModifyCol(2, 80)
        this.listView.ModifyCol(3, 700)
        this.listView.ModifyCol(4, 900)

        this.gui.SetFont("s10 c888888", "Consolas")
        this.footerText := this.gui.AddText("x15 y715 w1800 h25", "")

        this.inputBox.OnEvent("Change", (*) => this._OnInputChange())
        this.gui.OnEvent("Size", (g, m, w, h) => this._OnResize(w, h))
        this.gui.OnEvent("Escape", (*) => this.Hide())
        this.gui.OnEvent("Close", (*) => this.Hide())

        this.PopulateList()
        this._ShowFullScreen()
        this.inputBox.Focus()
        Hotkey("*Enter", (*) => this._Execute(), "On")
    }

    static _ShowFullScreen() {
        monNum := this._GetMonitorFromMouse()
        MonitorGetWorkArea(monNum, &wL, &wT, &wR, &wB)
        w := wR - wL
        h := wB - wT
        this.gui.Show("x" wL " y" wT " w" w " h" h)
        WinMaximize("ahk_id " this.gui.Hwnd)
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
            this.listView.Move(15, 105, w - 30, h - 155)
            this.footerText.Move(15, h - 35, w - 30, 25)
            colW := w - 30 - 50 - 80 - 20
            this.listView.ModifyCol(3, Round(colW * 0.45))
            this.listView.ModifyCol(4, Round(colW * 0.55))
        }
    }

    static PopulateList() {
        if (!this.listView)
            return
        this.listView.Delete()
        if (this.activeIndex < 1 || this.activeIndex > this.stories.Length) {
            this.footerText.Value := "Nenhuma história ativa — pressione N para criar"
            return
        }
        story := this.stories[this.activeIndex]
        for step in story.steps {
            evidPreview := StrLen(step.evidence) > 80 ? SubStr(step.evidence, 1, 80) "..." : step.evidence
            evidPreview := StrReplace(evidPreview, "`n", " ")
            ctxPreview := StrLen(step.context) > 100 ? SubStr(step.context, 1, 100) "..." : step.context
            ctxPreview := StrReplace(ctxPreview, "`n", " ")
            this.listView.Add("", A_Index, step.type, evidPreview, ctxPreview)
        }
        this.footerText.Value := story.steps.Length " passos | História: " story.name " | F=Flush prompt para clipboard"
    }

    ; ══════════════════════════════════════════════════════════════
    ; Input Handling
    ; ══════════════════════════════════════════════════════════════

    static _OnInputChange() {
        text := this.inputBox.Value
        if (RegExMatch(text, "^(\d+)", &match)) {
            num := Integer(match[1])
            if (this.activeIndex > 0 && num >= 1 && num <= this.stories[this.activeIndex].steps.Length)
                this.listView.Modify(num, "Select Focus Vis")
        }
    }

    static _Execute() {
        if (!this.isVisible || !this.inputBox)
            return
        text := Trim(this.inputBox.Value)
        this.inputBox.Value := ""
        if (text = "")
            return

        ; Single-letter commands
        upper := StrUpper(text)
        if (upper = "N") {
            this._CmdNewStory()
            return
        }
        if (upper = "A") {
            this._CmdAddStep()
            return
        }
        if (upper = "L") {
            this._CmdListStories()
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
                ToolTip("Nenhuma história ativa")
                SetTimer(() => ToolTip(), -2000)
                return
            }
            story := this.stories[this.activeIndex]
            if (num < 1 || num > story.steps.Length) {
                ToolTip("Passo " num " não existe")
                SetTimer(() => ToolTip(), -2000)
                return
            }
            switch cmd {
                case "E": this._CmdEditContext(num)
                case "V": this._CmdViewEvidence(num)
                case "U": this._CmdMoveUp(num)
                case "D": this._CmdMoveDown(num)
                case "R": this._CmdRemoveStep(num)
            }
            return
        }

        ; Number alone to select story from list mode
        if (RegExMatch(upper, "^\d+$")) {
            ; handled by _OnInputChange highlight
            return
        }
    }

    ; ── Commands ──

    static _CmdNewStory() {
        ib := InputBox("Nome da nova história:", "Nova História", "w400 h120")
        if (ib.Result = "Cancel" || Trim(ib.Value) = "")
            return
        story := {name: Trim(ib.Value), createdAt: this._Now(), steps: []}
        this.stories.Push(story)
        this.activeIndex := this.stories.Length
        this.Persist()
        this.PopulateList()
        this._UpdateHeader()
    }

    static _CmdAddStep() {
        if (this.stories.Length = 0)
            this._EnsureStory()
        clip := A_Clipboard
        if (clip = "") {
            ToolTip("Clipboard vazio — copie uma evidência primeiro")
            SetTimer(() => ToolTip(), -2000)
            return
        }
        type := this._DetectType(clip)
        context := this._AskContext()
        if (context = false)
            return
        story := this.stories[this.activeIndex]
        story.steps.Push({order: story.steps.Length + 1, type: type, evidence: clip, context: context})
        this.Persist()
        this.PopulateList()
    }

    static _CmdListStories() {
        if (this.stories.Length = 0) {
            ToolTip("Nenhuma história salva — pressione N para criar")
            SetTimer(() => ToolTip(), -2000)
            return
        }
        list := ""
        for i, s in this.stories {
            marker := (i = this.activeIndex) ? " ← ATIVA" : ""
            list .= i ". " s.name " (" s.steps.Length " passos)" marker "`n"
        }
        ib := InputBox("Histórias salvas:`n" list "`nDigite o número para ativar:", "Listar Histórias", "w500 h300")
        if (ib.Result = "Cancel" || Trim(ib.Value) = "")
            return
        num := 0
        try num := Integer(Trim(ib.Value))
        if (num >= 1 && num <= this.stories.Length) {
            this.activeIndex := num
            this.Persist()
            this.PopulateList()
            this._UpdateHeader()
        }
    }

    static _CmdEditContext(num) {
        story := this.stories[this.activeIndex]
        step := story.steps[num]
        ib := InputBox("Contexto atual:`n" SubStr(step.context, 1, 200) "`n`nNovo contexto:", "Editar Contexto — Passo " num, "w600 h250", step.context)
        if (ib.Result = "Cancel")
            return
        step.context := ib.Value
        this.Persist()
        this.PopulateList()
    }

    static _CmdViewEvidence(num) {
        story := this.stories[this.activeIndex]
        step := story.steps[num]
        preview := SubStr(step.evidence, 1, 2000)
        MsgBox("Tipo: " step.type "`nContexto: " step.context "`n`nEvidência:`n" preview, "Passo " num " — Evidência", "OK")
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

    static _EnsureStory() {
        if (this.stories.Length > 0 && this.activeIndex > 0)
            return
        ib := InputBox("Nenhuma história ativa.`nDigite o nome da nova história:", "Nova História", "w400 h150")
        if (ib.Result = "Cancel" || Trim(ib.Value) = "") {
            this.stories.Push({name: "História " FormatTime(, "yyyyMMdd_HHmmss"), createdAt: this._Now(), steps: []})
        } else {
            this.stories.Push({name: Trim(ib.Value), createdAt: this._Now(), steps: []})
        }
        this.activeIndex := this.stories.Length
        this.Persist()
    }

    static _DetectType(text) {
        clean := Trim(text)
        ; Check if it's a folder path
        if (DirExist(clean))
            return "Pasta"
        ; Check if it's an image file
        if (FileExist(clean)) {
            SplitPath(clean, , , &ext)
            if (RegExMatch(ext, "i)^(png|jpg|jpeg|gif|bmp|webp)$"))
                return "Imagem"
            return "Arquivo"
        }
        return "Texto"
    }

    static _AskContext() {
        ib := InputBox("Descreva o contexto desta evidência:`n(o que está acontecendo, por que é relevante)", "Contexto do Passo", "w600 h200")
        if (ib.Result = "Cancel")
            return false
        return ib.Value
    }

    static _UpdateHeader() {
        ; Recreate GUI to update header with new story name
        if (this.isVisible) {
            this.Show()
        }
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

        ; Parse stories by finding story objects
        ; Split by story boundaries — find each {"name":...,"steps":[...]}
        pos := 1
        while (pos := InStr(content, '"name"', , pos)) {
            ; Extract name
            nameStart := pos
            if (!RegExMatch(content, '"name"\s*:\s*"((?:[^"\\]|\\.)*)"', &mName, pos))
                break
            name := this._UnescJson(mName[1])

            ; Extract createdAt
            createdAt := ""
            if (RegExMatch(content, '"createdAt"\s*:\s*"([^"]*)"', &mCA, pos))
                createdAt := mCA[1]

            ; Find steps array
            stepsStart := InStr(content, '"steps"', , pos)
            if (!stepsStart)
                break
            bracketStart := InStr(content, "[", , stepsStart)
            if (!bracketStart)
                break

            ; Find matching closing bracket
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

            ; Parse individual steps
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

        ; Validate activeIndex
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
