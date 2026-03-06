; EvidencePicker.ahk — Seletor visual de evidências para StoryTelling
; Lista clipboard, screenshots e pastas _steps do GIF recorder
; Preview: imagem estática ou animação 60fps para pastas de steps

class EvidencePicker {
    static gui := ""
    static listView := ""
    static previewPic := ""
    static previewText := ""
    static previewLabel := ""
    static footerText := ""
    static isVisible := false
    static confirmCb := ""
    static cancelCb := ""
    static items := []

    ; Animation
    static animFrames := []
    static animIndex := 0
    static animTickFn := ""
    static animActive := false

    static screenshotDir := ""

    static Init() {
        this.screenshotDir := EnvGet("USERPROFILE") "\.screenshot"
        this.animTickFn := this._AnimTick.Bind(this)
    }

    static Show(confirmCb, cancelCb := "") {
        this.confirmCb := confirmCb
        this.cancelCb := cancelCb
        if (this.gui) {
            try this.gui.Destroy()
            this.gui := ""
        }
        this._StopAnim()
        this._ScanEvidence()
        this._CreateGui()
        this.isVisible := true
    }

    static Hide() {
        this._StopAnim()
        if (this.gui) {
            try Hotkey("*Enter", "Off")
            try this.gui.Destroy()
            this.gui := ""
        }
        this.isVisible := false
    }

    ; ══════════════════════════════════════════════════════════════
    ; Evidence Scanning
    ; ══════════════════════════════════════════════════════════════

    static _ScanEvidence() {
        this.items := []

        ; 1. Clipboard
        clip := A_Clipboard
        if (clip != "") {
            clean := Trim(clip)
            type := "Texto"
            if (DirExist(clean))
                type := "Pasta"
            else if (FileExist(clean) && RegExMatch(clean, "i)\.(png|jpg|jpeg|gif|bmp|webp)$"))
                type := "Imagem"
            this.items.Push({
                type: type,
                path: clip,
                name: "📋 Clipboard",
                date: FormatTime(, "yyyy-MM-dd HH:mm"),
                size: type = "Texto" ? StrLen(clip) " chars" : ""
            })
        }

        ; 2. Screenshots and _steps folders from ~/.screenshot/
        if (!DirExist(this.screenshotDir))
            return

        ; PNG screenshots
        Loop Files, this.screenshotDir "\*.png" {
            this.items.Push({
                type: "Imagem",
                path: A_LoopFileFullPath,
                name: A_LoopFileName,
                date: FormatTime(A_LoopFileTimeModified, "yyyy-MM-dd HH:mm"),
                size: Round(A_LoopFileSize / 1024) " KB"
            })
        }

        ; _steps folders (from GIF recorder)
        Loop Files, this.screenshotDir "\*_steps", "D" {
            count := 0
            Loop Files, A_LoopFileFullPath "\*.png"
                count++
            if (count > 0) {
                this.items.Push({
                    type: "Steps",
                    path: A_LoopFileFullPath,
                    name: A_LoopFileName,
                    date: FormatTime(A_LoopFileTimeModified, "yyyy-MM-dd HH:mm"),
                    size: count " frames"
                })
            }
        }

        ; Sort non-clipboard items by date descending (bubble sort)
        startIdx := (A_Clipboard != "") ? 2 : 1
        n := this.items.Length
        sortCount := n - startIdx
        if (sortCount > 0) {
            loop {
                swapped := false
                Loop sortCount {
                    i := startIdx + A_Index - 1
                    if (i < n && StrCompare(this.items[i].date, this.items[i + 1].date) < 0) {
                        temp := this.items[i]
                        this.items[i] := this.items[i + 1]
                        this.items[i + 1] := temp
                        swapped := true
                    }
                }
                if (!swapped)
                    break
            }
        }
    }

    ; ══════════════════════════════════════════════════════════════
    ; GUI
    ; ══════════════════════════════════════════════════════════════

