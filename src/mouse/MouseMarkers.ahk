#Requires AutoHotkey v2.0

class MouseMarkers {
    static markers := Map()
    static configDir := ""
    static configPath := ""

    static Init() {
        this.configDir := EnvGet("USERPROFILE") "\.lazywindow"
        this.configPath := this.configDir "\markers.json"
        this.Load()
    }

    static Save(slot) {
        if (slot < 1 || slot > 9)
            return

        pos := MouseController.GetPosition()
        this.markers[slot] := {x: pos.x, y: pos.y}
        this.Persist()

        ToolTip("Marcador " slot " salvo: (" pos.x ", " pos.y ")")
        SetTimer(() => ToolTip(), -1500)
    }

    static GoTo(slot) {
        if (slot < 1 || slot > 9)
            return false

        if (!this.markers.Has(slot)) {
            ToolTip("Marcador " slot " nao definido")
            SetTimer(() => ToolTip(), -1200)
            return false
        }

        marker := this.markers[slot]
        MouseController.MoveTo(marker.x, marker.y)
        ToolTip("Marcador " slot)
        SetTimer(() => ToolTip(), -800)
        return true
    }

    static GoToAndClick(slot) {
        if (this.GoTo(slot)) {
            Sleep(50)
            MouseController.LeftClick()
        }
    }

    static Persist() {
        try {
            if (!DirExist(this.configDir))
                DirCreate(this.configDir)

            json := "{"
            first := true
            for slot, marker in this.markers {
                if (!first)
                    json .= ","
                json .= '`n  "' slot '": {"x": ' marker.x ', "y": ' marker.y '}'
                first := false
            }
            json .= "`n}"

            file := FileOpen(this.configPath, "w", "UTF-8")
            file.Write(json)
            file.Close()
        }
    }

    static Load() {
        this.markers := Map()

        if (!FileExist(this.configPath))
            return

        try {
            content := FileRead(this.configPath, "UTF-8")

            ; Simple JSON parsing for our specific format
            Loop 9 {
                slot := A_Index
                pattern := '"' slot '"\s*:\s*\{\s*"x"\s*:\s*(-?\d+)\s*,\s*"y"\s*:\s*(-?\d+)\s*\}'
                if (RegExMatch(content, pattern, &m)) {
                    this.markers[slot] := {x: Integer(m[1]), y: Integer(m[2])}
                }
            }
        }
    }
}
