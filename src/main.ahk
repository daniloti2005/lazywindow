#Requires AutoHotkey v2.0
#SingleInstance Force

; Enable DPI awareness for correct monitor coordinates
DllCall("SetThreadDpiAwarenessContext", "Ptr", -3, "Ptr")  ; DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2

; Include all modules
#Include "utils\Monitor.ahk"
#Include "mouse\MouseController.ahk"
#Include "mouse\ArrowMouse.ahk"
#Include "mouse\MouseMarkers.ahk"
#Include "ui\StatusBar.ahk"
#Include "ui\SpeedDialog.ahk"
#Include "ui\HelpWindow.ahk"
#Include "ui\TeamsHelpWindow.ahk"
#Include "ui\LazyVimHelpWindow.ahk"
#Include "utils\CodeBeautify.ahk"
#Include "utils\Base64.ahk"
#Include "utils\Timestamp.ahk"
#Include "utils\ScreenshotRegion.ahk"
#Include "grid\GridOverlay.ahk"
#Include "grid\GridNavigation.ahk"
#Include "window\WindowList.ahk"
#Include "window\WindowSwitcher.ahk"
#Include "snippets\SnippetManager.ahk"

; Global settings
SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Screen")

; Tray icon and menu
A_IconTip := "LazyWindow - Controle do mouse por teclado"
TraySetIcon("shell32.dll", 25)

tray := A_TrayMenu
tray.Delete()
tray.Add("LazyWindow", (*) => "")
tray.Disable("LazyWindow")
tray.Add()
tray.Add("Monitor 1 (Ctrl+End)", (*) => ActivateGrid(1))
tray.Add("Monitor 2 (Ctrl+Del)", (*) => ActivateGrid(2))
tray.Add("Monitor 3 (Ctrl+PgDn)", (*) => ActivateGrid(3))
tray.Add()
tray.Add("Seletor de Janelas (Ctrl+Home)", (*) => OpenWindowSwitcher())
tray.Add("Modo Setas (Alt+Home)", (*) => ArrowMouse.Toggle())
tray.Add("Velocidade do Mouse (Ctrl+F12)", (*) => SpeedDialog.Show())
tray.Add()
tray.Add("Snippet Manager (Ctrl+Alt+F10)", (*) => SnippetManager.Toggle())
tray.Add("Ajuda (F3)", (*) => HelpWindow.Toggle())
tray.Add("Atalhos Teams (F10)", (*) => TeamsHelpWindow.Toggle())
tray.Add("Ajuda LazyVim (F11)", (*) => LazyVimHelpWindow.Toggle())
tray.Add("Recarregar", (*) => Reload())
tray.Add("Sair", (*) => ExitApp())

; Hotkeys
^End::ActivateGrid(1)    ; Ctrl+End = Monitor 1
^Del::ActivateGrid(2)    ; Ctrl+Del = Monitor 2
^PgDn::ActivateGrid(3)   ; Ctrl+PgDn = Monitor 3
^PgUp::ActivateGridOnWindow()  ; Ctrl+PgUp = Grid na janela ativa
!PgUp::ActivateGridAroundCursor()  ; Alt+PgUp = Grid ao redor do cursor
^Home::OpenWindowSwitcher()  ; Ctrl+Home = Window Switcher
!Home::ArrowMouse.Toggle()    ; Alt+Home = Arrow Mouse Mode
^F12::SpeedDialog.Show()      ; Ctrl+F12 = Set Arrow Mouse speed
!F12::SetSpeed8()             ; Alt+F12 = Set Arrow Mouse speed to 8
^Ins::DecreaseSpeed()         ; Ctrl+Ins = Diminuir velocidade
!Ins::IncreaseSpeed()         ; Alt+Ins = Aumentar velocidade
+End::ArrowMouse.ToggleSpeed5()  ; Shift+End = Toggle velocidade 5 dpi
F3::HelpWindow.Toggle()       ; F3 = Ajuda (rolável)
F10::TeamsHelpWindow.Toggle()  ; F10 = Ajuda de atalhos do Microsoft Teams
F11::LazyVimHelpWindow.Toggle() ; F11 = Ajuda de atalhos do LazyVim

