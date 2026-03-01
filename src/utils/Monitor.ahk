#Requires AutoHotkey v2.0

class Monitor {
    static GetCount() {
        return MonitorGetCount()
    }
    
    static GetBounds(monitorNum) {
        if (monitorNum > this.GetCount() || monitorNum < 1) {
            return false
        }
        
        ; Use AutoHotkey's native monitor numbering so:
        ; 1 = Monitor 1, 2 = Monitor 2, 3 = Monitor 3
        MonitorGet(monitorNum, &left, &top, &right, &bottom)
        return {
            x: left,
            y: top,
            width: right - left,
            height: bottom - top,
            right: right,
            bottom: bottom
        }
    }
    
    static GetMonitorHandle(monitorNum) {
        monitors := []
        callback := CallbackCreate(MonitorEnumProc)
        DllCall("EnumDisplayMonitors", "Ptr", 0, "Ptr", 0, "Ptr", callback, "Ptr", ObjPtr(monitors))
        CallbackFree(callback)
        
        if (monitorNum <= monitors.Length) {
            return monitors[monitorNum]
        }
        return 0
        
        MonitorEnumProc(hMon, hDC, pRect, lParam) {
            arr := ObjFromPtrAddRef(lParam)
            arr.Push(hMon)
            return true
        }
    }
    
    static GetWorkArea(monitorNum) {
        if (monitorNum > this.GetCount() || monitorNum < 1) {
            return false
        }
        MonitorGetWorkArea(monitorNum, &left, &top, &right, &bottom)
        return {
            x: left,
            y: top,
            width: right - left,
            height: bottom - top,
            right: right,
            bottom: bottom
        }
    }
    
    static Exists(monitorNum) {
        return monitorNum >= 1 && monitorNum <= this.GetCount()
    }
}
