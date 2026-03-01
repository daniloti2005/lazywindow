#Requires AutoHotkey v2.0

class ProjectBookmarks {
    static gui := ""
    static listView := ""
    static searchEdit := ""
    static tagFilter := ""
    static footerText := ""
    static isVisible := false
    static projects := []
    static filtered := []
    static wasArrowMouseOn := false
    static configDir := ""
    static configPath := ""
    static allTags := []

    static Init() {
        this.configDir := EnvGet("USERPROFILE") "\.lazywindow"
        this.configPath := this.configDir "\projects.json"
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
        this.SortByRecency()
        this.CreateGui()
        this.isVisible := true
    }

    static Hide() {
        try Hotkey("*Enter", "Off")
        try Hotkey("+Enter", "Off")
        try Hotkey("Delete", "Off")
        try Hotkey("Up", "Off")
        try Hotkey("Down", "Off")
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

    ; ── GUI ──

    static CreateGui() {
        this.gui := Gui("+AlwaysOnTop -MinimizeBox +ToolWindow", "LazyWindow - Project Bookmarks")
        this.gui.BackColor := "1a1a2e"

        this.gui.SetFont("s11 c0f3460", "Segoe UI")
        this.gui.AddText("x10 y10 w700", "Enter=nvim . │ Shift+Enter=terminal │ Del=remover │ ESC=fechar")

        ; Search
        this.gui.SetFont("s10 cWhite", "Segoe UI")
        this.gui.AddText("x10 y42 w50", "Busca:")
        this.gui.SetFont("s11 cWhite", "Consolas")
        this.searchEdit := this.gui.AddEdit("x65 y38 w330 h28 Background0f3460")
        this.searchEdit.OnEvent("Change", (*) => this.OnSearchChange())

        ; Tag filter dropdown
        this.gui.SetFont("s10 cWhite", "Segoe UI")
        this.gui.AddText("x410 y42 w30", "Tag:")
        this.RefreshTags()
        tagChoices := ["Todas"]
        for t in this.allTags {
            tagChoices.Push(t)
        }
        this.tagFilter := this.gui.AddDropDownList("x445 y38 w120 Choose1 Background0f3460", tagChoices)
        this.tagFilter.OnEvent("Change", (*) => this.OnSearchChange())

        ; ListView
        this.gui.SetFont("s10 cWhite", "Segoe UI")
        this.listView := this.gui.AddListView("x10 y75 w700 h310 Background16213e +Report -Multi +Grid", ["#", "Nome", "Caminho", "Tag", "Shell", "Última Abertura"])
        this.listView.ModifyCol(1, 30)
        this.listView.ModifyCol(2, 130)
        this.listView.ModifyCol(3, 270)
        this.listView.ModifyCol(4, 75)
        this.listView.ModifyCol(5, 50)
        this.listView.ModifyCol(6, 120)
        this.listView.OnEvent("DoubleClick", (*) => this.OpenInNvim())

        ; Buttons
        this.gui.SetFont("s9", "Segoe UI")
        addBtn := this.gui.AddButton("x10 y395 w100 h30", "+ Adicionar")
        addBtn.OnEvent("Click", (*) => this.AddProjectManual())

        browseBtn := this.gui.AddButton("x115 y395 w100 h30", "Browse...")
        browseBtn.OnEvent("Click", (*) => this.BrowseProject())

        removeBtn := this.gui.AddButton("x220 y395 w90 h30", "Remover")
        removeBtn.OnEvent("Click", (*) => this.RemoveProject())

        tagBtn := this.gui.AddButton("x315 y395 w80 h30", "Tag")
        tagBtn.OnEvent("Click", (*) => this.EditTag())

        shellBtn := this.gui.AddButton("x400 y395 w80 h30", "Shell")
        shellBtn.OnEvent("Click", (*) => this.EditShell())

        this.gui.SetFont("s9 cGray", "Segoe UI")
        this.footerText := this.gui.AddText("x10 y432 w700 h20", "")

        this.filtered := this.projects.Clone()
        this.PopulateList()

        this.gui.OnEvent("Escape", (*) => this.Hide())
        this.gui.OnEvent("Close", (*) => this.Hide())

        this.gui.Show("w720 h455")
        this.searchEdit.Focus()

        Hotkey("*Enter", (*) => this.OnEnter(), "On")
        Hotkey("+Enter", (*) => this.OpenTerminal(), "On")
        Hotkey("Delete", (*) => this.RemoveProject(), "On")
        Hotkey("Up", (*) => this.NavigateList(-1), "On")
        Hotkey("Down", (*) => this.NavigateList(1), "On")
    }

    static PopulateList() {
        this.listView.Delete()
        for idx, proj in this.filtered {
            shellLabel := (proj.shell = "wsl") ? "WSL" : "PS"
            timeAgo := this.FormatTimeAgo(proj.lastOpened)
            this.listView.Add("", idx, proj.name, proj.path, proj.tag, shellLabel, timeAgo)
        }
        if (this.filtered.Length > 0) {
            this.listView.Modify(1, "Select Focus Vis")
        }
        this.footerText.Value := this.filtered.Length " de " this.projects.Length " projetos"
    }

    static OnSearchChange() {
        query := Trim(this.searchEdit.Value)
        tagIdx := this.tagFilter.Value
        tagText := (tagIdx <= 1) ? "" : this.tagFilter.Text

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

    static NavigateList(direction) {
        if (this.filtered.Length = 0)
            return
        currentRow := this.listView.GetNext(0, "Focused")
        if (currentRow = 0)
            currentRow := 1
        newRow := currentRow + direction
        if (newRow < 1)
            newRow := this.filtered.Length
        if (newRow > this.filtered.Length)
            newRow := 1
        this.listView.Modify(currentRow, "-Select -Focus")
        this.listView.Modify(newRow, "Select Focus Vis")
        this.searchEdit.Focus()
    }

    static GetSelectedProject() {
        row := this.listView.GetNext(0, "Focused")
        if (row = 0 && this.filtered.Length > 0)
            row := 1
        if (row = 0 || row > this.filtered.Length)
            return ""
        return this.filtered[row]
    }

    static OnEnter() {
        this.OpenInNvim()
    }

    ; ── Ações ──

    static OpenInNvim() {
        proj := this.GetSelectedProject()
        if (!proj)
            return

        this.UpdateLastOpened(proj)
        this.Hide()
        Sleep(50)

        if (proj.shell = "wsl") {
            Run('wt.exe wsl -e bash -c "cd ' . this.EscapeBashPath(proj.path) . ' && nvim ."')
        } else {
            Run('wt.exe -d "' . proj.path . '" pwsh -NoExit -Command "nvim ."')
        }
    }

    static OpenTerminal() {
        proj := this.GetSelectedProject()
        if (!proj)
            return

        this.UpdateLastOpened(proj)
        this.Hide()
        Sleep(50)

        if (proj.shell = "wsl") {
            Run('wt.exe wsl -e bash -c "cd ' . this.EscapeBashPath(proj.path) . ' && exec bash"')
        } else {
            Run('wt.exe -d "' . proj.path . '"')
        }
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
        shell := this.DetectShell(projPath)

        ; Ask for shell confirmation
        shellInput := InputBox("Shell para este projeto:`n(powershell ou wsl)", "Shell", "w300 h130", shell)
        if (shellInput.Result != "OK")
            return
        shell := StrLower(Trim(shellInput.Value))
        if (shell != "wsl")
            shell := "powershell"

        ; Ask for tag
        tagInput := InputBox("Tag (opcional, ex: aws, pessoal, trabalho):", "Tag", "w300 h130", "")
        tag := (tagInput.Result = "OK") ? Trim(tagInput.Value) : ""

        name := this.ExtractName(projPath)
        this.AddToList(name, projPath, tag, shell)
        this.Show()
    }

    static BrowseProject() {
        this.Hide()
        Sleep(50)

        selectedDir := DirSelect(, 3, "Selecione a pasta do projeto")
        if (selectedDir = "")
            return

        shell := this.DetectShell(selectedDir)

        ; Ask for shell confirmation
        shellInput := InputBox("Shell para este projeto:`n(powershell ou wsl)", "Shell", "w300 h130", shell)
        if (shellInput.Result != "OK")
            return
        shell := StrLower(Trim(shellInput.Value))
        if (shell != "wsl")
            shell := "powershell"

        ; Ask for tag
        tagInput := InputBox("Tag (opcional, ex: aws, pessoal, trabalho):", "Tag", "w300 h130", "")
        tag := (tagInput.Result = "OK") ? Trim(tagInput.Value) : ""

        name := this.ExtractName(selectedDir)
        this.AddToList(name, selectedDir, tag, shell)
        this.Show()
    }

    static AddToList(name, path, tag, shell) {
        ; Check duplicate
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

    static RemoveProject() {
        proj := this.GetSelectedProject()
        if (!proj)
            return

        ; Find and remove from main list
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
            this.OnSearchChange()
            ToolTip("Removido: " proj.name)
            SetTimer(() => ToolTip(), -1500)
        }
    }

    static EditTag() {
        proj := this.GetSelectedProject()
        if (!proj)
            return

        tagInput := InputBox("Nova tag para '" proj.name "':", "Editar Tag", "w300 h130", proj.tag)
        if (tagInput.Result != "OK")
            return
        proj.tag := Trim(tagInput.Value)
        this.Persist()
        this.RefreshTags()
        this.OnSearchChange()
    }

    static EditShell() {
        proj := this.GetSelectedProject()
        if (!proj)
            return

        currentShell := (proj.shell = "wsl") ? "wsl" : "powershell"
        shellInput := InputBox("Shell para '" proj.name "':`n(powershell ou wsl)", "Editar Shell", "w300 h130", currentShell)
        if (shellInput.Result != "OK")
            return
        newShell := StrLower(Trim(shellInput.Value))
        if (newShell != "wsl")
            newShell := "powershell"
        proj.shell := newShell
        this.Persist()
        this.OnSearchChange()
    }

    ; ── Utilidades ──

    static DetectShell(path) {
        if (RegExMatch(path, "^[A-Za-z]:\\"))
            return "powershell"
        if (RegExMatch(path, "^(/|~)"))
            return "wsl"
        return "powershell"
    }

    static ExtractName(path) {
        ; Remove trailing slashes
        path := RegExReplace(path, "[/\\]+$", "")
        ; Get last segment
        if (RegExMatch(path, "[/\\]([^/\\]+)$", &m))
            return m[1]
        return path
    }

    static EscapeBashPath(path) {
        ; Escape spaces and special chars for bash
        return "'" RegExReplace(path, "'", "'\\''") "'"
    }

    static FormatTimeAgo(dateStr) {
        if (dateStr = "" || dateStr = "never")
            return "nunca"

        try {
            ; Parse ISO date to AHK timestamp (yyyyMMddHHmmss)
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
        ; Bubble sort by lastOpened descending
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

            ; Parse each project object
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
                        shell := this.DetectShell(path)
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