F7::WinMaximize("A")          ; F7 = Maximizar janela ativa
F6::WinMinimize("A")          ; F6 = Minimizar janela ativa
F8::WinClose("A")             ; F8 = Fechar janela ativa
^F6::TakeActiveWindowShot()    ; Ctrl+F6 = Print da janela ativa
^+F6::TakeWindowShotPathOnly() ; Ctrl+Shift+F6 = Print da janela ativa (caminho no clipboard)
^F7::TakeRegionShot()          ; Ctrl+F7 = Selecionar região (imagem no clipboard + arquivo)
^+F7::TakeRegionShotPathOnly() ; Ctrl+Shift+F7 = Selecionar região (caminho no clipboard)
^+b::CodeBeautify.Beautify()   ; Ctrl+Shift+B = Beautify clipboard (JSON/XML)
^+a::Base64.Encode()           ; Ctrl+Shift+A = Encode clipboard para Base64
^!a::Base64.Decode()           ; Ctrl+Alt+A = Decode Base64 do clipboard
^+t::Timestamp.ToEpoch()       ; Ctrl+Shift+T = Data para Epoch
^!t::Timestamp.FromEpoch()     ; Ctrl+Alt+T = Epoch para Data
^!F10::SnippetManager.Toggle()  ; Ctrl+Alt+F10 = Snippet Manager

[::Send "{WheelUp}"           ; Scroll up
]::Send "{WheelDown}"         ; Scroll down

^=::Send "^{WheelUp}"          ; Zoom in (Ctrl+ScrollUp)
^-::Send "^{WheelDown}"        ; Zoom out (Ctrl+ScrollDown)

ActivateGrid(monitorNum) {
    if (!Monitor.Exists(monitorNum)) {
        ToolTip("Monitor " monitorNum " não encontrado")
        SetTimer(() => ToolTip(), -2000)
        return
    }
    GridNavigation.Activate(monitorNum)
}

ActivateGridOnWindow() {
    try {
        hwnd := WinExist("A")
        if (!hwnd) {
            ToolTip("Nenhuma janela ativa")
            SetTimer(() => ToolTip(), -2000)
            return
        }
        WinGetPos(&x, &y, &w, &h, hwnd)
        if (w < 50 || h < 50) {
            ToolTip("Janela muito pequena")
            SetTimer(() => ToolTip(), -2000)
            return
        }
        bounds := {x: x, y: y, width: w, height: h}
        GridNavigation.ActivateWithBounds(bounds)
    } catch {
        ToolTip("Erro ao obter janela ativa")
        SetTimer(() => ToolTip(), -2000)
    }
}

