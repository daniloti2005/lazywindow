#Requires AutoHotkey v2.0

class Timestamp {
    static ToEpoch() {
        content := Trim(A_Clipboard)
        
        tempOut := A_Temp "\lazywindow_ts_out.txt"

        try {
            ; If empty, use current time
            if (content = "") {
                ps := 'powershell -NoProfile -ExecutionPolicy Bypass -Command "'
                    . "$e = [DateTimeOffset]::Now.ToUnixTimeSeconds(); "
                    . "$e | Out-File -Encoding ASCII '" tempOut "'"
                    . '"'
            } else {
                tempIn := A_Temp "\lazywindow_ts_in.txt"
                file := FileOpen(tempIn, "w", "UTF-8")
                file.Write(content)
                file.Close()

                ps := 'powershell -NoProfile -ExecutionPolicy Bypass -Command "'
                    . "$c = Get-Content -Raw -Encoding UTF8 '" tempIn "'; "
                    . "$c = $c.Trim(); "
                    . "try { $d = [DateTimeOffset]::Parse($c); $e = $d.ToUnixTimeSeconds(); "
                    . "$e | Out-File -Encoding ASCII '" tempOut "' } "
                    . 'catch { exit 1 }"'
            }

            rc := RunWait(ps, , "Hide")
            if (rc != 0) {
                this.Cleanup(tempOut)
                if (content != "")
                    this.Cleanup(tempIn)
                ToolTip("Erro: formato de data invalido")
                SetTimer(() => ToolTip(), -2000)
                return
            }

            result := Trim(FileRead(tempOut, "UTF-8"))
            this.Cleanup(tempOut)
            if (content != "")
                this.Cleanup(tempIn)

            A_Clipboard := result
            if (content = "") {
                ToolTip("Epoch atual: " result)
            } else {
                ToolTip("Data -> Epoch: " result)
            }
            SetTimer(() => ToolTip(), -2000)
        } catch {
            ToolTip("Erro ao converter para epoch")
            SetTimer(() => ToolTip(), -2000)
        }
    }

    static FromEpoch() {
        content := Trim(A_Clipboard)
        
        tempOut := A_Temp "\lazywindow_ts_out.txt"

        try {
            ; If empty, use current time
            if (content = "") {
                ps := 'powershell -NoProfile -ExecutionPolicy Bypass -Command "'
                    . "$d = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'; "
                    . "$d | Out-File -Encoding UTF8 '" tempOut "'"
                    . '"'
            } else {
                ; Detect if milliseconds (13 digits) or seconds (10 digits)
                ps := 'powershell -NoProfile -ExecutionPolicy Bypass -Command "'
                    . "$e = " content "; "
                    . "if ($e.ToString().Length -ge 13) { "
                    . "  $d = [DateTimeOffset]::FromUnixTimeMilliseconds($e).LocalDateTime; "
                    . "} else { "
                    . "  $d = [DateTimeOffset]::FromUnixTimeSeconds($e).LocalDateTime; "
                    . "}; "
                    . "$d.ToString('yyyy-MM-ddTHH:mm:ss') | Out-File -Encoding UTF8 '" tempOut "'"
                    . '"'
            }

            rc := RunWait(ps, , "Hide")
            if (rc != 0) {
                this.Cleanup(tempOut)
                ToolTip("Erro: epoch invalido")
                SetTimer(() => ToolTip(), -2000)
                return
            }

            result := Trim(FileRead(tempOut, "UTF-8"))
            this.Cleanup(tempOut)

            A_Clipboard := result
            if (content = "") {
                ToolTip("Data atual: " result)
            } else {
                ToolTip("Epoch -> Data: " result)
            }
            SetTimer(() => ToolTip(), -2000)
        } catch {
            ToolTip("Erro ao converter epoch")
            SetTimer(() => ToolTip(), -2000)
        }
    }

    static Cleanup(files*) {
        for f in files {
            try FileDelete(f)
        }
    }
}
