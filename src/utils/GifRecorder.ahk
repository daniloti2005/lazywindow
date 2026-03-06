#Requires AutoHotkey v2.0

class GifRecorder {
    ; ── State ──────────────────────────────────────────────────────────────────
    static recording   := false
    static frameCount  := 0
    static tempDir     := ""
    static outputPath  := ""
    static fps         := 60       ; frames per second (60 = video-like recording)
    static scale       := 0.5      ; resolution scale (0.5 = half native resolution)
    static canvasW     := 0        ; scaled canvas width
    static canvasH     := 0
    static gdipToken   := 0
    static pngClsid    := ""
    static tickFn      := ""
    static pollFn      := ""
    static clickFrames := 0        ; frames remaining to show yellow click ring

    ; ── Public API ─────────────────────────────────────────────────────────────

    static Start() {
        if (this.recording)
            return

        ; Temp folder for PNG frames
        ts := FormatTime(, "yyyyMMdd_HHmmss")
        this.tempDir := A_Temp "\LazyWindow_GIF_" ts
        DirCreate(this.tempDir)

        ; Output path in ~/.screenshot/
        screenshotDir := EnvGet("USERPROFILE") "\.screenshot"
        try DirCreate(screenshotDir)

        seq := 1
        Loop Files screenshotDir "\LazyWindow_GIF_*.gif" {
            if RegExMatch(A_LoopFileName, "^LazyWindow_GIF_(\d+)_", &m) {
                n := m[1] + 0
                if (n >= seq)
                    seq := n + 1
            }
        }
        this.outputPath := screenshotDir "\LazyWindow_GIF_" Format("{:03}", seq) "_" ts ".gif"

        ; Reset counters and canvas
        this.frameCount  := 0
        this.canvasW     := 0
        this.canvasH     := 0
        this.clickFrames := 0

        ; Prepare GDI+ (lazy init)
        this._GdipInit()

        this.recording := true

        if (!this.tickFn)
            this.tickFn := this.Tick.Bind(this)
        SetTimer(this.tickFn, Round(1000 / this.fps))

        ToolTip("⏺ GIF gravando (Ctrl+F5 = parar)`nMáximo 60s | Steps PNG copiados para pasta")
        SetTimer(() => ToolTip(), -4000)
    }

    static Tick() {
        if (!this.recording)
            return

        ; Safety cap: 60 seconds at current FPS
        if (this.frameCount >= this.fps * 60) {
            ToolTip("⚠ Limite de 60s atingido. Parando gravação.")
            SetTimer(() => ToolTip(), -3000)
            this.Stop()
            return
        }

        MouseGetPos(&mx, &my)
        mon := this._MonitorForPoint(mx, my)

        ; Canvas size is fixed to the first frame's monitor (scaled)
        if (this.canvasW = 0) {
            this.canvasW := Round(mon.w * this.scale)
            this.canvasH := Round(mon.h * this.scale)
        }

        ; Detect mouse click (left=0x01 or right=0x02 button down)
        lBtn := DllCall("GetAsyncKeyState", "Int", 0x01, "Short")
        rBtn := DllCall("GetAsyncKeyState", "Int", 0x02, "Short")
        if (lBtn & 0x8000) || (rBtn & 0x8000)
            this.clickFrames := 20  ; show ring for 20 frames (~333ms at 60fps)

        ; Mouse position relative to monitor, scaled
        relX := Round((mx - mon.l) * this.scale)
        relY := Round((my - mon.t) * this.scale)
        showClick := this.clickFrames > 0

        framePath := this.tempDir "\frame_" Format("{:04d}", this.frameCount) ".png"
        this._CaptureFrame(mon.l, mon.t, mon.w, mon.h, framePath, relX, relY, showClick)
        this.frameCount++

        if (this.clickFrames > 0)
            this.clickFrames--
    }

