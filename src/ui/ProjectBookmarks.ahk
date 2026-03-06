#Requires AutoHotkey v2.0

class ProjectBookmarks {
    static gui := ""
    static listView := ""
    static inputBox := ""
    static tagFilter := ""
    static footerText := ""
    static isVisible := false
    static projects := []
    static filtered := []
    static wasArrowMouseOn := false
    static configDir := ""
    static configPath := ""
    static allTags := []
    static wtProfiles := []

    static Init() {
        this.configDir := EnvGet("USERPROFILE") "\.lazywindow"
        this.configPath := this.configDir "\projects.json"
        this.LoadWTProfiles()
        this.Load()
        this.MigrateLegacyShells()
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

        if (ArrowMouse.IsEnabled()) {
            this.wasArrowMouseOn := true
            ArrowMouse.PauseForSwitcher()
        } else {
            this.wasArrowMouseOn := false
        }

        this.Load()
        this.MigrateLegacyShells()
        this.SortByRecency()
        this.CreateGui()
        this.isVisible := true
    }

    static Hide() {
        try Hotkey("*Enter", "Off")
        if (this.gui) {
            this.gui.Destroy()
            this.gui := ""
        }
        this.isVisible := false

        if (this.wasArrowMouseOn) {
            this.wasArrowMouseOn := false
            ArrowMouse.Enable()
        }
    }

    ; ── Windows Terminal Profiles ──

    static LoadWTProfiles() {
        this.wtProfiles := []
        localAppData := EnvGet("LOCALAPPDATA")

        ; Try standard WT, then Preview
        paths := [
            localAppData "\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
            localAppData "\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
        ]

        settingsContent := ""
        for p in paths {
            if (FileExist(p)) {
                try {
                    settingsContent := FileRead(p, "UTF-8")
                    break
                }
            }
        }

        if (settingsContent = "")
            return

        ; Parse profiles from "list": [...] array
        ; Find each profile object within the list
        listStart := InStr(settingsContent, '"list"')
        if (!listStart)
            return

        ; Find the opening bracket of the list array
        bracketStart := InStr(settingsContent, "[", , listStart)
        if (!bracketStart)
            return

        ; Extract from bracket to matching close bracket
        depth := 0
        listEnd := 0
        pos := bracketStart
        Loop StrLen(settingsContent) - bracketStart + 1 {
            ch := SubStr(settingsContent, pos, 1)
            if (ch = "[")
                depth++
            else if (ch = "]")
                depth--
            if (depth = 0) {
                listEnd := pos
                break
            }
            pos++
        }

        if (listEnd = 0)
            return

        listContent := SubStr(settingsContent, bracketStart, listEnd - bracketStart + 1)

        ; Parse each profile object
        objPos := 1
        while (objPos := RegExMatch(listContent, '\{[^{}]+\}', &m, objPos)) {
            obj := m[0]
            name := this.ExtractJsonField(obj, "name")
            source := this.ExtractJsonField(obj, "source")
            cmdline := this.ExtractJsonField(obj, "commandline")

            ; Check if hidden
            hiddenStr := ""
            if (RegExMatch(obj, '"hidden"\s*:\s*(true|false)', &hm))
                hiddenStr := hm[1]
            isHidden := (hiddenStr = "true")

            if (name != "" && !isHidden) {
                shellType := this.DetectProfileType(name, source, cmdline)
                this.wtProfiles.Push({
                    name: name,
                    shellType: shellType,
                    source: source
                })
            }
            objPos += StrLen(m[0])
        }
    }

    static DetectProfileType(name, source, cmdline) {
        ; Check source and name for WSL indicators
        nameLower := StrLower(name)
        sourceLower := StrLower(source)
        cmdLower := StrLower(cmdline)

        wslKeywords := ["ubuntu", "debian", "fedora", "suse", "kali", "arch", "alpine", "wsl", "canonical", "linux"]
        for kw in wslKeywords {
            if (InStr(nameLower, kw) || InStr(sourceLower, kw) || InStr(cmdLower, kw))
                return "wsl"
        }
        return "windows"
    }

