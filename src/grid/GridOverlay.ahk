#Requires AutoHotkey v2.0

class GridOverlay {
    gui := ""
    bounds := ""
    labels := []
    cellWidth := 0
    cellHeight := 0
    isVisible := false
    
    __New(bounds) {
        this.bounds := bounds
        this.cellWidth := bounds.width // 3
        this.cellHeight := bounds.height // 2
        this.CreateGui()
    }
    
    CreateGui() {
        this.gui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        this.gui.Opt("-DPIScale")  ; Use raw pixels so overlay matches monitor bounds
        this.gui.BackColor := "1a1a2e"
        this.gui.MarginX := 0
        this.gui.MarginY := 0
        
        ; Draw grid cells with labels
        keys := ["A", "S", "D", "Z", "X", "C"]
        colors := ["16213e", "1a1a2e", "16213e", "1a1a2e", "16213e", "1a1a2e"]
        
        loop 2 {
            row := A_Index - 1
            loop 3 {
                col := A_Index - 1
                idx := row * 3 + col + 1
                
                cellX := col * this.cellWidth
                cellY := row * this.cellHeight
                
                ; Cell background
                this.gui.SetFont("s48 bold", "Segoe UI")
                label := this.gui.AddText(
                    "x" cellX " y" cellY " w" this.cellWidth " h" this.cellHeight 
                    " Center BackgroundTrans c0f3460",
                    keys[idx]
                )
                label.Opt("+0x200")  ; Center vertically
                this.labels.Push(label)
            }
        }
        
        ; Draw grid lines
        this.DrawGridLines()
    }
    
    DrawGridLines() {
        lineColor := "e94560"
        lineThickness := 3
        
        ; Vertical lines
        loop 2 {
            x := A_Index * this.cellWidth
            this.gui.AddProgress("x" x " y0 w" lineThickness " h" this.bounds.height " Background" lineColor)
        }
        
        ; Horizontal line
        y := this.cellHeight
        this.gui.AddProgress("x0 y" y " w" this.bounds.width " h" lineThickness " Background" lineColor)
        
        ; Border
        this.gui.AddProgress("x0 y0 w" this.bounds.width " h" lineThickness " Background" lineColor)  ; Top
        this.gui.AddProgress("x0 y" (this.bounds.height - lineThickness) " w" this.bounds.width " h" lineThickness " Background" lineColor)  ; Bottom
        this.gui.AddProgress("x0 y0 w" lineThickness " h" this.bounds.height " Background" lineColor)  ; Left
        this.gui.AddProgress("x" (this.bounds.width - lineThickness) " y0 w" lineThickness " h" this.bounds.height " Background" lineColor)  ; Right
    }
    
    Show() {
        this.gui.Show("x" this.bounds.x " y" this.bounds.y " w" this.bounds.width " h" this.bounds.height " NoActivate")
        WinSetTransparent(200, this.gui)
        this.isVisible := true
    }
    
    Hide() {
        this.gui.Hide()
        this.isVisible := false
    }
    
    Destroy() {
        if (this.gui) {
            this.gui.Destroy()
            this.gui := ""
        }
        this.isVisible := false
    }
    
    GetCellBounds(key) {
        key := StrUpper(key)
        positions := Map(
            "A", {col: 0, row: 0},
            "S", {col: 1, row: 0},
            "D", {col: 2, row: 0},
            "Z", {col: 0, row: 1},
            "X", {col: 1, row: 1},
            "C", {col: 2, row: 1}
        )
        
        if (!positions.Has(key)) {
            return false
        }
        
        pos := positions[key]
        return {
            x: this.bounds.x + (pos.col * this.cellWidth),
            y: this.bounds.y + (pos.row * this.cellHeight),
            width: this.cellWidth,
            height: this.cellHeight
        }
    }
    
    GetCenter() {
        return {
            x: this.bounds.x + (this.bounds.width // 2),
            y: this.bounds.y + (this.bounds.height // 2)
        }
    }
}
