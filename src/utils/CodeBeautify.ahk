#Requires AutoHotkey v2.0

class CodeBeautify {
    static Beautify() {
        content := A_Clipboard
        if (content = "") {
            ToolTip("Clipboard vazio")
            SetTimer(() => ToolTip(), -1500)
            return
        }

        ; Try to detect and format
        result := ""
        formatType := ""

        ; Try JSON first
        result := this.TryFormatJSON(content)
        if (result != "") {
            formatType := "JSON"
        } else {
            ; Try XML
            result := this.TryFormatXML(content)
            if (result != "") {
                formatType := "XML"
            } else {
                ; Try YAML
                result := this.TryFormatYAML(content)
                if (result != "") {
                    formatType := "YAML"
                }
            }
        }

        if (result = "") {
            ToolTip("Formato nao reconhecido (JSON/XML/YAML)")
            SetTimer(() => ToolTip(), -2000)
            return
        }

        A_Clipboard := result
        ToolTip("Beautify " formatType " concluido!`nCopiado para clipboard")
        SetTimer(() => ToolTip(), -2000)
    }

    static TryFormatJSON(content) {
        ; Use PowerShell to format JSON
        content := Trim(content)
        if (!RegExMatch(content, "^[\[\{]"))
            return ""

        tempIn := A_Temp "\lazywindow_json_in.txt"
        tempOut := A_Temp "\lazywindow_json_out.txt"

        try {
            file := FileOpen(tempIn, "w", "UTF-8")
            file.Write(content)
            file.Close()

            ps := 'powershell -NoProfile -ExecutionPolicy Bypass -Command "'
                . "$c = Get-Content -Raw -Encoding UTF8 '" tempIn "'; "
                . "try { $j = $c | ConvertFrom-Json; $j | ConvertTo-Json -Depth 100 | Out-File -Encoding UTF8 '" tempOut "' } "
                . 'catch { exit 1 }"'

            rc := RunWait(ps, , "Hide")
            if (rc != 0) {
                this.Cleanup(tempIn, tempOut)
                return ""
            }

            result := FileRead(tempOut, "UTF-8")
            this.Cleanup(tempIn, tempOut)
            return Trim(result)
        } catch {
            this.Cleanup(tempIn, tempOut)
            return ""
        }
    }

    static TryFormatXML(content) {
        ; Use PowerShell to format XML
        content := Trim(content)
        if (!RegExMatch(content, "^<"))
            return ""

        tempIn := A_Temp "\lazywindow_xml_in.txt"
        tempOut := A_Temp "\lazywindow_xml_out.txt"

        try {
            file := FileOpen(tempIn, "w", "UTF-8")
            file.Write(content)
            file.Close()

            ps := 'powershell -NoProfile -ExecutionPolicy Bypass -Command "'
                . "$c = Get-Content -Raw -Encoding UTF8 '" tempIn "'; "
                . "try { "
                . "[xml]$x = $c; "
                . "$sw = New-Object System.IO.StringWriter; "
                . "$xw = New-Object System.Xml.XmlTextWriter($sw); "
                . "$xw.Formatting = 'Indented'; "
                . "$xw.Indentation = 2; "
                . "$x.WriteContentTo($xw); "
                . "$xw.Flush(); "
                . "$sw.ToString() | Out-File -Encoding UTF8 '" tempOut "' "
                . '} catch { exit 1 }"'

            rc := RunWait(ps, , "Hide")
            if (rc != 0) {
                this.Cleanup(tempIn, tempOut)
                return ""
            }

            result := FileRead(tempOut, "UTF-8")
            this.Cleanup(tempIn, tempOut)
            return Trim(result)
        } catch {
            this.Cleanup(tempIn, tempOut)
            return ""
        }
    }

    static Cleanup(files*) {
        for f in files {
            try FileDelete(f)
        }
    }

    static TryFormatYAML(content) {
        ; Simple YAML re-indentation (normalize indentation to 2 spaces)
        content := Trim(content)
        
        ; Check if it looks like YAML (has key: value patterns or starts with ---)
        if (!RegExMatch(content, "(^---|\n---)|(\w+\s*:)"))
            return ""

        tempIn := A_Temp "\lazywindow_yaml_in.txt"
        tempOut := A_Temp "\lazywindow_yaml_out.txt"

        try {
            file := FileOpen(tempIn, "w", "UTF-8")
            file.Write(content)
            file.Close()

            ; PowerShell script to re-indent YAML
            ps := 'powershell -NoProfile -ExecutionPolicy Bypass -Command "'
                . "$lines = Get-Content -Encoding UTF8 '" tempIn "'; "
                . "$result = @(); "
                . "foreach ($line in $lines) { "
                . "  if ($line -match '^(\s*)(.*)$') { "
                . "    $spaces = $Matches[1].Length; "
                . "    $text = $Matches[2]; "
                . "    $indent = [math]::Floor($spaces / 2) * 2; "
                . "    $result += (' ' * $indent) + $text; "
                . "  } else { $result += $line } "
                . "}; "
                . "$result | Out-File -Encoding UTF8 '" tempOut "'"
                . '"'

            rc := RunWait(ps, , "Hide")
            if (rc != 0) {
                this.Cleanup(tempIn, tempOut)
                return ""
            }

            result := FileRead(tempOut, "UTF-8")
            this.Cleanup(tempIn, tempOut)
            return Trim(result)
        } catch {
            this.Cleanup(tempIn, tempOut)
            return ""
        }
    }
}
