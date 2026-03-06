#Requires AutoHotkey v2.0

class StatusBar {
    static gui := ""
    static line1 := ""
    static line2 := ""
    static height := 28
    static refreshFn := ""
    static monitorNum := 1
    static shown := false
    static TRANSKEY := "1B2838"

    static Init() {
        if (this.gui) {
            return
        }

        this.monitorNum := MonitorGetPrimary()
        work := Monitor.GetWorkArea(this.monitorNum)
        if (!work) {
            return
        }

        ; Detect taskbar height
        tbH := this.height
        try {
            WinGetPos(, , , &tbHeight, "ahk_class Shell_TrayWnd")
            if (tbHeight > 0)
                tbH := tbHeight
        }

        this.shown := false
        this.gui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        this.gui.Opt("-DPIScale")
        this.gui.BackColor := this.TRANSKEY
        this.gui.MarginX := 0
        this.gui.MarginY := 0

        ; Two lines after weather widget area
        xStart := 200
        lineW := 130
        this.gui.SetFont("s7 cD0D8E0", "Cascadia Code")
        this.line1 := this.gui.AddText("x" xStart " y3 w" lineW " h14", "")
        this.gui.SetFont("s7 c7EB8DA", "Cascadia Code")
        this.line2 := this.gui.AddText("x" xStart " y" (tbH // 2 + 1) " w" lineW " h14", "")

        this.Dock()
        WinSetTransColor(this.TRANSKEY, this.gui)

        this.refreshFn := this.Refresh.Bind(this)
        this.Refresh()
        SetTimer(this.refreshFn, 200)
    }

    static Dock() {
        work := Monitor.GetWorkArea(this.monitorNum)
        bounds := Monitor.GetBounds(this.monitorNum)
        if (!work || !bounds || !this.gui) {
            return
        }

        x := work.x
        y := work.bottom - this.height
        w := work.width
        h := this.height

        ; Overlay directly on the taskbar
        try {
            WinGetPos(&tx, &ty, &tw, &th, "ahk_class Shell_TrayWnd")
            if (tx >= bounds.x && tx < bounds.right && ty >= bounds.y && ty < bounds.bottom) {
                if (tw > th) {
                    x := tx
                    y := ty
                    w := tw
                    h := th
                }
            }
        }

        if (this.shown) {
            WinMove(x, y, w, h, "ahk_id " this.gui.Hwnd)
        } else {
            this.gui.Show("x" x " y" y " w" w " h" h " NoActivate")
            this.shown := true
        }
    }

    static Refresh() {
        if (!this.gui || !this.line1 || !this.line2) {
            return
        }

        this.Dock()

        cursorOn := false
        vel := 0

        try cursorOn := ArrowMouse.IsEnabled()
        try vel := ArrowMouse.GetSpeedPercent()

        if (cursorOn) {
            rec := ""
            try {
                if (GifRecorder.IsRecording())
                    rec := "⏺REC "
            }
            this.line1.Value := rec "ON | Vel: " vel " dpi"
            this.line2.Value := "F3 F10 F11 | Alt+Home=OFF"
        } else {
            this.line1.Value := "OFF | Alt+Home=LIGAR"
            this.line2.Value := "F3=AJUDA"
        }
    }
}
