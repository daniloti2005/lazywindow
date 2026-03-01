#Requires AutoHotkey v2.0

class ArrowMouse {
    static enabled := false
    static speedPercent := 25
    static step := 25
    static intervalMs := 15
    static timerRunning := false
    static dragging := false
    static moveTickFn := ""
    static savedSpeed := 0
    static isSpeedToggled := false

    static Toggle() {
        if (this.enabled) {
            this.Disable()
        } else {
            this.Enable()
        }
    }

    static IsEnabled() {
        return this.enabled
    }

    static GetSpeedPercent() {
        return this.speedPercent
    }

    static SetSpeedPercent(dpi) {
        dpi := Integer(dpi)
        if (dpi < 1)
            dpi := 1
        if (dpi > 50)
            dpi := 50
        this.speedPercent := dpi
        this.UpdateStep()
    }

    static UpdateStep() {
        ; "DPI" here is the movement step per tick (1..50).
        this.step := Max(1, this.speedPercent)
    }
    
    static ToggleSpeed5() {
        if (this.isSpeedToggled) {
            ; Restaurar velocidade anterior
            this.speedPercent := this.savedSpeed
            this.isSpeedToggled := false
            this.UpdateStep()
            ToolTip("Velocidade restaurada: " this.speedPercent " dpi")
        } else {
            ; Salvar velocidade atual e mudar para 5
            this.savedSpeed := this.speedPercent
            this.speedPercent := 5
            this.isSpeedToggled := true
            this.UpdateStep()
            ToolTip("Velocidade: 5 dpi (anterior: " this.savedSpeed ")")
        }
        SetTimer(() => ToolTip(), -1500)
    }

    static Enable() {
        if (this.enabled) {
            return
        }
        global g_hotkeysEnabled
        g_hotkeysEnabled := true
        this.UpdateStep()
        if (!this.moveTickFn) {
            this.moveTickFn := this.MoveTick.Bind(this)
        }
        this.enabled := true
        this.EnableHotkeys()
        this.ShowStatusTip(true)
    }

    static Disable() {
        if (!this.enabled) {
            return
        }
        global g_hotkeysEnabled
        this.StopTimer()
        this.EndDrag()
        this.DisableHotkeys()
        this.enabled := false
        g_hotkeysEnabled := false
        this.ShowStatusTip(false)
    }

    static PauseForSwitcher() {
        ; Pause arrow mouse without changing g_hotkeysEnabled
        if (!this.enabled) {
            return
        }
        this.StopTimer()
        this.EndDrag()
        this.DisableHotkeys()
        this.enabled := false
    }

    static EnableHotkeys() {
        ; Arrow keys: block normal behavior and move mouse while held
        Hotkey("*Up", (*) => this.OnArrowDown(), "On")
        Hotkey("*Down", (*) => this.OnArrowDown(), "On")
        Hotkey("*Left", (*) => this.OnArrowDown(), "On")
        Hotkey("*Right", (*) => this.OnArrowDown(), "On")

        Hotkey("*Up Up", (*) => this.OnArrowUp(), "On")
        Hotkey("*Down Up", (*) => this.OnArrowUp(), "On")
        Hotkey("*Left Up", (*) => this.OnArrowUp(), "On")
        Hotkey("*Right Up", (*) => this.OnArrowUp(), "On")

        ; Mouse buttons while ArrowMouse is enabled
        Hotkey("*F1", (*) => MouseController.RightClick(), "On")
        Hotkey("*F2", (*) => MouseController.LeftClick(), "On")

        ; Horizontal scroll: Alt+- (left) and Alt+= (right)
        Hotkey("!-", (*) => MouseController.ScrollLeft(), "On")
        Hotkey("!=", (*) => MouseController.ScrollRight(), "On")

        ; Drag: hold Ctrl while moving with arrows
        Hotkey("~*LControl Up", (*) => this.OnCtrlUp(), "On")
        Hotkey("~*RControl Up", (*) => this.OnCtrlUp(), "On")
    }

    static DisableHotkeys() {
        try Hotkey("*Up", "Off")
        try Hotkey("*Down", "Off")
        try Hotkey("*Left", "Off")
        try Hotkey("*Right", "Off")

        try Hotkey("*Up Up", "Off")
        try Hotkey("*Down Up", "Off")
        try Hotkey("*Left Up", "Off")
        try Hotkey("*Right Up", "Off")

        try Hotkey("*F1", "Off")
        try Hotkey("*F2", "Off")

        try Hotkey("!-", "Off")
        try Hotkey("!=", "Off")

        try Hotkey("~*LControl Up", "Off")
        try Hotkey("~*RControl Up", "Off")
    }

    static OnArrowDown() {
        this.StartTimer()
    }

    static OnArrowUp() {
        ; Stop when no arrows are held
        if (!GetKeyState("Up", "P") && !GetKeyState("Down", "P") && !GetKeyState("Left", "P") && !GetKeyState("Right", "P")) {
            this.StopTimer()
        }
    }

    static StartTimer() {
        if (this.timerRunning) {
            return
        }
        if (!this.moveTickFn) {
            this.moveTickFn := this.MoveTick.Bind(this)
        }
        this.timerRunning := true
        SetTimer(this.moveTickFn, this.intervalMs)
    }

    static StopTimer() {
        if (!this.timerRunning) {
            return
        }
        if (this.moveTickFn) {
            SetTimer(this.moveTickFn, 0)
        }
        this.timerRunning := false
    }

    static MoveTick() {
        if (!this.enabled) {
            this.StopTimer()
            return
        }

        dx := 0
        dy := 0

        if (GetKeyState("Left", "P"))
            dx -= 1
        if (GetKeyState("Right", "P"))
            dx += 1
        if (GetKeyState("Up", "P"))
            dy -= 1
        if (GetKeyState("Down", "P"))
            dy += 1

        if (dx = 0 && dy = 0) {
            this.StopTimer()
            return
        }

        ctrlDown := GetKeyState("LControl", "P") || GetKeyState("RControl", "P")
        if (ctrlDown) {
            this.StartDrag()
        }

        step := this.step
        if (dx != 0 && dy != 0) {
            step := Round(this.step / 1.41421356237)  ; keep roughly same speed diagonally
        }

        pos := MouseController.GetPosition()
        newX := pos.x + (dx * step)
        newY := pos.y + (dy * step)
        MouseController.MoveTo(newX, newY)
    }

    static StartDrag() {
        if (this.dragging) {
            return
        }
        Click("Down")
        this.dragging := true
    }

    static EndDrag() {
        if (!this.dragging) {
            return
        }
        Click("Up")
        this.dragging := false
    }

    static OnCtrlUp() {
        this.EndDrag()
    }

    static ShowStatusTip(isOn) {
        msg := isOn ? ("Comandos: ON | Modo Setas: ON | Vel: " this.speedPercent " dpi") : "Comandos: OFF | Modo Setas: OFF"
        ToolTip(msg)
        SetTimer(() => ToolTip(), -1200)
    }
}
