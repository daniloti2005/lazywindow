#Requires AutoHotkey v2.0

class SpeedDialog {
    static gui := ""
    static edit := ""

    static Show() {
        if (this.gui) {
            try {
                this.edit.Value := ArrowMouse.GetSpeedPercent()
                this.gui.Show("AutoSize Center")
                WinActivate("ahk_id " this.gui.Hwnd)
                this.edit.Focus()
                Send "^a"
                return
            }
        }

        this.gui := Gui("+AlwaysOnTop +ToolWindow", "Velocidade do Mouse")
        this.gui.BackColor := "1B2838"
        this.gui.SetFont("s11 cD0D8E0", "Cascadia Code")

        this.gui.AddText("x12 y12 w360", "Digite a velocidade (DPI 1 a 50):")

        this.gui.SetFont("s14 cA8D8B9", "Cascadia Code")
        this.edit := this.gui.AddEdit("x12 y40 w120 h34 Number Background152230 cA8D8B9")
        this.edit.Value := ArrowMouse.GetSpeedPercent()

        this.gui.SetFont("s11 cD0D8E0", "Cascadia Code")
        okBtn := this.gui.AddButton("x150 y40 w80 h34 Default", "OK")
        cancelBtn := this.gui.AddButton("x240 y40 w100 h34", "Cancelar")

        okBtn.OnEvent("Click", (*) => this.Apply())
        cancelBtn.OnEvent("Click", (*) => this.Close())

        this.gui.OnEvent("Escape", (*) => this.Close())
        this.gui.OnEvent("Close", (*) => this.Close())

        this.gui.Show("AutoSize Center")
        WinActivate("ahk_id " this.gui.Hwnd)
        this.edit.Focus()
        Send "^a"
    }

    static Apply() {
        val := Trim(this.edit.Value)
        if (!RegExMatch(val, "^\d+$")) {
            SoundBeep(900)
            return
        }

        dpi := Integer(val)
        if (dpi < 1 || dpi > 50) {
            SoundBeep(900)
            return
        }

        ArrowMouse.SetSpeedPercent(dpi)
        try StatusBar.Refresh()
        this.Close()
    }

    static Close() {
        try this.gui.Hide()
    }
}