    static GetDefaultProfile(shellType) {
        for p in this.wtProfiles {
            if (p.shellType = shellType)
                return p.name
        }
        if (this.wtProfiles.Length > 0)
            return this.wtProfiles[1].name
        return (shellType = "wsl") ? "Ubuntu" : "PowerShell"
    }

    static GetProfileType(profileName) {
        for p in this.wtProfiles {
            if (p.name = profileName)
                return p.shellType
        }
        return this.DetectShellType(profileName)
    }

    static DetectShellType(name) {
        nameLower := StrLower(name)
        wslKeywords := ["ubuntu", "debian", "fedora", "suse", "kali", "arch", "alpine", "wsl", "linux"]
        for kw in wslKeywords {
            if (InStr(nameLower, kw))
                return "wsl"
        }
        return "windows"
    }

    ; Migrate old "powershell"/"wsl" values to real WT profile names
    static MigrateLegacyShells() {
        changed := false
        for proj in this.projects {
            if (proj.shell = "powershell" || proj.shell = "wsl") {
                proj.shell := this.GetDefaultProfile(proj.shell = "wsl" ? "wsl" : "windows")
                changed := true
            }
        }
        if (changed)
            this.Persist()
    }

    ; Show numbered profile picker, returns chosen profile name or ""
    static PickProfile(title, defaultProfile := "") {
        if (this.wtProfiles.Length = 0)
            return defaultProfile

        msg := title "`n`n"
        for idx, p in this.wtProfiles {
            typeLabel := (p.shellType = "wsl") ? " [WSL]" : ""
            marker := (p.name = defaultProfile) ? " ◄" : ""
            msg .= idx ". " p.name typeLabel marker "`n"
        }
        msg .= "`nDigite o número:"

        result := InputBox(msg, "Terminal", "w400 h" (100 + this.wtProfiles.Length * 22))
        if (result.Result != "OK" || Trim(result.Value) = "")
            return ""

        val := Trim(result.Value)
        if (RegExMatch(val, "^\d+$")) {
            num := Integer(val)
            if (num >= 1 && num <= this.wtProfiles.Length)
                return this.wtProfiles[num].name
        }
        return ""
    }

    ; ── GUI ──

