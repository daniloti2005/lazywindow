#Requires AutoHotkey v2.0

class ScreenshotRegion {
    static active      := false
    static onDone      := ""
    static startX      := 0
    static startY      := 0
    static dragging    := false
    static tickFn      := ""

    ; 4 dark overlay panels + 4 border lines
    static panTop    := ""
    static panBottom := ""
    static panLeft   := ""
    static panRight  := ""
    static borTop    := ""
    static borBottom := ""
    static borLeft   := ""
    static borRight  := ""

    ; Virtual screen bounds (all monitors combined)
    static vsX := 0
    static vsY := 0
    static vsW := 0
    static vsH := 0

    static Select(onDone) {
        if (this.active) {
            return
        }
        this.onDone  := onDone
        this.active  := true
        this.dragging := false

        ; Get virtual screen spanning all monitors
        this.vsX := SysGet(76)   ; SM_XVIRTUALSCREEN
        this.vsY := SysGet(77)   ; SM_YVIRTUALSCREEN
        this.vsW := SysGet(78)   ; SM_CXVIRTUALSCREEN
        this.vsH := SysGet(79)   ; SM_CYVIRTUALSCREEN

        this.CreateOverlays()
        this.EnableHotkeys()

        ToolTip("Clique e arraste para selecionar a região`nESC = cancelar")
        SetTimer(() => ToolTip(), -2000)
    }

    static CreateOverlays() {
        ; 4 dark semi-transparent panels covering the full virtual screen
        this.panTop    := this.MakePanel()
        this.panBottom := this.MakePanel()
        this.panLeft   := this.MakePanel()
        this.panRight  := this.MakePanel()

        ; 4 thin bright border lines for the selection rectangle
        this.borTop    := this.MakeBorder()
        this.borBottom := this.MakeBorder()
        this.borLeft   := this.MakeBorder()
        this.borRight  := this.MakeBorder()

        ; Initially fill entire screen with the top panel (no selection yet)
        this.UpdatePanels(this.vsX, this.vsY, this.vsX, this.vsY)
    }

    static MakePanel() {
        g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        g.Opt("-DPIScale")
        g.BackColor := "000000"
        g.Show("x0 y0 w1 h1 NoActivate")
        WinSetTransparent(130, g)
        return g
    }

    static MakeBorder() {
        g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        g.Opt("-DPIScale")
        g.BackColor := "00BFFF"
        g.Show("x0 y0 w1 h1 NoActivate")
        WinSetTransparent(220, g)
        return g
    }

    static UpdatePanels(x1, y1, x2, y2) {
        ; Normalise so x1 <= x2, y1 <= y2
        lx := Min(x1, x2)
        ly := Min(y1, y2)
        rx := Max(x1, x2)
        ry := Max(y1, y2)

        brd := 2   ; border thickness in px

        vs := {x: this.vsX, y: this.vsY, w: this.vsW, h: this.vsH}

        ; Top panel: full width, from virtual top to selection top
        this.ShowPanel(this.panTop,    vs.x, vs.y,           vs.w,      ly - vs.y)
        ; Bottom panel: full width, from selection bottom to virtual bottom
        this.ShowPanel(this.panBottom, vs.x, ry,             vs.w,      vs.y + vs.h - ry)
        ; Left panel: selection height band, left of selection
        this.ShowPanel(this.panLeft,   vs.x, ly,             lx - vs.x, ry - ly)
        ; Right panel: selection height band, right of selection
        this.ShowPanel(this.panRight,  rx,   ly,             vs.x + vs.w - rx, ry - ly)

        ; Border lines
        this.ShowPanel(this.borTop,    lx,      ly,          rx - lx, brd)
        this.ShowPanel(this.borBottom, lx,      ry - brd,    rx - lx, brd)
        this.ShowPanel(this.borLeft,   lx,      ly,          brd,     ry - ly)
        this.ShowPanel(this.borRight,  rx - brd, ly,         brd,     ry - ly)
    }

    static ShowPanel(g, x, y, w, h) {
        if (!(g is Gui)) {
            return
        }
        w := Max(w, 1)
        h := Max(h, 1)
        WinMove(x, y, w, h, "ahk_id " g.Hwnd)
    }

    static EnableHotkeys() {
        Hotkey("*LButton",    (*) => this.OnMouseDown(), "On")
        Hotkey("*LButton Up", (*) => this.OnMouseUp(),   "On")
        Hotkey("*Escape",     (*) => this.Cancel(),      "On")
    }

    static DisableHotkeys() {
        try Hotkey("*LButton",    "Off")
        try Hotkey("*LButton Up", "Off")
        try Hotkey("*Escape",     "Off")
    }

    static OnMouseDown() {
        if (!this.active) {
            return
        }
        MouseGetPos(&mx, &my)
        this.startX   := mx
        this.startY   := my
        this.dragging := true

        if (!this.tickFn) {
            this.tickFn := this.Tick.Bind(this)
        }
        SetTimer(this.tickFn, 30)
    }

    static Tick() {
        if (!this.active || !this.dragging) {
            SetTimer(this.tickFn, 0)
            return
        }
        MouseGetPos(&mx, &my)
        this.UpdatePanels(this.startX, this.startY, mx, my)
    }

    static OnMouseUp() {
        if (!this.active || !this.dragging) {
            return
        }
        SetTimer(this.tickFn, 0)
        MouseGetPos(&mx, &my)

        lx := Min(this.startX, mx)
        ly := Min(this.startY, my)
        w  := Abs(mx - this.startX)
        h  := Abs(my - this.startY)

        this.Cleanup()

        if (w < 5 || h < 5) {
            ToolTip("Seleção muito pequena — cancelado")
            SetTimer(() => ToolTip(), -1500)
            return
        }

        cb := this.onDone
        if (cb) {
            cb({x: lx, y: ly, width: w, height: h})
        }
    }

    static Cancel() {
        if (!this.active) {
            return
        }
        if (this.tickFn) {
            SetTimer(this.tickFn, 0)
        }
        this.Cleanup()
        ToolTip("Screenshot cancelado")
        SetTimer(() => ToolTip(), -1200)
    }

    static Cleanup() {
        ; Set flags first so any in-flight timer/hotkey returns early
        this.active   := false
        this.dragging := false

        if (this.tickFn) {
            SetTimer(this.tickFn, 0)
        }
        this.DisableHotkeys()

        for panel in [this.panTop, this.panBottom, this.panLeft, this.panRight,
                      this.borTop, this.borBottom, this.borLeft, this.borRight] {
            try panel.Destroy()
        }
        this.panTop    := ""
        this.panBottom := ""
        this.panLeft   := ""
        this.panRight  := ""
        this.borTop    := ""
        this.borBottom := ""
        this.borLeft   := ""
        this.borRight  := ""
        this.onDone    := ""
    }
}