ActivateGridAroundCursor() {
    static gridSize := 400
    
    MouseGetPos(&mx, &my)
    
    ; Calculate bounds centered on cursor
    x := mx - (gridSize // 2)
    y := my - (gridSize // 2)
    
    ; Get monitor bounds to clamp the grid inside the screen
    monitorNum := 1
    cnt := Monitor.GetCount()
    Loop cnt {
        b := Monitor.GetBounds(A_Index)
        if (b && mx >= b.x && mx < b.x + b.width && my >= b.y && my < b.y + b.height) {
            monitorNum := A_Index
            break
        }
    }
    
    monBounds := Monitor.GetBounds(monitorNum)
    if (!monBounds) {
        monBounds := {x: 0, y: 0, width: A_ScreenWidth, height: A_ScreenHeight}
    }
    
    ; Clamp to screen bounds
    if (x < monBounds.x)
        x := monBounds.x
    if (y < monBounds.y)
        y := monBounds.y
    if (x + gridSize > monBounds.x + monBounds.width)
        x := monBounds.x + monBounds.width - gridSize
    if (y + gridSize > monBounds.y + monBounds.height)
        y := monBounds.y + monBounds.height - gridSize
    
    bounds := {x: x, y: y, width: gridSize, height: gridSize}
    GridNavigation.ActivateWithBounds(bounds)
}

OpenWindowSwitcher() {
    if (ArrowMouse.IsEnabled()) {
        ArrowMouse.Disable()
    }
    WindowSwitcher.Show()
}

TakeActiveWindowShot() {
    ; Alt+PrintScreen copies the active window screenshot to clipboard
    Send "!{PrintScreen}"
    Sleep 150

    screenshotDir := EnvGet("USERPROFILE") "\\.screenshot"
    try DirCreate(screenshotDir)

    seq := 1
    Loop Files screenshotDir "\\LazyWindow_*.png" {
        if RegExMatch(A_LoopFileName, "^LazyWindow_(\\d+)_", &m) {
            n := m[1] + 0
            if (n >= seq)
                seq := n + 1
        }
    }

    seqStr := Format("{:03}", seq)
    ts := FormatTime(, "yyyyMMdd_HHmmss")
    filePath := screenshotDir "\\LazyWindow_" seqStr "_" ts ".png"

    ps := "powershell -STA -NoProfile -ExecutionPolicy Bypass -Command " . Chr(34)
        . "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; "
        . "$img=[System.Windows.Forms.Clipboard]::GetImage(); if($null -eq $img){ exit 2 }; "
        . "$path='" filePath "'; $img.Save($path,[System.Drawing.Imaging.ImageFormat]::Png);"
        . Chr(34)

    rc := RunWait(ps, , "Hide")
    if (rc = 0) {
        ToolTip("Print copiado e salvo:`n" filePath)
    } else {
        ToolTip("Print copiado; falha ao salvar (rc=" rc ")")
    }
    SetTimer(() => ToolTip(), -2500)
}

TakeWindowShotPathOnly() {
    ; Same capture/save logic as TakeActiveWindowShot, but puts the file path in clipboard instead of the image
    Send "!{PrintScreen}"
    Sleep 150

    screenshotDir := EnvGet("USERPROFILE") "\\.screenshot"
    try DirCreate(screenshotDir)

    seq := 1
    Loop Files screenshotDir "\\LazyWindow_*.png" {
        if RegExMatch(A_LoopFileName, "^LazyWindow_(\\d+)_", &m) {
            n := m[1] + 0
            if (n >= seq)
                seq := n + 1
        }
    }

    seqStr := Format("{:03}", seq)
    ts := FormatTime(, "yyyyMMdd_HHmmss")
    filePath := screenshotDir "\\LazyWindow_" seqStr "_" ts ".png"

    ps := "powershell -STA -NoProfile -ExecutionPolicy Bypass -Command " . Chr(34)
        . "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; "
        . "$img=[System.Windows.Forms.Clipboard]::GetImage(); if($null -eq $img){ exit 2 }; "
        . "$path='" filePath "'; $img.Save($path,[System.Drawing.Imaging.ImageFormat]::Png);"
        . Chr(34)

    rc := RunWait(ps, , "Hide")
    if (rc = 0) {
        A_Clipboard := filePath
        ToolTip("Caminho copiado:`n" filePath)
    } else {
        ToolTip("Print copiado; falha ao salvar (rc=" rc ")")
    }
    SetTimer(() => ToolTip(), -2500)
}

TakeRegionShot() {
    ScreenshotRegion.Select((bounds) => _SaveRegionShot(bounds, false))
}

TakeRegionShotPathOnly() {
    ScreenshotRegion.Select((bounds) => _SaveRegionShot(bounds, true))
}

_SaveRegionShot(bounds, pathOnly) {
    screenshotDir := EnvGet("USERPROFILE") "\\.screenshot"
    try DirCreate(screenshotDir)

    seq := 1
    Loop Files screenshotDir "\\LazyWindow_*.png" {
        if RegExMatch(A_LoopFileName, "^LazyWindow_(\\d+)_", &m) {
            n := m[1] + 0
            if (n >= seq)
                seq := n + 1
        }
    }

    seqStr   := Format("{:03}", seq)
    ts       := FormatTime(, "yyyyMMdd_HHmmss")
    filePath := screenshotDir "\\LazyWindow_" seqStr "_" ts ".png"

    x := bounds.x
    y := bounds.y
    w := bounds.width
    h := bounds.height

    if (pathOnly) {
        ; Capture region, save PNG, put file path in clipboard
        ps := "powershell -STA -NoProfile -ExecutionPolicy Bypass -Command " . Chr(34)
            . "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; "
            . "$bmp=New-Object System.Drawing.Bitmap(" w "," h "); "
            . "$g=[System.Drawing.Graphics]::FromImage($bmp); "
            . "$g.CopyFromScreen(" x "," y ",0,0,[System.Drawing.Size]::new(" w "," h ")); "
            . "$g.Dispose(); "
            . "$bmp.Save('" filePath "',[System.Drawing.Imaging.ImageFormat]::Png); "
            . "$bmp.Dispose();"
            . Chr(34)
        rc := RunWait(ps, , "Hide")
        if (rc = 0) {
            A_Clipboard := filePath
            ToolTip("Caminho copiado:`n" filePath)
        } else {
            ToolTip("Falha ao capturar região (rc=" rc ")")
        }
    } else {
        ; Capture region, save PNG, put image in clipboard
        ps := "powershell -STA -NoProfile -ExecutionPolicy Bypass -Command " . Chr(34)
            . "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; "
            . "$bmp=New-Object System.Drawing.Bitmap(" w "," h "); "
            . "$g=[System.Drawing.Graphics]::FromImage($bmp); "
            . "$g.CopyFromScreen(" x "," y ",0,0,[System.Drawing.Size]::new(" w "," h ")); "
            . "$g.Dispose(); "
            . "$bmp.Save('" filePath "',[System.Drawing.Imaging.ImageFormat]::Png); "
            . "[System.Windows.Forms.Clipboard]::SetImage($bmp); "
            . "$bmp.Dispose();"
            . Chr(34)
        rc := RunWait(ps, , "Hide")
        if (rc = 0) {
            ToolTip("Região copiada e salva:`n" filePath)
        } else {
            ToolTip("Falha ao capturar região (rc=" rc ")")
        }
    }
    SetTimer(() => ToolTip(), -2500)
}


SetSpeed8() {
    ArrowMouse.SetSpeedPercent(8)
    ToolTip("Velocidade do cursor: 8 dpi")
    SetTimer(() => ToolTip(), -1500)
}

DecreaseSpeed() {
    newSpeed := ArrowMouse.GetSpeedPercent() - 1
    if (newSpeed < 1)
        newSpeed := 1
    ArrowMouse.SetSpeedPercent(newSpeed)
    ToolTip("Velocidade: " newSpeed " dpi")
    SetTimer(() => ToolTip(), -1000)
}

IncreaseSpeed() {
    newSpeed := ArrowMouse.GetSpeedPercent() + 1
    if (newSpeed > 50)
        newSpeed := 50
    ArrowMouse.SetSpeedPercent(newSpeed)
    ToolTip("Velocidade: " newSpeed " dpi")
    SetTimer(() => ToolTip(), -1000)
}

; Initialize status bar
StatusBar.Init()

; Initialize mouse markers
MouseMarkers.Init()

; Hotkeys for mouse markers (Ctrl+N = save, Alt+N = go, Ctrl+Alt+N = go and click)
^1::MouseMarkers.Save(1)
^2::MouseMarkers.Save(2)
^3::MouseMarkers.Save(3)
^4::MouseMarkers.Save(4)
^5::MouseMarkers.Save(5)
^6::MouseMarkers.Save(6)
^7::MouseMarkers.Save(7)
^8::MouseMarkers.Save(8)
^9::MouseMarkers.Save(9)

!1::MouseMarkers.GoTo(1)
!2::MouseMarkers.GoTo(2)
!3::MouseMarkers.GoTo(3)
!4::MouseMarkers.GoTo(4)
!5::MouseMarkers.GoTo(5)
!6::MouseMarkers.GoTo(6)
!7::MouseMarkers.GoTo(7)
!8::MouseMarkers.GoTo(8)
!9::MouseMarkers.GoTo(9)

^!1::MouseMarkers.GoToAndClick(1)
^!2::MouseMarkers.GoToAndClick(2)
^!3::MouseMarkers.GoToAndClick(3)
^!4::MouseMarkers.GoToAndClick(4)
^!5::MouseMarkers.GoToAndClick(5)
^!6::MouseMarkers.GoToAndClick(6)
^!7::MouseMarkers.GoToAndClick(7)
^!8::MouseMarkers.GoToAndClick(8)
^!9::MouseMarkers.GoToAndClick(9)

; Show startup notification
ToolTip("LazyWindow iniciado!`nCtrl+End/Del/PgDn = Grid`nCtrl+Home = Janelas`nAlt+Home = Modo Setas")
SetTimer(() => ToolTip(), -3500)
