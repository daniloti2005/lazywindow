#Requires AutoHotkey v2.0

class StatusBar {
    static gui := ""
    static text := ""
    static height := 28
    static refreshFn := ""
    static monitorNum := 1
    static shown := false

    static Init() {
        if (this.gui) {
            return
        }

        this.monitorNum := MonitorGetPrimary()
        work := Monitor.GetWorkArea(this.monitorNum)
        if (!work) {
            return
        }

        this.shown := false
        this.gui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        this.gui.Opt("-DPIScale")
        this.gui.BackColor := "05060a"  ; dark space
        this.gui.MarginX := 0
        this.gui.MarginY := 0

        ; "lightsaber" accent line
        this.gui.AddProgress("x0 y0 w" work.width " h2 c00FF7F Background05060a", 100)

        ; Tiny ASCII icons (3 droids + 1 alien baby), sized to fit reliably
        this.gui.SetFont("s5 c00FF7F", "Consolas")
        this.gui.AddText("x6  y4 w26 h18", "[o]`n|_|")
        this.gui.AddText("x30 y4 w26 h18", "{o}`n|#|")
        this.gui.AddText("x54 y4 w30 h18", "/o\\`n|_|")
        this.gui.AddText("x86 y4 w44 h18", "(^_^)`n /|\\")

        ; Main status text
        this.gui.SetFont("s7 cCFEFEA", "Segoe UI")
        this.text := this.gui.AddText("x132 y5 w" (work.width - 142) " h" (this.height - 6), "")

        this.Dock()
        WinSetTransparent(230, this.gui)

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

        ; Prefer using the real taskbar rectangle when it's on this monitor
        try {
            WinGetPos(&tx, &ty, &tw, &th, "ahk_class Shell_TrayWnd")
            if (tx >= bounds.x && tx < bounds.right && ty >= bounds.y && ty < bounds.bottom) {
                if (tw > th) {
                    ; horizontal taskbar
                    if (ty > bounds.y + (bounds.height // 2)) {
                        y := ty - this.height - 1
                    } else {
                        y := ty + th + 1
                    }
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
