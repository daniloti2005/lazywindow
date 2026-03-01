#Requires AutoHotkey v2.0

class Base64 {
    static Encode() {
        content := A_Clipboard
        if (content = "") {
            ToolTip("Clipboard vazio")
            SetTimer(() => ToolTip(), -1500)
            return
        }

        tempIn := A_Temp "\lazywindow_b64_in.txt"
        tempOut := A_Temp "\lazywindow_b64_out.txt"

        try {
            file := FileOpen(tempIn, "w", "UTF-8")
            file.Write(content)
            file.Close()

            ps := 'powershell -NoProfile -ExecutionPolicy Bypass -Command "'
                . "$c = Get-Content -Raw -Encoding UTF8 '" tempIn "'; "
                . "$b = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($c)); "
                . "$b | Out-File -Encoding ASCII '" tempOut "'"
                . '"'

            rc := RunWait(ps, , "Hide")
            if (rc != 0) {
                this.Cleanup(tempIn, tempOut)
                ToolTip("Erro ao codificar Base64")
                SetTimer(() => ToolTip(), -2000)
                return
            }

            result := Trim(FileRead(tempOut, "UTF-8"))
            this.Cleanup(tempIn, tempOut)

            A_Clipboard := result
            ToolTip("Base64 Encode OK")
            SetTimer(() => ToolTip(), -1500)
        } catch {
            this.Cleanup(tempIn, tempOut)
            ToolTip("Erro ao codificar Base64")
            SetTimer(() => ToolTip(), -2000)
        }
    }

    static Decode() {
        content := Trim(A_Clipboard)
        if (content = "") {
            ToolTip("Clipboard vazio")
            SetTimer(() => ToolTip(), -1500)
            return
        }

        tempIn := A_Temp "\lazywindow_b64_in.txt"
        tempOut := A_Temp "\lazywindow_b64_out.txt"

        try {
            file := FileOpen(tempIn, "w", "UTF-8")
            file.Write(content)
            file.Close()

            ps := 'powershell -NoProfile -ExecutionPolicy Bypass -Command "'
                . "$c = Get-Content -Raw -Encoding UTF8 '" tempIn "'; "
                . "$c = $c.Trim(); "
                . "try { $d = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($c)); "
                . "$d | Out-File -Encoding UTF8 '" tempOut "' } "
                . 'catch { exit 1 }"'

            rc := RunWait(ps, , "Hide")
            if (rc != 0) {
                this.Cleanup(tempIn, tempOut)
                ToolTip("Erro ao decodificar Base64")
                SetTimer(() => ToolTip(), -2000)
                return
            }

            result := FileRead(tempOut, "UTF-8")
            this.Cleanup(tempIn, tempOut)

            A_Clipboard := Trim(result)
            ToolTip("Base64 Decode OK")
            SetTimer(() => ToolTip(), -1500)
        } catch {
            this.Cleanup(tempIn, tempOut)
            ToolTip("Erro ao decodificar Base64")
            SetTimer(() => ToolTip(), -2000)
        }
    }

    static Cleanup(files*) {
        for f in files {
            try FileDelete(f)
        }
    }
}