    static _CreateGui() {
        this.gui := Gui("+AlwaysOnTop +ToolWindow +Resize +OwnDialogs", "📎 Selecionar Evidência — LazyWindow")
        this.gui.Opt("-DPIScale")
        this.gui.BackColor := "1B2838"

        ; ── Title ──
        this.gui.SetFont("s14 cE8EDF3 Bold", "Cascadia Code")
        this.gui.AddText("x20 y12 w900", "📎 SELECIONAR EVIDÊNCIA")

        ; ── Separator ──
        this.gui.SetFont("s6 c3A5068", "Consolas")
        this.gui.AddText("x20 y42 w1800", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        ; ── Help ──
        this.gui.SetFont("s9 c5A7A94", "Cascadia Code")
        this.gui.AddText("x20 y55 w900", "  ↑↓ Navegar    Enter Confirmar    ESC Cancelar")

        ; ── ListView (left ~50%) ──
        this.gui.SetFont("s11 cD0D8E0", "Cascadia Code")
        this.listView := this.gui.AddListView("x20 y80 w860 h580 +Report -Multi -E0x200 +LV0x10020 Background0D1926 c7EB8DA"
            , ["#", "Tipo", "Nome", "Data", "Tamanho"])
        this._StyleDarkListView(this.listView)
        this.listView.ModifyCol(1, 40)
        this.listView.ModifyCol(2, 100)
        this.listView.ModifyCol(3, 420)
        this.listView.ModifyCol(4, 160)
        this.listView.ModifyCol(5, 100)

        for i, item in this.items
            this.listView.Add("", i, item.type, item.name, item.date, item.size)

        ; ── Preview (right ~50%) ──
        this.gui.SetFont("s10 c7EB8DA", "Cascadia Code")
        this.previewLabel := this.gui.AddText("x900 y55 w860 h25", "  Preview")

        this.gui.SetFont("s6 c2A3F54", "Consolas")
        this.gui.AddText("x900 y75 w860", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        ; Picture for image/steps preview
        this.previewPic := this.gui.AddPicture("x910 y90 w840 h560", "")

        ; Text preview (hidden, shown for text evidence)
        this.gui.SetFont("s10 cD0D8E0", "Cascadia Code")
        this.previewText := this.gui.AddEdit("x910 y90 w840 h560 +ReadOnly +Multi Background152230 cD0D8E0 -E0x200 +Hidden", "")

        ; ── Footer ──
        this.gui.SetFont("s10 c5A7A94", "Cascadia Code")
        this.footerText := this.gui.AddText("x20 y670 w1800 h25"
            , "  " this.items.Length " evidências disponíveis  ·  Selecione e pressione Enter")

        ; Events
        this.listView.OnEvent("ItemSelect", (ctrl, item, selected) => this._OnSelect(item, selected))
        this.gui.OnEvent("Escape", (*) => this._Cancel())
        this.gui.OnEvent("Close", (*) => this._Cancel())
        this.gui.OnEvent("Size", (g, m, w, h) => this._OnResize(w, h))

        this._ShowFullScreen()

        if (this.items.Length > 0)
            this.listView.Modify(1, "Select Focus")

        Hotkey("*Enter", (*) => this._Confirm(), "On")
    }

    static _ShowFullScreen() {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mx, &my)
        monNum := MonitorGetPrimary()
        count := MonitorGetCount()
        Loop count {
            MonitorGet(A_Index, &l, &t, &r, &b)
            if (mx >= l && mx < r && my >= t && my < b) {
                monNum := A_Index
                break
            }
        }
        MonitorGetWorkArea(monNum, &wL, &wT, &wR, &wB)
        this.gui.Show("x" wL " y" wT " w" (wR - wL) " h" (wB - wT))
        WinMaximize("ahk_id " this.gui.Hwnd)
        WinSetTransparent(215, this.gui)
    }

    static _StyleDarkListView(lv) {
        DllCall("uxtheme\SetWindowTheme", "Ptr", lv.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
        SendMessage(0x1001, 0, 0x26190D, lv)   ; LVM_SETBKCOLOR  (#0D1926)
        SendMessage(0x1026, 0, 0x26190D, lv)   ; LVM_SETTEXTBKCOLOR
        SendMessage(0x1024, 0, 0xDAB87E, lv)   ; LVM_SETTEXTCOLOR (#7EB8DA)
    }

    static _OnResize(w, h) {
        if (!this.listView)
            return
        try {
            halfW := Round(w / 2) - 30
            this.listView.Move(20, 80, halfW, h - 130)
            pX := halfW + 40
            pW := w - pX - 20
            this.previewLabel.Move(pX, 55, pW, 25)
            this.previewPic.Move(pX + 10, 90, pW - 20, h - 140)
            this.previewText.Move(pX + 10, 90, pW - 20, h - 140)
            this.footerText.Move(20, h - 38, w - 40, 25)
        }
    }

    ; ══════════════════════════════════════════════════════════════
    ; Preview
    ; ══════════════════════════════════════════════════════════════

    static _OnSelect(item, selected) {
        if (!selected || item < 1 || item > this.items.Length)
            return
        this._StopAnim()
        ev := this.items[item]

        if (ev.type = "Imagem") {
            path := Trim(ev.path)
            if (FileExist(path)) {
                this.previewText.Visible := false
                this.previewPic.Visible := true
                try this.previewPic.Value := "*w0 *h-1 " path
                this.previewLabel.Value := "  📸 " ev.name
            }
        } else if (ev.type = "Steps" || (ev.type = "Pasta" && DirExist(Trim(ev.path)))) {
            this.previewText.Visible := false
            this.previewPic.Visible := true
            this._StartAnim(Trim(ev.path))
        } else {
            ; Text evidence
            this.previewPic.Visible := false
            this.previewText.Visible := true
            this.previewText.Value := ev.path
            this.previewLabel.Value := "  📝 Texto (" StrLen(ev.path) " chars)"
        }
    }

    static _StartAnim(folderPath) {
        this.animFrames := []
        this.animIndex := 0

        Loop Files, folderPath "\*.png" {
            this.animFrames.Push(A_LoopFileFullPath)
        }

        if (this.animFrames.Length = 0) {
            this.previewLabel.Value := "  📂 Pasta sem imagens"
            return
        }

        ; Show first frame
        try this.previewPic.Value := "*w0 *h-1 " this.animFrames[1]
        this.animIndex := 1
        this.previewLabel.Value := "  🎬 " this.animFrames.Length " frames  ·  1/" this.animFrames.Length

        if (this.animFrames.Length > 1) {
            this.animActive := true
            SetTimer(this.animTickFn, 16)  ; ~60fps
        }
    }

    static _AnimTick() {
        if (!this.animActive || this.animFrames.Length = 0)
            return
        this.animIndex++
        if (this.animIndex > this.animFrames.Length)
            this.animIndex := 1
        try this.previewPic.Value := "*w0 *h-1 " this.animFrames[this.animIndex]
        if (Mod(this.animIndex, 30) = 0)
            try this.previewLabel.Value := "  🎬 " this.animFrames.Length " frames  ·  " this.animIndex "/" this.animFrames.Length
    }

    static _StopAnim() {
        if (this.animActive) {
            SetTimer(this.animTickFn, 0)
            this.animActive := false
        }
        this.animFrames := []
        this.animIndex := 0
    }

    ; ══════════════════════════════════════════════════════════════
    ; Actions
    ; ══════════════════════════════════════════════════════════════

    static _Confirm() {
        if (!this.isVisible)
            return
        row := this.listView.GetNext(0)
        if (row < 1 || row > this.items.Length) {
            this.footerText.Value := "  ⚠ Selecione uma evidência primeiro"
            return
        }
        item := this.items[row]
        cb := this.confirmCb
        this.Hide()
        if (cb)
            cb.Call(item)
    }

    static _Cancel() {
        cb := this.cancelCb
        this.Hide()
        if (cb)
            cb.Call()
    }
}
