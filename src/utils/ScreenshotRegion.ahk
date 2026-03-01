#Requires AutoHotkey v2.0

class ScreenshotRegion {
    static active      := false
    static onDone      := ""
    static startX      := 0
    static startY      := 0
    static dragging    := false
    static tickFn      := ""

    ; 4 dark overlay panels + selection highlight + 4 border lines
    static panTop    := ""
    static panBottom := ""
    static panLeft   := ""
    static panRight  := ""
    static panSel    := ""
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
        this.SetCrosshairCursor()

        ; Only Escape as hotkey; mouse is handled by polling GetKeyState
        Hotkey("*Escape", (*) => this.Cancel(), "On")

        ; Start polling timer
        if (!this.tickFn) {
            this.tickFn := this.Tick.Bind(this)
        }
        SetTimer(this.tickFn, 16)

        ToolTip("Clique e arraste para selecionar a região`nESC = cancelar")
        SetTimer(() => ToolTip(), -2000)
    }

    static CreateOverlays() {
        ; 4 dark semi-transparent panels covering the full virtual screen
        this.panTop    := this.MakePanel()
        this.panBottom := this.MakePanel()
        this.panLeft   := this.MakePanel()
        this.panRight  := this.MakePanel()

        ; Light highlight panel inside the selection (white tint)
        this.panSel    := this.MakeSel()

        ; 4 bright white border lines for the selection rectangle
        this.borTop    := this.MakeBorder()
        this.borBottom := this.MakeBorder()
        this.borLeft   := this.MakeBorder()
        this.borRight  := this.MakeBorder()

        ; Initially fill entire screen with the bottom panel (no selection yet)
        this.UpdatePanels(this.vsX, this.vsY, this.vsX, this.vsY)
    }

    static MakePanel() {
        g := Gui("+AlwaysOnTop -Caption +ToolWindow")
        g.Opt("-DPIScale")
        g.BackColor := "000000"
        g.Show("x0 y0 w1 h1 NoActivate")
        WinSetTransparent(190, "ahk_id " g.Hwnd)
        return g
    }

    static MakeSel() {
        g := Gui("+AlwaysOnTop -Caption +ToolWindow")
        g.Opt("-DPIScale")
        g.BackColor := "FFFFFF"
        g.Show("x0 y0 w1 h1 NoActivate")
        WinSetTransparent(35, "ahk_id " g.Hwnd)
        return g
    }

    static MakeBorder() {
        g := Gui("+AlwaysOnTop -Caption +ToolWindow")
        g.Opt("-DPIScale")
        g.BackColor := "FFFFFF"
        g.Show("x0 y0 w1 h1 NoActivate")
        WinSetTransparent(255, "ahk_id " g.Hwnd)
        return g
    }

    static UpdatePanels(x1, y1, x2, y2) {
        ; Normalise so x1 <= x2, y1 <= y2
        lx := Min(x1, x2)
        ly := Min(y1, y2)
        rx := Max(x1, x2)
        ry := Max(y1, y2)

        brd := 3   ; border thickness in px

        vs := {x: this.vsX, y: this.vsY, w: this.vsW, h: this.vsH}

        ; 4 dark panels surrounding the selection
        this.ShowPanel(this.panTop,    vs.x, vs.y,           vs.w,           ly - vs.y)
        this.ShowPanel(this.panBottom, vs.x, ry,             vs.w,           vs.y + vs.h - ry)
        this.ShowPanel(this.panLeft,   vs.x, ly,             lx - vs.x,      ry - ly)
        this.ShowPanel(this.panRight,  rx,   ly,             vs.x + vs.w - rx, ry - ly)

        ; Light highlight inside selection (visible only when dragging)
        selW := rx - lx
        selH := ry - ly
        if (selW > brd * 2 && selH > brd * 2) {
            this.ShowPanel(this.panSel, lx + brd, ly + brd, selW - brd * 2, selH - brd * 2)
        }

        ; White border lines
        this.ShowPanel(this.borTop,    lx,         ly,         rx - lx, brd)
        this.ShowPanel(this.borBottom, lx,         ry - brd,   rx - lx, brd)
        this.ShowPanel(this.borLeft,   lx,         ly,         brd,     ry - ly)
        this.ShowPanel(this.borRight,  rx - brd,   ly,         brd,     ry - ly)
    }

    static ShowPanel(g, x, y, w, h) {
        if (!(g is Gui)) {
            return
        }
        w := Max(w, 1)
        h := Max(h, 1)
        WinMove(x, y, w, h, "ahk_id " g.Hwnd)
    }

    static Tick() {
        if (!this.active) {
            SetTimer(this.tickFn, 0)
            return
        }

        lbDown := GetKeyState("LButton", "P")

        if (lbDown && !this.dragging) {
            ; Mouse button just pressed — start drag
            MouseGetPos(&mx, &my)
            this.startX   := mx
            this.startY   := my
            this.dragging := true
        } else if (lbDown && this.dragging) {
            ; Mouse held — update selection rectangle
            MouseGetPos(&mx, &my)
            this.UpdatePanels(this.startX, this.startY, mx, my)
        } else if (!lbDown && this.dragging) {
            ; Mouse released — finish selection
            SetTimer(this.tickFn, 0)
            MouseGetPos(&mx, &my)

            lx := Min(this.startX, mx)
            ly := Min(this.startY, my)
            w  := Abs(mx - this.startX)
            h  := Abs(my - this.startY)

            ; Save callback BEFORE Cleanup (which clears onDone)
            cb := this.onDone
            this.Cleanup()

            if (w < 5 || h < 5) {
                ToolTip("Seleção muito pequena — cancelado")
                SetTimer(() => ToolTip(), -1500)
                return
            }

            if (cb) {
                cb({x: lx, y: ly, width: w, height: h})
            }
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
        try Hotkey("*Escape", "Off")
        this.RestoreCursor()

        for panel in [this.panTop, this.panBottom, this.panLeft, this.panRight,
                      this.panSel,
                      this.borTop, this.borBottom, this.borLeft, this.borRight] {
            try panel.Destroy()
        }
        this.panTop    := ""
        this.panBottom := ""
        this.panLeft   := ""
        this.panRight  := ""
        this.panSel    := ""
        this.borTop    := ""
        this.borBottom := ""
        this.borLeft   := ""
        this.borRight  := ""
        this.onDone    := ""
    }

    static SetCrosshairCursor() {
        crossCursor := DllCall("LoadCursor", "Ptr", 0, "Ptr", 32515, "Ptr")
        for panel in [this.panTop, this.panBottom, this.panLeft, this.panRight, this.panSel,
                      this.borTop, this.borBottom, this.borLeft, this.borRight] {
            if (panel is Gui) {
                DllCall("SetClassLongPtr", "Ptr", panel.Hwnd, "Int", -12, "Ptr", crossCursor)
            }
        }
        DllCall("SetCursor", "Ptr", crossCursor)
    }

    static RestoreCursor() {
        arrowCursor := DllCall("LoadCursor", "Ptr", 0, "Ptr", 32512, "Ptr")
        DllCall("SetCursor", "Ptr", arrowCursor)
    }
}
