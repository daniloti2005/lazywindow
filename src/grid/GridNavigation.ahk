#Requires AutoHotkey v2.0

class GridNavigation {
    static currentOverlay := ""
    static isActive := false
    static onComplete := ""
    
    static Activate(monitorNum, onComplete := "") {
        if (this.isActive) {
            this.Deactivate()
        }
        
        if (!Monitor.Exists(monitorNum)) {
            return false
        }
        
        bounds := Monitor.GetBounds(monitorNum)
        this.currentOverlay := GridOverlay(bounds)
        this.currentOverlay.Show()
        this.isActive := true
        this.onComplete := onComplete
        this.EnableHotkeys()
        return true
    }
    
    static ActivateWithBounds(bounds) {
        if (this.isActive) {
            this.Deactivate()
        }
        
        this.currentOverlay := GridOverlay(bounds)
        this.currentOverlay.Show()
        this.isActive := true
        this.EnableHotkeys()
        return true
    }
    
    static NavigateTo(key) {
        if (!this.isActive || !this.currentOverlay) {
            return false
        }
        
        newBounds := this.currentOverlay.GetCellBounds(key)
        if (!newBounds) {
            return false
        }
        
        ; Destroy current overlay and create new one in selected cell
        this.currentOverlay.Destroy()
        this.currentOverlay := GridOverlay(newBounds)
        this.currentOverlay.Show()
        return true
    }
    
    static ExecuteClick(button := "Left") {
        if (!this.isActive || !this.currentOverlay) {
            return false
        }
        
        center := this.currentOverlay.GetCenter()
        this.Deactivate()
        
        MouseController.MoveTo(center.x, center.y)
        Sleep(50)
        
        if (button = "Left") {
            MouseController.LeftClick()
        } else {
            MouseController.RightClick()
        }
        
        return true
    }
    
    static Deactivate() {
        this.DisableHotkeys()
        if (this.currentOverlay) {
            this.currentOverlay.Destroy()
            this.currentOverlay := ""
        }
        this.isActive := false
    }
    
    static EnableHotkeys() {
        Hotkey("*a", (*) => this.NavigateTo("A"), "On")
        Hotkey("*s", (*) => this.NavigateTo("S"), "On")
        Hotkey("*d", (*) => this.NavigateTo("D"), "On")
        Hotkey("*z", (*) => this.NavigateTo("Z"), "On")
        Hotkey("*x", (*) => this.NavigateTo("X"), "On")
        Hotkey("*c", (*) => this.NavigateTo("C"), "On")
        Hotkey("*Enter", (*) => this.ExecuteClick("Right"), "On")
        Hotkey("*Backspace", (*) => this.ExecuteClick("Left"), "On")
        Hotkey("*Escape", (*) => this.Deactivate(), "On")
    }
    
    static DisableHotkeys() {
        try {
            Hotkey("*a", "Off")
            Hotkey("*s", "Off")
            Hotkey("*d", "Off")
            Hotkey("*z", "Off")
            Hotkey("*x", "Off")
            Hotkey("*c", "Off")
            Hotkey("*Enter", "Off")
            Hotkey("*Backspace", "Off")
            Hotkey("*Escape", "Off")
        }
    }
}
