#Requires AutoHotkey v2.0

class WindowSwitcher {
    static gui := ""
    static listView := ""
    static inputBox := ""
    static windows := []
    static isVisible := false
    
    static Show() {
        if (this.isVisible) {
            this.Hide()
            return
        }
        
        this.windows := WindowList.GetAll()
        if (this.windows.Length = 0) {
            return
        }
        
        this.CreateGui()
        this.isVisible := true
    }
    
    static CreateGui() {
        this.gui := Gui("+AlwaysOnTop -MinimizeBox", "LazyWindow - Seletor de Janelas")
        this.gui.BackColor := "1B2838"
        this.gui.SetFont("s11 c7EB8DA", "Cascadia Code")
        
        this.gui.AddText("x10 y10 w500", "Digite: [número][posição] (Ex: 1, 2C, 3RD)")
        this.gui.AddText("x10 y35 w500 c5A7A94", "Posições: C=Centro T=Topo E=Esquerda D=Direita R=Rodapé")
        
        this.gui.SetFont("s10 cA8D8B9", "Cascadia Code")
        this.inputBox := this.gui.AddEdit("x10 y65 w500 h30 Background152230")
        this.inputBox.OnEvent("Change", (*) => this.OnInputChange())
        
        this.gui.SetFont("s10 cD0D8E0", "Cascadia Code")
        this.listView := this.gui.AddListView("x10 y105 w500 h300 -Hdr +Report -E0x200 +LV0x10020 Background0D1926 c7EB8DA", ["#", "Processo", "Janela"])
        this.listView.ModifyCol(1, 35)
        this.listView.ModifyCol(2, 120)
        this.listView.ModifyCol(3, 335)
        DllCall("uxtheme\SetWindowTheme", "Ptr", this.listView.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
        SendMessage(0x1001, 0, 0x26190D, this.listView)
        SendMessage(0x1026, 0, 0x26190D, this.listView)
        SendMessage(0x1024, 0, 0xDAB87E, this.listView)
        
        ; Populate list
        for idx, win in this.windows {
            procName := RegExReplace(win.processName, "\.exe$", "")
            displayTitle := StrLen(win.title) > 45 ? SubStr(win.title, 1, 42) . "..." : win.title
            this.listView.Add("", idx, procName, displayTitle)
        }
        
        this.gui.OnEvent("Escape", (*) => this.Hide())
        this.gui.OnEvent("Close", (*) => this.Hide())
        
        ; Center on primary monitor
        this.gui.Show("w520 h420")
        this.inputBox.Focus()
        
        ; Enable Enter hotkey
        Hotkey("*Enter", (*) => this.Execute(), "On")
    }
    
    static OnInputChange() {
        ; Highlight matching row
        text := this.inputBox.Value
        if (RegExMatch(text, "^(\d+)", &match)) {
            num := Integer(match[1])
            if (num >= 1 && num <= this.windows.Length) {
                this.listView.Modify(num, "Select Focus Vis")
            }
        }
    }
    
    static Execute() {
        text := Trim(this.inputBox.Value)
        if (text = "") {
            this.Hide()
            return
        }
        
        ; Parse input: number + optional position letters
        if (!RegExMatch(text, "i)^(\d+)([CTEDR]{0,2})$", &match)) {
            return
        }
        
        windowNum := Integer(match[1])
        position := StrUpper(match[2])
        
        if (windowNum < 1 || windowNum > this.windows.Length) {
            return
        }
        
        win := this.windows[windowNum]
        this.Hide()
        
        ; Focus window
        WindowList.FocusWindow(win.hwnd)
        Sleep(100)
        
        ; Get window bounds and calculate mouse position
        bounds := WindowList.GetWindowBounds(win.hwnd)
        if (!bounds) {
            return
        }
        
        mousePos := this.CalculatePosition(bounds, position)
        MouseController.MoveTo(mousePos.x, mousePos.y)
    }
    
    static CalculatePosition(bounds, position) {
        ; Default to center
        if (position = "" || position = "C") {
            return {
                x: bounds.x + bounds.width // 2,
                y: bounds.y + bounds.height // 2
            }
        }
        
        marginX := bounds.width // 10
        marginY := bounds.height // 10
        
        x := bounds.x + bounds.width // 2
        y := bounds.y + bounds.height // 2
        
        ; Process each letter
        loop StrLen(position) {
            letter := SubStr(position, A_Index, 1)
            switch letter {
                case "T":
                    y := bounds.y + marginY
                case "R":
                    y := bounds.y + bounds.height - marginY
                case "E":
                    x := bounds.x + marginX
                case "D":
                    x := bounds.x + bounds.width - marginX
            }
        }
        
        return {x: x, y: y}
    }
    
    static Hide() {
        try Hotkey("*Enter", "Off")
        if (this.gui) {
            this.gui.Destroy()
            this.gui := ""
        }
        this.isVisible := false
    }
}
