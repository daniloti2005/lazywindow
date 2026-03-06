#Requires AutoHotkey v2.0

class StatusBar {
    static gui := ""
    static text := ""
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

        ; Detect taskbar height for vertical centering
        tbH := this.height
        try {
            WinGetPos(, , , &tbHeight, "ahk_class Shell_TrayWnd")
            if (tbHeight > 0)
                tbH := tbHeight
        }
        vOff := Max(2, (tbH - 16) // 2)

        this.shown := false
        this.gui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        this.gui.Opt("-DPIScale")
        this.gui.BackColor := this.TRANSKEY
        this.gui.MarginX := 0
        this.gui.MarginY := 0

        ; Status text only — no decorations
        this.gui.SetFont("s8 cD0D8E0", "Cascadia Code")
        this.text := this.gui.AddText("x6 y" vOff " w" (work.width - 12) " h20", "")

        this.Dock()
        ; Transparent background — text floats over taskbar
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
        if (!this.gui || !this.text) {
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
                    rec := "⏺ REC (" GifRecorder.GetFrameCount() " frames) | "
            }
            this.text.Value := rec "ON | Vel: " vel " dpi | F3=AJUDA | F10=TEAMS | F11=VIM | Alt+Home=OFF"
        } else {
            this.text.Value := "OFF | Alt+Home=LIGAR | F3=AJUDA"
        }
    }
}