    static Stop() {
        if (!this.recording)
            return

        this.recording := false
        SetTimer(this.tickFn, 0)

        fc := this.frameCount
        if (fc = 0) {
            ToolTip("Nenhum frame capturado")
            SetTimer(() => ToolTip(), -2000)
            this._CleanTemp()
            return
        }

        ToolTip("⏳ Criando GIF (" fc " frames)...")

        ; Write PowerShell conversion script
        psScript := this._BuildGifScript()
        psFile    := this.tempDir "\make_gif.ps1"
        try {
            fh := FileOpen(psFile, "w", "UTF-8-RAW")
            fh.Write(psScript)
            fh.Close()
        } catch {
            ToolTip("Falha ao criar script PS")
            SetTimer(() => ToolTip(), -2000)
            this._CleanTemp()
            return
        }

        ; Launch PS non-blocking (shell = "", hide window)
        Run("powershell -STA -NoProfile -ExecutionPolicy Bypass -File `"" psFile "`"", , "Hide")

        ; Steps folder path (same as GIF but _steps suffix)
        stepsDir := RegExReplace(this.outputPath, "\.gif$", "_steps")

        ; Poll every 500ms for the output file (up to 10 min)
        outPath  := this.outputPath
        tempDir  := this.tempDir
        this.tempDir := ""   ; prevent early cleanup

        this.pollFn := this._PollGifDone.Bind(this, outPath, stepsDir, tempDir, A_TickCount)
        SetTimer(this.pollFn, 500)
    }

    static Cancel() {
        if (!this.recording)
            return
        this.recording := false
        SetTimer(this.tickFn, 0)
        this._CleanTemp()
        ToolTip("Gravação GIF cancelada")
        SetTimer(() => ToolTip(), -1500)
    }

    static IsRecording() {
        return this.recording
    }

    static GetFrameCount() {
        return this.frameCount
    }

    ; ── Private helpers ────────────────────────────────────────────────────────

    static _PollGifDone(outPath, stepsDir, tempDir, startTick) {
        ; Wait for both GIF and _steps folder to be ready
        if (FileExist(outPath) && DirExist(stepsDir)) {
            SetTimer(this.pollFn, 0)
            A_Clipboard := stepsDir
            ToolTip("✅ GIF + Steps salvos:`n" stepsDir "`nCaminho da pasta copiado!")
            SetTimer(() => ToolTip(), -5000)
            try DirDelete(tempDir, true)
            return
        }
        if (A_TickCount - startTick > 600000) {  ; 10 min timeout
            SetTimer(this.pollFn, 0)
            ToolTip("⚠ Timeout ao criar GIF/Steps")
            SetTimer(() => ToolTip(), -3000)
            try DirDelete(tempDir, true)
        }
    }

    static _MonitorForPoint(x, y) {
        Loop MonitorGetCount() {
            MonitorGet(A_Index, &l, &t, &r, &b)
            if (x >= l && x < r && y >= t && y < b)
                return {l: l, t: t, w: r - l, h: b - t}
        }
        n := MonitorGetPrimary()
        MonitorGet(n, &l, &t, &r, &b)
        return {l: l, t: t, w: r - l, h: b - t}
    }

    static _GdipInit() {
        if (this.gdipToken)
            return
        if (!DllCall("GetModuleHandle", "Str", "gdiplus", "Ptr"))
            DllCall("LoadLibrary", "Str", "gdiplus")
        si := Buffer(24, 0)
        NumPut("UInt", 1, si, 0)   ; GdiplusVersion = 1
        DllCall("gdiplus\GdiplusStartup", "Ptr*", &tok := 0, "Ptr", si, "Ptr", 0)
        this.gdipToken := tok
        ; Cache PNG encoder CLSID
        this.pngClsid := Buffer(16)
        DllCall("ole32\CLSIDFromString",
                "Str", "{557CF406-1A04-11D3-9A73-0000F81EF32E}",
                "Ptr", this.pngClsid)
    }

    static _CaptureFrame(x, y, srcW, srcH, framePath, mouseX, mouseY, showClick) {
        dstW := this.canvasW
        dstH := this.canvasH

        ; ── 1. StretchBlt screen → scaled memory bitmap ──────────────────────
        hScreen := DllCall("GetDC", "Ptr", 0, "Ptr")
        hMemDC  := DllCall("CreateCompatibleDC", "Ptr", hScreen, "Ptr")
        hBmp    := DllCall("CreateCompatibleBitmap", "Ptr", hScreen, "Int", dstW, "Int", dstH, "Ptr")
        hOld    := DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hBmp, "Ptr")
        DllCall("SetStretchBltMode", "Ptr", hMemDC, "Int", 4)  ; HALFTONE
        DllCall("SetBrushOrgEx", "Ptr", hMemDC, "Int", 0, "Int", 0, "Ptr", 0)
        DllCall("StretchBlt",
                "Ptr", hMemDC, "Int", 0, "Int", 0, "Int", dstW, "Int", dstH,
                "Ptr", hScreen, "Int", x, "Int", y, "Int", srcW, "Int", srcH,
                "UInt", 0x40CC0020)  ; SRCCOPY | CAPTUREBLT

        ; ── 2. Draw mouse cursor on the captured frame ───────────────────────
        ci := Buffer(24, 0)  ; CURSORINFO (64-bit)
        NumPut("UInt", 24, ci, 0)
        if DllCall("GetCursorInfo", "Ptr", ci) {
            cFlags  := NumGet(ci, 4, "UInt")
            hCursor := NumGet(ci, 8, "Ptr")
            if (cFlags & 1) {  ; CURSOR_SHOWING
                ; Get hotspot offset
                ii := Buffer(32, 0)  ; ICONINFO (64-bit)
                if DllCall("GetIconInfo", "Ptr", hCursor, "Ptr", ii) {
                    hsX := NumGet(ii, 4, "UInt")
                    hsY := NumGet(ii, 8, "UInt")
                    hbmMask  := NumGet(ii, 16, "Ptr")
                    hbmColor := NumGet(ii, 24, "Ptr")
                    if (hbmMask)
                        DllCall("DeleteObject", "Ptr", hbmMask)
                    if (hbmColor)
                        DllCall("DeleteObject", "Ptr", hbmColor)
                    DllCall("DrawIconEx", "Ptr", hMemDC,
                            "Int", mouseX - hsX, "Int", mouseY - hsY,
                            "Ptr", hCursor, "Int", 0, "Int", 0,
                            "UInt", 0, "Ptr", 0, "UInt", 3)  ; DI_NORMAL
                }
            }
        }

        ; ── 3. Draw yellow click ring if mouse button is pressed ─────────────
        if (showClick) {
            radius := 20
            hPen := DllCall("CreatePen", "Int", 0, "Int", 3, "UInt", 0x0000FFFF, "Ptr")
            hOldPen := DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hPen, "Ptr")
            hNullBrush := DllCall("GetStockObject", "Int", 5, "Ptr")
            hOldBrush := DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hNullBrush, "Ptr")
            DllCall("Ellipse", "Ptr", hMemDC,
                    "Int", mouseX - radius, "Int", mouseY - radius,
                    "Int", mouseX + radius, "Int", mouseY + radius)
            DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hOldBrush)
            DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hOldPen)
            DllCall("DeleteObject", "Ptr", hPen)
        }

        DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hOld)
        DllCall("DeleteDC", "Ptr", hMemDC)
        DllCall("ReleaseDC", "Ptr", 0, "Ptr", hScreen)

        ; ── 4. Convert HBITMAP → GDI+ bitmap → PNG ──────────────────────────
        DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", hBmp, "Ptr", 0, "Ptr*", &pBmp := 0)
        DllCall("DeleteObject", "Ptr", hBmp)

        wPath := Buffer((StrLen(framePath) + 1) * 2)
        StrPut(framePath, wPath, "UTF-16")
        DllCall("gdiplus\GdipSaveImageToFile",
                "Ptr", pBmp, "Ptr", wPath, "Ptr", this.pngClsid, "Ptr", 0)
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pBmp)
    }

    static _BuildGifScript() {
        td  := this.tempDir
        op  := this.outputPath
        fp  := this.fps
        dc  := Round(100 / fp)   ; centiseconds per frame (GIF unit)

        s := ""
        s .= "$tempDir  = `"" td "`"`n"
        s .= "$outPath  = `"" op "`"`n"
        s .= "$fps      = " fp "`n"
        s .= "$delayCs  = " dc "`n"
        s .= "`n"

        ; ── Try FFmpeg (no external installer, might already be on PATH) ──
        s .= "$ffmpeg = $null`n"
        s .= "foreach ($c in @('ffmpeg','C:\ffmpeg\bin\ffmpeg.exe','C:\tools\ffmpeg.exe','C:\ProgramData\chocolatey\bin\ffmpeg.exe')) {`n"
        s .= "    if (Get-Command $c -ErrorAction SilentlyContinue) { $ffmpeg = $c; break }`n"
        s .= "    if (Test-Path $c) { $ffmpeg = $c; break }`n"
        s .= "}`n"
        s .= "$files = Get-ChildItem $tempDir -Filter 'frame_*.png' | Sort-Object Name`n"
        s .= "if ($files.Count -eq 0) { exit 1 }`n"
        s .= "`n"

        ; ── Create _steps folder with 1 PNG per second (before GIF, uses temp frames) ──
        s .= "# Create steps folder with every frame for AI analysis`n"
        s .= "$stepsDir = $outPath -replace '\.gif$', '_steps'`n"
        s .= "New-Item -ItemType Directory -Force -Path $stepsDir | Out-Null`n"
        s .= "$stepNum = 1`n"
        s .= "foreach ($f in $files) {`n"
        s .= "    Copy-Item $f.FullName (Join-Path $stepsDir ('step_{0:D5}.png' -f $stepNum))`n"
        s .= "    $stepNum++`n"
        s .= "}`n"
        s .= "`n"

        ; ── Build GIF ──
        s .= "if ($ffmpeg) {`n"
        s .= "    & $ffmpeg -framerate $fps -i `"$tempDir\frame_%04d.png`" -vf `"split[s0][s1];[s0]palettegen=stats_mode=diff[p];[s1][p]paletteuse=dither=sierra2_4a`" -loop 0 -y `"$outPath`" 2>`$null`n"
        s .= "    exit $LASTEXITCODE`n"
        s .= "}`n"
        s .= "`n"

        ; ── Fallback: System.Drawing MultiFrame GIF encoder (no extra tools) ──
        s .= "Add-Type -AssemblyName System.Drawing`n"
        s .= "`n"
        s .= "$gifCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/gif' }`n"
        s .= "$enc = [System.Drawing.Imaging.Encoder]`n"
        s .= "$first = [System.Drawing.Image]::FromFile($files[0].FullName)`n"
        s .= "`n"
        s .= "$ep = New-Object System.Drawing.Imaging.EncoderParameters(1)`n"
        s .= "$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(`n"
        s .= "    $enc::SaveFlag, [long][System.Drawing.Imaging.EncoderValue]::MultiFrame)`n"
        s .= "$first.Save($outPath, $gifCodec, $ep)`n"
        s .= "`n"
        s .= "for ($i = 1; $i -lt $files.Count; $i++) {`n"
        s .= "    $frm = [System.Drawing.Image]::FromFile($files[$i].FullName)`n"
        s .= "    $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(`n"
        s .= "        $enc::SaveFlag, [long][System.Drawing.Imaging.EncoderValue]::FrameDimensionTime)`n"
        s .= "    $first.SaveAdd($frm, $ep)`n"
        s .= "    $frm.Dispose()`n"
        s .= "}`n"
        s .= "$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(`n"
        s .= "    $enc::SaveFlag, [long][System.Drawing.Imaging.EncoderValue]::Flush)`n"
        s .= "$first.SaveAdd($ep)`n"
        s .= "$first.Dispose()`n"
        s .= "`n"

        ; ── Patch GCE delay bytes so the GIF plays at the correct speed ──────
        ; GCE block: 0x21 0xF9 0x04 [flags] [delay_lo] [delay_hi] [tcidx] 0x00
        s .= "$bytes = [System.IO.File]::ReadAllBytes($outPath)`n"
        s .= "$i = 0`n"
        s .= "while ($i -lt ($bytes.Length - 7)) {`n"
        s .= "    if ($bytes[$i] -eq 0x21 -and $bytes[$i+1] -eq 0xF9 -and $bytes[$i+2] -eq 0x04) {`n"
        s .= "        $bytes[$i+4] = [byte]($delayCs -band 0xFF)`n"
        s .= "        $bytes[$i+5] = [byte](($delayCs -shr 8) -band 0xFF)`n"
        s .= "        $i += 8`n"
        s .= "    } else { $i++ }`n"
        s .= "}`n"
        s .= "[System.IO.File]::WriteAllBytes($outPath, $bytes)`n"
        s .= "exit 0`n"

        return s
    }

    static _CleanTemp() {
        if (this.tempDir != "")
            try DirDelete(this.tempDir, true)
        this.tempDir := ""
    }
}