    static CreateGui() {
        this.gui := Gui("+AlwaysOnTop +ToolWindow +Resize +OwnDialogs", "LazyWindow - Project Bookmarks")
        this.gui.Opt("-DPIScale")
        this.gui.BackColor := "1B2838"

        ; Header instructions
        this.gui.SetFont("s11 c7EB8DA", "Cascadia Code")
        this.gui.AddText("x15 y10 w900 h25", "Digite: [nº][ação] + Enter     Ex: 1N=nvim  2S=shell  3R=remover  4G=tag  5P=perfil")
        this.gui.SetFont("s10 c5A7A94", "Cascadia Code")
        this.gui.AddText("x15 y35 w900 h22", "Sem nº: A=adicionar  B=browse pasta  |  Texto livre = filtrar por nome/caminho  |  ESC=fechar")

        ; Input box
        this.gui.SetFont("s13 cA8D8B9", "Cascadia Code")
        this.inputBox := this.gui.AddEdit("x15 y65 w550 h32 Background152230")
        this.inputBox.OnEvent("Change", (*) => this.OnInputChange())

        ; Tag filter dropdown
        this.gui.SetFont("s10 cD0D8E0", "Cascadia Code")
        this.gui.AddText("x580 y70 w35 h25", "Tag:")
        this.RefreshTags()
        tagChoices := ["Todas"]
        for t in this.allTags {
            tagChoices.Push(t)
        }
        this.tagFilter := this.gui.AddDropDownList("x620 y67 w140 Choose1 Background152230", tagChoices)
        this.tagFilter.OnEvent("Change", (*) => this.ApplyFilter())

        ; ListView — "Terminal" column instead of "Shell"
        this.gui.SetFont("s11 cD0D8E0", "Cascadia Code")
        this.listView := this.gui.AddListView("x15 y105 w900 h450 +Report -Multi -E0x200 +LV0x10020 Background0D1926 c7EB8DA", ["#", "Nome", "Caminho", "Tag", "Terminal", "Aberto"])
        this.listView.ModifyCol(1, 40)
        this.listView.ModifyCol(2, 160)
        this.listView.ModifyCol(3, 350)
        this.listView.ModifyCol(4, 90)
        this.listView.ModifyCol(5, 160)
        this.listView.ModifyCol(6, 80)
        DllCall("uxtheme\SetWindowTheme", "Ptr", this.listView.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
        SendMessage(0x1001, 0, 0x26190D, this.listView)
        SendMessage(0x1026, 0, 0x26190D, this.listView)
        SendMessage(0x1024, 0, 0xDAB87E, this.listView)

        ; Footer
        this.gui.SetFont("s10 c5A7A94", "Cascadia Code")
        this.footerText := this.gui.AddText("x15 y565 w900 h22", "")

        this.gui.OnEvent("Size", (guiObj, minMax, w, h) => this.OnResize(w, h))
        this.gui.OnEvent("Escape", (*) => this.Hide())
        this.gui.OnEvent("Close", (*) => this.Hide())

        ; Populate and show fullscreen
        this.filtered := this.projects.Clone()
        this.PopulateList()
        this.ShowFullScreen()
        this.inputBox.Focus()

        Hotkey("*Enter", (*) => this.Execute(), "On")
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
        margin := 15
        inputY := 65
        listY := 105
        footerH := 28
        footerY := Max(listY + 50, height - footerH - margin)
        listH := Max(50, footerY - listY - 8)
        listW := Max(200, width - (margin * 2))

        try this.inputBox.Move(margin, inputY, Max(200, width - 230), 32)
        try this.listView.Move(margin, listY, listW, listH)
        try this.footerText.Move(margin, footerY, listW)

        if (listW > 400) {
            this.listView.ModifyCol(1, 40)
            this.listView.ModifyCol(2, Round(listW * 0.15))
            this.listView.ModifyCol(3, Round(listW * 0.38))
            this.listView.ModifyCol(4, Round(listW * 0.10))
            this.listView.ModifyCol(5, Round(listW * 0.20))
            this.listView.ModifyCol(6, Round(listW * 0.10))
        }
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

    static PopulateList() {
        this.listView.Delete()
        for idx, proj in this.filtered {
            timeAgo := this.FormatTimeAgo(proj.lastOpened)
            this.listView.Add("", idx, proj.name, proj.path, proj.tag, proj.shell, timeAgo)
        }
        if (this.filtered.Length > 0) {
            this.listView.Modify(1, "Select Focus Vis")
        }
        this.footerText.Value := this.filtered.Length " de " this.projects.Length " projetos"
    }

    static OnInputChange() {
        text := this.inputBox.Value

        ; If starts with a number, highlight that row
        if (RegExMatch(text, "^(\d+)", &match)) {
            num := Integer(match[1])
            if (num >= 1 && num <= this.filtered.Length) {
                this.listView.Modify(num, "Select Focus Vis")
            }
            return
        }

        ; If starts with A or B (global actions), don't filter
        if (RegExMatch(text, "i)^[AB]$")) {
            return
        }

        ; Otherwise treat as search filter
        this.ApplyFilter()
    }

    static ApplyFilter() {
        text := Trim(this.inputBox.Value)
        tagIdx := this.tagFilter.Value
        tagText := (tagIdx <= 1) ? "" : this.tagFilter.Text

        ; Don't filter if input is a command (number or A/B)
        if (RegExMatch(text, "i)^(\d+[NTRGS]?|[AB])$")) {
            query := ""
        } else {
            query := text
        }

        if (query = "" && tagText = "") {
            this.filtered := this.projects.Clone()
        } else {
            this.filtered := []
            queryLower := StrLower(query)
            for proj in this.projects {
                if (tagText != "" && StrLower(proj.tag) != StrLower(tagText)) {
                    continue
                }
                if (query != "") {
                    searchText := StrLower(proj.name . " " . proj.path . " " . proj.tag)
                    if (!InStr(searchText, queryLower)) {
                        continue
                    }
                }
                this.filtered.Push(proj)
            }
        }
        this.PopulateList()
    }

    ; ── Execução por input ──

    static Execute() {
        if (!this.gui || !this.inputBox)
            return
        try text := Trim(this.inputBox.Value)
        catch
            return
        if (text = "") {
            this.Hide()
            return
        }

        ; Global actions (no number)
        if (text = "A" || text = "a") {
            this.AddProjectManual()
            return
        }
        if (text = "B" || text = "b") {
            this.BrowseProject()
            return
        }

        ; Number + optional action letter
        if (!RegExMatch(text, "i)^(\d+)([NTRSGP]?)$", &match)) {
            return
        }

        num := Integer(match[1])
        action := StrUpper(match[2])

        if (num < 1 || num > this.filtered.Length) {
            return
        }

        proj := this.filtered[num]

        switch action {
            case "", "N":
                this.OpenInNvim(proj)
            case "T", "S":
                this.OpenTerminal(proj)
            case "R":
                this.RemoveProject(proj)
            case "G":
                this.EditTag(proj)
            case "P":
                this.EditShell(proj)
        }
    }

    ; ── Ações ──

    static OpenInNvim(proj) {
        this.UpdateLastOpened(proj)
        this.Hide()
        Sleep(50)

        profileName := proj.shell
        shellType := this.GetProfileType(profileName)

        if (shellType = "wsl") {
            Run('wt.exe -p "' profileName '" wsl -e bash -c "cd ' . this.EscapeBashPath(proj.path) . ' && nvim ."')
        } else {
            cleanPath := RTrim(proj.path, "\/")
            if (!DirExist(cleanPath)) {
                MsgBox("Diretório não encontrado:`n" cleanPath, "LazyWindow", "Icon!")
                return
            }
            Run('wt.exe -p "' profileName '" -d "' cleanPath '" pwsh -NoExit -Command "nvim ."')
        }
        this.MaximizeWT()
    }

    static OpenTerminal(proj) {
        this.UpdateLastOpened(proj)
        this.Hide()
        Sleep(50)

        profileName := proj.shell
        shellType := this.GetProfileType(profileName)

        if (shellType = "wsl") {
            Run('wt.exe -p "' profileName '" wsl -e bash -c "cd ' . this.EscapeBashPath(proj.path) . ' && exec bash"')
        } else {
            cleanPath := RTrim(proj.path, "\/")
            if (!DirExist(cleanPath)) {
                MsgBox("Diretório não encontrado:`n" cleanPath, "LazyWindow", "Icon!")
                return
            }
            Run('wt.exe -p "' profileName '" -d "' cleanPath '"')
        }
        this.MaximizeWT()
    }

    static MaximizeWT() {
        if (WinWait("ahk_exe WindowsTerminal.exe",, 3))
            WinMaximize("ahk_exe WindowsTerminal.exe")
    }

    static UpdateLastOpened(proj) {
        proj.lastOpened := FormatTime(, "yyyy-MM-ddTHH:mm:ss")
        this.Persist()
    }

    static AddProjectManual() {
        this.Hide()
        Sleep(50)

        pathInput := InputBox("Caminho completo do projeto:`n(Windows: C:\path ou Linux: ~/path)", "Adicionar Projeto", "w450 h150")
        if (pathInput.Result != "OK" || Trim(pathInput.Value) = "")
            return

        projPath := Trim(pathInput.Value)

        ; Suggest default profile based on path
        pathType := this.DetectPathType(projPath)
        defaultProfile := this.GetDefaultProfile(pathType)

        ; Pick WT profile
        chosenProfile := this.PickProfile("Terminal para '" this.ExtractName(projPath) "':", defaultProfile)
        if (chosenProfile = "")
            return

        tagInput := InputBox("Tag (opcional, ex: aws, pessoal, trabalho):", "Tag", "w300 h130", "")
        tag := (tagInput.Result = "OK") ? Trim(tagInput.Value) : ""

        name := this.ExtractName(projPath)
        this.AddToList(name, projPath, tag, chosenProfile)
        this.Show()
    }

    static BrowseProject() {
        this.Hide()
        Sleep(50)

        selectedDir := DirSelect(, 3, "Selecione a pasta do projeto")
        if (selectedDir = "")
            return

        pathType := this.DetectPathType(selectedDir)
        defaultProfile := this.GetDefaultProfile(pathType)

        chosenProfile := this.PickProfile("Terminal para '" this.ExtractName(selectedDir) "':", defaultProfile)
        if (chosenProfile = "")
            return

        tagInput := InputBox("Tag (opcional, ex: aws, pessoal, trabalho):", "Tag", "w300 h130", "")
        tag := (tagInput.Result = "OK") ? Trim(tagInput.Value) : ""

        name := this.ExtractName(selectedDir)
        this.AddToList(name, selectedDir, tag, chosenProfile)
        this.Show()
    }

    static AddToList(name, path, tag, shell) {
        ; Sanitize path — remove newlines, headers, trailing slashes
        path := RTrim(Trim(path, ' `t`r`n"'), "\/")
        if (path = "" || InStr(path, "`n")) {
            ToolTip("Caminho inválido")
            SetTimer(() => ToolTip(), -2000)
            return
        }

        for proj in this.projects {
            if (StrLower(proj.path) = StrLower(path)) {
                ToolTip("Projeto já existe: " name)
                SetTimer(() => ToolTip(), -2000)
                return
            }
        }

        now := FormatTime(, "yyyy-MM-ddTHH:mm:ss")
        this.projects.Push({
            name: name,
            path: path,
            tag: tag,
            shell: shell,
            lastOpened: now,
            createdAt: now
        })
        this.Persist()
        ToolTip("Projeto adicionado: " name)
        SetTimer(() => ToolTip(), -1500)
    }

    static RemoveProject(proj) {
        idx := 0
        for i, p in this.projects {
            if (p.path = proj.path) {
                idx := i
                break
            }
        }
        if (idx > 0) {
            this.projects.RemoveAt(idx)
            this.Persist()
            this.inputBox.Value := ""
            this.ApplyFilter()
            ToolTip("Removido: " proj.name)
            SetTimer(() => ToolTip(), -1500)
        }
    }

    static EditTag(proj) {
        this.Hide()
        KeyWait("Enter")
        Sleep(100)
        tagInput := InputBox("Nova tag para '" proj.name "':", "Editar Tag", "w300 h130", proj.tag)
        if (tagInput.Result != "OK") {
            this.Show()
            return
        }
        proj.tag := Trim(tagInput.Value)
        this.Persist()
        this.Show()
    }

    static EditShell(proj) {
        this.Hide()
        KeyWait("Enter")
        Sleep(100)
        chosenProfile := this.PickProfile("Novo terminal para '" proj.name "':", proj.shell)
        if (chosenProfile = "") {
            this.Show()
            return
        }
        proj.shell := chosenProfile
        this.Persist()
        this.Show()
    }

    ; ── Quick-Add from Terminal ──

    static QuickAddFromTerminal() {
        ; Check if active window is Windows Terminal
        try {
            processName := WinGetProcessName("A")
        } catch {
            ToolTip("Nenhuma janela ativa")
            SetTimer(() => ToolTip(), -2000)
            return
        }

        if (processName != "WindowsTerminal.exe") {
            ToolTip("Janela ativa não é Windows Terminal")
            SetTimer(() => ToolTip(), -2000)
            return
        }

        title := WinGetTitle("A")

        ; Detect shell type from WT title to send the right command
        isWSL := false
        titleLower := StrLower(title)
        wslKeywords := ["ubuntu", "debian", "fedora", "suse", "kali", "arch", "alpine", "wsl", "linux", "bash", "@"]
        for kw in wslKeywords {
            if (InStr(titleLower, kw)) {
                isWSL := true
                break
            }
        }

        ; Save current clipboard
        savedClip := A_Clipboard
        A_Clipboard := ""

        ; Send command to copy pwd to clipboard (leading space = no history in many shells)
        ; Use clip.exe pipe — more reliable than Set-Clipboard (works in PS5, PS7, cmd)
        if (isWSL) {
            SendInput(" pwd | clip.exe{Enter}")
        } else {
            SendInput(" (Get-Location).Path | clip{Enter}")
        }

        ; Wait for clipboard to be populated
        success := ClipWait(2, 1)
        if (!success || A_Clipboard = "") {
            A_Clipboard := savedClip
            ToolTip("Não foi possível obter o diretório atual")
            SetTimer(() => ToolTip(), -2500)
            return
        }

        ; Extract last valid line from clipboard (handles PS formatted output with headers)
        clipText := A_Clipboard
        A_Clipboard := savedClip
        projPath := ""
        loop parse clipText, "`n", "`r" {
            line := Trim(A_LoopField, ' `t`r`n"')
            if (line != "" && !RegExMatch(line, "^-+$") && line != "Path")
                projPath := line
        }
        projPath := RTrim(projPath, "\/")

        if (projPath = "") {
            ToolTip("Caminho vazio")
            SetTimer(() => ToolTip(), -2000)
            return
        }

        ; Check if already bookmarked
        this.Load()
        for proj in this.projects {
            if (StrLower(proj.path) = StrLower(projPath)) {
                ToolTip("Já marcado: " proj.name)
                SetTimer(() => ToolTip(), -2000)
                return
            }
        }

        ; Detect profile from WT title
        detectedProfile := ""
        for p in this.wtProfiles {
            if (InStr(titleLower, StrLower(p.name))) {
                detectedProfile := p.name
                break
            }
        }
        if (detectedProfile = "") {
            pathType := this.DetectPathType(projPath)
            detectedProfile := this.GetDefaultProfile(pathType)
        }

        name := this.ExtractName(projPath)
        this.AddToList(name, projPath, "", detectedProfile)
    }

    ; ── Utilidades ──

    static DetectPathType(path) {
        if (RegExMatch(path, "^[A-Za-z]:\\"))
            return "windows"
        if (RegExMatch(path, "^(/|~)"))
            return "wsl"
        return "windows"
    }

    static ExtractName(path) {
        path := RegExReplace(path, "[/\\]+$", "")
        if (RegExMatch(path, "[/\\]([^/\\]+)$", &m))
            return m[1]
        return path
    }

    static EscapeBashPath(path) {
        return "'" RegExReplace(path, "'", "'\\''") "'"
    }

    static FormatTimeAgo(dateStr) {
        if (dateStr = "" || dateStr = "never")
            return "nunca"

        try {
            ts := RegExReplace(dateStr, "[-T:]", "")
            now := FormatTime(, "yyyyMMddHHmmss")

            diffMin := DateDiff(now, ts, "Minutes")
            if (diffMin < 0)
                diffMin := 0

            if (diffMin < 1)
                return "agora"
            if (diffMin < 60)
                return diffMin "min"
            diffHours := diffMin // 60
            if (diffHours < 24)
                return diffHours "h"
            diffDays := diffHours // 24
            if (diffDays < 7)
                return diffDays "d"
            diffWeeks := diffDays // 7
            if (diffWeeks < 5)
                return diffWeeks "sem"
            diffMonths := diffDays // 30
            return diffMonths "mes"
        } catch {
            return "?"
        }
    }

    static SortByRecency() {
        n := this.projects.Length
        Loop n - 1 {
            i := A_Index
            Loop n - i {
                j := A_Index
                a := this.projects[j]
                b := this.projects[j + 1]
                tsA := RegExReplace(a.lastOpened, "[-T:]", "")
                tsB := RegExReplace(b.lastOpened, "[-T:]", "")
                if (tsA < tsB) {
                    this.projects[j] := b
                    this.projects[j + 1] := a
                }
            }
        }
    }

    static RefreshTags() {
        tagMap := Map()
        for proj in this.projects {
            if (proj.tag != "")
                tagMap[proj.tag] := true
        }
        this.allTags := []
        for tag, _ in tagMap {
            this.allTags.Push(tag)
        }
    }

    ; ── Persistência ──

    static Persist() {
        try {
            if (!DirExist(this.configDir))
                DirCreate(this.configDir)

            json := '{"projects": ['
            first := true
            for proj in this.projects {
                if (!first)
                    json .= ","
                json .= "`n    {"
                json .= '"name": "' this.EscapeJson(proj.name) '", '
                json .= '"path": "' this.EscapeJson(proj.path) '", '
                json .= '"tag": "' this.EscapeJson(proj.tag) '", '
                json .= '"shell": "' this.EscapeJson(proj.shell) '", '
                json .= '"lastOpened": "' proj.lastOpened '", '
                json .= '"createdAt": "' proj.createdAt '"'
                json .= "}"
                first := false
            }
            json .= "`n]}"

            file := FileOpen(this.configPath, "w", "UTF-8")
            file.Write(json)
            file.Close()
        }
    }

    static Load() {
        this.projects := []

        if (!FileExist(this.configPath))
            return

        try {
            content := FileRead(this.configPath, "UTF-8")

            pos := 1
            while (pos := RegExMatch(content, '\{[^{}]+\}', &m, pos)) {
                obj := m[0]
                name := this.ExtractJsonField(obj, "name")
                path := this.ExtractJsonField(obj, "path")
                tag := this.ExtractJsonField(obj, "tag")
                shell := this.ExtractJsonField(obj, "shell")
                lastOpened := this.ExtractJsonField(obj, "lastOpened")
                createdAt := this.ExtractJsonField(obj, "createdAt")

                if (path != "") {
                    if (shell = "")
                        shell := this.GetDefaultProfile(this.DetectPathType(path))
                    if (name = "")
                        name := this.ExtractName(path)
                    this.projects.Push({
                        name: name,
                        path: path,
                        tag: tag,
                        shell: shell,
                        lastOpened: lastOpened,
                        createdAt: createdAt
                    })
                }
                pos += StrLen(m[0])
            }
        }
    }

    static ExtractJsonField(obj, field) {
        pattern := '"' field '"\s*:\s*"([^"]*)"'
        if (RegExMatch(obj, pattern, &m))
            return this.UnescapeJson(m[1])
        return ""
    }

    static EscapeJson(str) {
        str := StrReplace(str, "\", "\\")
        str := StrReplace(str, '"', '\"')
        str := StrReplace(str, "`n", "\n")
        str := StrReplace(str, "`r", "\r")
        str := StrReplace(str, "`t", "\t")
        return str
    }

    static UnescapeJson(str) {
        str := StrReplace(str, "\n", "`n")
        str := StrReplace(str, "\r", "`r")
        str := StrReplace(str, "\t", "`t")
        str := StrReplace(str, '\"', '"')
        str := StrReplace(str, "\\", "\")
        return str
    }
}
