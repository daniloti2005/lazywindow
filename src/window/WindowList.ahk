#Requires AutoHotkey v2.0

class WindowList {
    static excludeList := ["Program Manager", ""]
    
    static GetAll() {
        windows := []
        for hwnd in WinGetList() {
            try {
                title := WinGetTitle(hwnd)
                style := WinGetStyle(hwnd)
                exStyle := WinGetExStyle(hwnd)
                
                ; Check if visible and not a tool window
                isVisible := style & 0x10000000  ; WS_VISIBLE
                isToolWindow := exStyle & 0x80    ; WS_EX_TOOLWINDOW
                hasOwner := DllCall("GetWindow", "Ptr", hwnd, "UInt", 4, "Ptr")  ; GW_OWNER
                
                if (isVisible && !isToolWindow && !hasOwner && title != "" && !this.IsExcluded(title)) {
                    windows.Push({
                        hwnd: hwnd,
                        title: title,
                        processName: WinGetProcessName(hwnd)
                    })
                }
            }
        }
        return windows
    }
    
    static IsExcluded(title) {
        for excluded in this.excludeList {
            if (title = excluded) {
                return true
            }
        }
        return false
    }
    
    static GetWindowBounds(hwnd) {
        try {
            WinGetPos(&x, &y, &w, &h, hwnd)
            return {x: x, y: y, width: w, height: h}
        } catch {
            return false
        }
    }
    
    static FocusWindow(hwnd) {
        try {
            WinActivate(hwnd)
            WinWaitActive(hwnd,, 1)
            return true
        } catch {
            return false
        }
    }
}
