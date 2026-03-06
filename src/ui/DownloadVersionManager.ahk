#Requires AutoHotkey v2.0

class DownloadVersionManager {
    static gui := ""
    static listView := ""
    static inputBox := ""
    static footerText := ""
    static isVisible := false
    static wasArrowMouseOn := false
    static downloadsDir := ""
    static versionDir := ""
    static groups := []
    static versionFolders := []
    static versionDetail := []
    static mode := "duplicates"  ; "duplicates" | "versions" | "detail"
    static currentBaseName := ""

    static Init() {
        this.downloadsDir := EnvGet("USERPROFILE") "\Downloads"
        this.versionDir := EnvGet("USERPROFILE") "\.downloads-version"
    }

    static Toggle() {
        if (this.isVisible)
            this.Hide()
        else
            this.Show()
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

        this.mode := "duplicates"
        this.ScanDownloads()
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

    ; ── Duplicate Detection ──

    static ScanDownloads() {
        this.groups := []
        fileMap := Map()

        Loop Files, this.downloadsDir "\*.*", "F" {
            name := A_LoopFileName
            size := A_LoopFileSize
            modified := A_LoopFileTimeModified
            fullPath := A_LoopFileFullPath

            baseName := this.ExtractBaseName(name)
            baseKey := StrLower(baseName)

            if (!fileMap.Has(baseKey))
                fileMap[baseKey] := {baseName: baseName, files: []}

            fileMap[baseKey].files.Push({
                name: name,
                path: fullPath,
                size: Integer(size),
                modified: modified
            })
        }

        for key, group in fileMap {
            if (group.files.Length >= 2) {
                totalSize := 0
                for f in group.files
                    totalSize += f.size
                this.groups.Push({
                    baseName: group.baseName,
                    files: group.files,
                    totalSize: totalSize
                })
            }
        }
    }

    static ExtractBaseName(filename) {
        ; Split into name and extension
        dotPos := 0
        pos := 1
        while (p := InStr(filename, ".", , pos)) {
            dotPos := p
            pos := p + 1
        }

        if (dotPos > 1) {
            name := SubStr(filename, 1, dotPos - 1)
            ext := SubStr(filename, dotPos)
        } else {
            name := filename
            ext := ""
        }

        ; Remove copy patterns: " (1)", " Copia (1)", " - Copy (1)", " - Cópia (1)"
        ; Iteratively remove from right to left
        Loop {
            orig := name
            name := RegExReplace(name, "\s*[-–]\s*(?:Copy|Cópia|Copia)\s*\(\d+\)\s*$", "")
            name := RegExReplace(name, "\s*(?:Copia|Copy|Cópia)\s*\(\d+\)\s*$", "")
            name := RegExReplace(name, "\s*\(\d+\)\s*$", "")
            if (name = orig)
                break
        }

        return Trim(name) . ext
    }

    ; ── Version Action ──

    static VersionGroup(groupIdx) {
        if (groupIdx < 1 || groupIdx > this.groups.Length)
            return

        group := this.groups[groupIdx]
        baseName := group.baseName
        destDir := this.versionDir "\" baseName

        if (!DirExist(destDir))
            DirCreate(destDir)

        existing := this.LoadVersionsJson(baseName)
        newCount := 0
        skipCount := 0

        for f in group.files {
            if (this.IsAlreadyVersioned(existing, f.name, f.size, f.modified)) {
                skipCount++
                continue
            }

            ; Format timestamp from file modification time
            ts := this.FormatTimestamp(f.modified)

            ; Ensure unique filename
            destFile := destDir "\" ts "_" baseName
            counter := 0
            while FileExist(destFile) {
                counter++
                destFile := destDir "\" ts "_" counter "_" baseName
            }

            try {
                FileCopy(f.path, destFile)

                existing.Push({
                    versionFile: this.FileNameFromPath(destFile),
                    originalName: f.name,
                    originalPath: f.path,
                    versionedAt: FormatTime(, "yyyy-MM-ddTHH:mm:ss"),
                    fileSize: f.size,
                    fileModified: f.modified
                })

                ; Delete only copies (not the original base name)
                if (StrLower(f.name) != StrLower(baseName)) {
                    try FileDelete(f.path)
                }

                newCount++
            }
        }

        this.SaveVersionsJson(baseName, existing)

        msg := newCount " novo(s) versionado(s)"
        if (skipCount > 0)
            msg .= ", " skipCount " já existente(s)"
        ToolTip(msg)
        SetTimer(() => ToolTip(), -3000)

        ; Refresh
        this.ScanDownloads()
        this.PopulateDuplicates()
    }

    static VersionAll() {
        totalNew := 0
        totalSkip := 0

        Loop this.groups.Length {
            idx := this.groups.Length - A_Index + 1
            group := this.groups[idx]
            baseName := group.baseName
            destDir := this.versionDir "\" baseName

            if (!DirExist(destDir))
                DirCreate(destDir)

            existing := this.LoadVersionsJson(baseName)

            for f in group.files {
                if (this.IsAlreadyVersioned(existing, f.name, f.size, f.modified)) {
                    totalSkip++
                    continue
                }

                ts := this.FormatTimestamp(f.modified)
                destFile := destDir "\" ts "_" baseName
                counter := 0
                while FileExist(destFile) {
                    counter++
                    destFile := destDir "\" ts "_" counter "_" baseName
                }

                try {
                    FileCopy(f.path, destFile)
                    existing.Push({
                        versionFile: this.FileNameFromPath(destFile),
                        originalName: f.name,
                        originalPath: f.path,
                        versionedAt: FormatTime(, "yyyy-MM-ddTHH:mm:ss"),
                        fileSize: f.size,
                        fileModified: f.modified
                    })
                    if (StrLower(f.name) != StrLower(baseName))
                        try FileDelete(f.path)
                    totalNew++
                }
            }

            this.SaveVersionsJson(baseName, existing)
        }

        msg := totalNew " novo(s) versionado(s)"
        if (totalSkip > 0)
            msg .= ", " totalSkip " já existente(s)"
        ToolTip(msg)
        SetTimer(() => ToolTip(), -3000)

        this.ScanDownloads()
        this.PopulateDuplicates()
    }

    static IsAlreadyVersioned(existing, originalName, fileSize, fileModified) {
        for v in existing {
            if (StrLower(v.originalName) = StrLower(originalName)
                && v.fileSize = fileSize
                && v.fileModified = fileModified)
                return true
        }
        return false
    }

    ; ── Versions View ──

    static ScanVersions() {
        this.versionFolders := []
        if (!DirExist(this.versionDir))
            return

        Loop Files, this.versionDir "\*", "D" {
            folderName := A_LoopFileName
            versions := this.LoadVersionsJson(folderName)
            if (versions.Length = 0)
                continue

            latest := versions[versions.Length]
            this.versionFolders.Push({
                baseName: folderName,
                count: versions.Length,
                latestDate: latest.versionedAt,
                path: A_LoopFileFullPath
            })
        }
    }

    static LoadVersionDetail(baseName) {
        this.versionDetail := this.LoadVersionsJson(baseName)
        this.currentBaseName := baseName
    }

    static RestoreVersion(baseName, versionIdx := 0) {
        versions := this.LoadVersionsJson(baseName)
        if (versions.Length = 0)
            return

        ; Default to latest version
        if (versionIdx < 1 || versionIdx > versions.Length)
            versionIdx := versions.Length

        v := versions[versionIdx]
        srcPath := this.versionDir "\" baseName "\" v.versionFile
        destPath := this.downloadsDir "\" v.originalName

        if (!FileExist(srcPath)) {
            ToolTip("Arquivo não encontrado: " v.versionFile)
            SetTimer(() => ToolTip(), -3000)
            return
        }

        ; Avoid overwrite
        if (FileExist(destPath)) {
            destPath := this.downloadsDir "\restored_" v.originalName
        }

        try {
            FileCopy(srcPath, destPath)
            ToolTip("Restaurado: " v.originalName)
            SetTimer(() => ToolTip(), -3000)
        }
    }

    ; ── GUI ──

    static CreateGui() {
        this.gui := Gui("+AlwaysOnTop +ToolWindow +Resize +OwnDialogs", "LazyWindow - Download Version Manager")
        this.gui.Opt("-DPIScale")
        this.gui.BackColor := "1B2838"

        ; Header
        this.gui.SetFont("s11 c7EB8DA", "Cascadia Code")
        this.headerText := this.gui.AddText("x15 y10 w900 h25", this.GetHeaderText())
        this.gui.SetFont("s10 c5A7A94", "Cascadia Code")
        this.helpText := this.gui.AddText("x15 y35 w900 h22", this.GetHelpText())

        ; Input
        this.gui.SetFont("s13 cA8D8B9", "Cascadia Code")
        this.inputBox := this.gui.AddEdit("x15 y65 w550 h32 Background152230")
        this.inputBox.OnEvent("Change", (*) => this.OnInputChange())

        ; ListView
        this.gui.SetFont("s11 cD0D8E0", "Cascadia Code")
        this.listView := this.gui.AddListView("x15 y105 w900 h450 +Report -Multi -E0x200 +LV0x10020 Background0D1926 c7EB8DA", this.GetColumns())
        DllCall("uxtheme\SetWindowTheme", "Ptr", this.listView.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
        SendMessage(0x1001, 0, 0x26190D, this.listView)
        SendMessage(0x1026, 0, 0x26190D, this.listView)
        SendMessage(0x1024, 0, 0xDAB87E, this.listView)

        ; Footer
        this.gui.SetFont("s10 c5A7A94", "Cascadia Code")
        this.footerText := this.gui.AddText("x15 y565 w900 h22", "")

        this.gui.OnEvent("Size", (guiObj, minMax, w, h) => this.OnResize(w, h))
        this.gui.OnEvent("Escape", (*) => this.HandleEscape())
        this.gui.OnEvent("Close", (*) => this.Hide())

        this.PopulateCurrentMode()
        this.ShowFullScreen()
        this.inputBox.Focus()

        Hotkey("*Enter", (*) => this.Execute(), "On")
    }

    static GetHeaderText() {
        if (this.mode = "duplicates")
            return "📥 Duplicatas em Downloads     [nº]V=Versionar  [nº]O=Abrir  T=Todas  L=Versões"
        if (this.mode = "versions")
            return "📦 Versões Salvas     [nº]L=Listar  [nº]O=Abrir  [nº]R=Restaurar  D=Duplicatas"
        if (this.mode = "detail")
            return "📋 Versões de: " this.currentBaseName "     [nº]R=Restaurar  [nº]O=Abrir  V=Voltar"
        return ""
    }

    static GetHelpText() {
        if (this.mode = "duplicates")
            return "R=Refresh  L=Ver versões salvas  ESC=Fechar"
        if (this.mode = "versions")
            return "D=Voltar para duplicatas  ESC=Fechar"
        if (this.mode = "detail")
            return "V=Voltar para lista  ESC=Fechar"
        return ""
    }

    static GetColumns() {
        if (this.mode = "duplicates")
            return ["#", "Arquivo Base", "Cópias", "Tamanho"]
        if (this.mode = "versions")
            return ["#", "Arquivo Base", "Versões", "Última"]
        if (this.mode = "detail")
            return ["#", "Data/Hora", "Nome Original", "Tamanho"]
        return ["#"]
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
        listY := 105
        footerH := 28
        footerY := Max(listY + 50, height - footerH - margin)
        listH := Max(50, footerY - listY - 8)
        listW := Max(200, width - (margin * 2))

        try this.inputBox.Move(margin, 65, Max(200, width - 230), 32)
        try this.listView.Move(margin, listY, listW, listH)
        try this.footerText.Move(margin, footerY, listW)

        if (listW > 400) {
            if (this.mode = "duplicates") {
                this.listView.ModifyCol(1, 50)
                this.listView.ModifyCol(2, Round(listW * 0.50))
                this.listView.ModifyCol(3, Round(listW * 0.15))
                this.listView.ModifyCol(4, Round(listW * 0.25))
            } else if (this.mode = "versions") {
                this.listView.ModifyCol(1, 50)
                this.listView.ModifyCol(2, Round(listW * 0.45))
                this.listView.ModifyCol(3, Round(listW * 0.15))
                this.listView.ModifyCol(4, Round(listW * 0.30))
            } else if (this.mode = "detail") {
                this.listView.ModifyCol(1, 50)
                this.listView.ModifyCol(2, Round(listW * 0.25))
                this.listView.ModifyCol(3, Round(listW * 0.40))
                this.listView.ModifyCol(4, Round(listW * 0.20))
            }
        }
    }

    static GetMonitorFromMouse() {
        MouseGetPos(&mx, &my)
        cnt := Monitor.GetCount()
        Loop cnt {
            b := Monitor.GetBounds(A_Index)
            if (b && mx >= b.x && mx < b.right && my >= b.y && my < b.bottom)
                return A_Index
        }
        try return MonitorGetPrimary()
        return 1
    }

    ; ── Populate ──

    static PopulateCurrentMode() {
        if (this.mode = "duplicates")
            this.PopulateDuplicates()
        else if (this.mode = "versions")
            this.PopulateVersions()
        else if (this.mode = "detail")
            this.PopulateDetail()
    }

    static PopulateDuplicates() {
        this.listView.Delete()
        for idx, group in this.groups {
            sizeStr := this.FormatSize(group.totalSize)
            this.listView.Add("", idx, group.baseName, group.files.Length, sizeStr)
        }
        if (this.groups.Length > 0)
            this.listView.Modify(1, "Select Focus Vis")
        this.footerText.Value := this.groups.Length " grupo(s) de duplicatas em " this.downloadsDir
    }

    static PopulateVersions() {
        this.listView.Delete()
        for idx, vf in this.versionFolders {
            dateStr := this.FormatDateShort(vf.latestDate)
            this.listView.Add("", idx, vf.baseName, vf.count, dateStr)
        }
        if (this.versionFolders.Length > 0)
            this.listView.Modify(1, "Select Focus Vis")
        this.footerText.Value := this.versionFolders.Length " arquivo(s) versionado(s) em " this.versionDir
    }

    static PopulateDetail() {
        this.listView.Delete()
        for idx, v in this.versionDetail {
            dateStr := this.FormatDateShort(v.versionedAt)
            sizeStr := this.FormatSize(v.fileSize)
            this.listView.Add("", idx, dateStr, v.originalName, sizeStr)
        }
        if (this.versionDetail.Length > 0)
            this.listView.Modify(1, "Select Focus Vis")
        this.footerText.Value := this.versionDetail.Length " versão(ões) de " this.currentBaseName
    }

    ; ── Input Handling ──

    static OnInputChange() {
        text := this.inputBox.Value
        if (RegExMatch(text, "^(\d+)", &match)) {
            num := Integer(match[1])
            maxItems := this.GetCurrentListLength()
            if (num >= 1 && num <= maxItems)
                this.listView.Modify(num, "Select Focus Vis")
        }
    }

    static GetCurrentListLength() {
        if (this.mode = "duplicates")
            return this.groups.Length
        if (this.mode = "versions")
            return this.versionFolders.Length
        if (this.mode = "detail")
            return this.versionDetail.Length
        return 0
    }

    static HandleEscape() {
        if (this.mode = "detail") {
            this.SwitchMode("versions")
        } else if (this.mode = "versions") {
            this.SwitchMode("duplicates")
        } else {
            this.Hide()
        }
    }

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

        cmd := StrUpper(text)

        ; Global commands (no number)
        if (this.mode = "duplicates") {
            if (cmd = "T") {
                this.VersionAll()
                this.inputBox.Value := ""
                return
            }
            if (cmd = "L") {
                this.SwitchMode("versions")
                this.inputBox.Value := ""
                return
            }
            if (cmd = "R") {
                this.ScanDownloads()
                this.PopulateDuplicates()
                this.inputBox.Value := ""
                return
            }
        } else if (this.mode = "versions") {
            if (cmd = "D") {
                this.SwitchMode("duplicates")
                this.inputBox.Value := ""
                return
            }
        } else if (this.mode = "detail") {
            if (cmd = "V") {
                this.SwitchMode("versions")
                this.inputBox.Value := ""
                return
            }
        }

        ; Number + action commands
        if (RegExMatch(cmd, "^(\d+)([VORL]?)$", &m)) {
            num := Integer(m[1])
            action := m[2]
            if (action = "")
                action := "V"  ; Default action

            if (this.mode = "duplicates") {
                if (num < 1 || num > this.groups.Length) {
                    this.inputBox.Value := ""
                    return
                }
                if (action = "V") {
                    this.VersionGroup(num)
                } else if (action = "O") {
                    path := this.groups[num].files[1].path
                    Run('explorer.exe /select,"' path '"')
                }
            } else if (this.mode = "versions") {
                if (num < 1 || num > this.versionFolders.Length) {
                    this.inputBox.Value := ""
                    return
                }
                if (action = "L") {
                    this.LoadVersionDetail(this.versionFolders[num].baseName)
                    this.SwitchMode("detail")
                } else if (action = "O") {
                    Run('explorer.exe "' this.versionFolders[num].path '"')
                } else if (action = "R") {
                    this.RestoreVersion(this.versionFolders[num].baseName)
                }
            } else if (this.mode = "detail") {
                if (num < 1 || num > this.versionDetail.Length) {
                    this.inputBox.Value := ""
                    return
                }
                if (action = "R") {
                    this.RestoreVersion(this.currentBaseName, num)
                } else if (action = "O") {
                    vFile := this.versionDetail[num].versionFile
                    fullPath := this.versionDir "\" this.currentBaseName "\" vFile
                    Run('explorer.exe /select,"' fullPath '"')
                }
            }
        }

        this.inputBox.Value := ""
    }

    static SwitchMode(newMode) {
        this.mode := newMode
        this.inputBox.Value := ""

        if (newMode = "versions")
            this.ScanVersions()
        else if (newMode = "duplicates")
            this.ScanDownloads()

        ; Update headers
        try this.headerText.Value := this.GetHeaderText()
        try this.helpText.Value := this.GetHelpText()

        ; Rebuild ListView columns
        this.listView.Delete()
        cols := this.GetColumns()
        Loop this.listView.GetCount("Col")
            this.listView.DeleteCol(1)
        for col in cols
            this.listView.InsertCol(A_Index, , col)

        this.PopulateCurrentMode()

        ; Re-apply column widths
        if (this.gui) {
            try {
                WinGetPos(, , &w, &h, this.gui)
                this.OnResize(w, h)
            }
        }
    }

    ; ── JSON Persistence ──

    static LoadVersionsJson(baseName) {
        versions := []
        jsonPath := this.versionDir "\" baseName "\versions.json"

        if (!FileExist(jsonPath))
            return versions

        try {
            content := FileRead(jsonPath, "UTF-8")
            pos := 1
            while (pos := RegExMatch(content, '\{[^{}]+\}', &m, pos)) {
                obj := m[0]
                vFile := this.ExtractJsonField(obj, "versionFile")
                origName := this.ExtractJsonField(obj, "originalName")
                origPath := this.ExtractJsonField(obj, "originalPath")
                vAt := this.ExtractJsonField(obj, "versionedAt")
                fSize := this.ExtractJsonField(obj, "fileSize")
                fMod := this.ExtractJsonField(obj, "fileModified")

                if (vFile != "") {
                    versions.Push({
                        versionFile: vFile,
                        originalName: origName,
                        originalPath: origPath,
                        versionedAt: vAt,
                        fileSize: (fSize != "") ? Integer(fSize) : 0,
                        fileModified: fMod
                    })
                }
                pos += StrLen(m[0])
            }
        }
        return versions
    }

    static SaveVersionsJson(baseName, versions) {
        dirPath := this.versionDir "\" baseName
        if (!DirExist(dirPath))
            DirCreate(dirPath)

        json := '{"baseName": "' this.EscapeJson(baseName) '", "versions": ['
        first := true
        for v in versions {
            if (!first)
                json .= ","
            json .= "`n    {"
            json .= '"versionFile": "' this.EscapeJson(v.versionFile) '", '
            json .= '"originalName": "' this.EscapeJson(v.originalName) '", '
            json .= '"originalPath": "' this.EscapeJson(v.originalPath) '", '
            json .= '"versionedAt": "' this.EscapeJson(v.versionedAt) '", '
            json .= '"fileSize": "' v.fileSize '", '
            json .= '"fileModified": "' this.EscapeJson(v.fileModified) '"'
            json .= "}"
            first := false
        }
        json .= "`n]}"

        file := FileOpen(dirPath "\versions.json", "w", "UTF-8")
        file.Write(json)
        file.Close()
    }

    ; ── Helpers ──

    static FormatTimestamp(ahkTime) {
        ; AHK time format: YYYYMMDDHHMMSS → YYYYMMDD-HHmmss
        if (StrLen(ahkTime) < 14)
            return FormatTime(, "yyyyMMdd-HHmmss")
        return SubStr(ahkTime, 1, 8) "-" SubStr(ahkTime, 9, 6)
    }

    static FormatSize(bytes) {
        if (bytes < 1024)
            return bytes " B"
        if (bytes < 1048576)
            return Round(bytes / 1024, 1) " KB"
        if (bytes < 1073741824)
            return Round(bytes / 1048576, 1) " MB"
        return Round(bytes / 1073741824, 1) " GB"
    }

    static FormatDateShort(isoDate) {
        ; "2026-03-06T14:55:01" → "06/03 14:55"
        if (StrLen(isoDate) < 16)
            return isoDate
        day := SubStr(isoDate, 9, 2)
        month := SubStr(isoDate, 6, 2)
        time := SubStr(isoDate, 12, 5)
        return day "/" month " " time
    }

    static FileNameFromPath(fullPath) {
        SplitPath(fullPath, &name)
        return name
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
