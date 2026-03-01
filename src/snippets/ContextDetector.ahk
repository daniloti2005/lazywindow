#Requires AutoHotkey v2.0

class ContextDetector {
    ; Detect language based on active window title/process
    static DetectLanguage() {
        try {
            title := WinGetTitle("A")
            processName := WinGetProcessName("A")
        } catch {
            return "typescript"  ; Default
        }
        
        titleLower := StrLower(title)
        processLower := StrLower(processName)
        
        ; Check for terminals/shells
        if (InStr(processLower, "powershell") || InStr(titleLower, "powershell") || InStr(titleLower, "pwsh")) {
            return "powershell"
        }
        if (InStr(processLower, "bash") || InStr(titleLower, "bash") || InStr(titleLower, "wsl") || InStr(processLower, "wsl")) {
            return "bash"
        }
        if (InStr(processLower, "cmd.exe") || InStr(titleLower, "command prompt")) {
            return "bash"  ; Use bash snippets for cmd too
        }
        if (InStr(processLower, "windowsterminal") || InStr(processLower, "terminal")) {
            ; Windows Terminal - check title for hints
            if (InStr(titleLower, "powershell") || InStr(titleLower, "pwsh")) {
                return "powershell"
            }
            if (InStr(titleLower, "bash") || InStr(titleLower, "ubuntu") || InStr(titleLower, "wsl")) {
                return "bash"
            }
            return "powershell"  ; Default for Windows Terminal
        }
        
        ; Check file extension in title
        if (RegExMatch(titleLower, "\.(ts|tsx)\b")) {
            return "typescript"
        }
        if (RegExMatch(titleLower, "\.py\b")) {
            return "python"
        }
        if (RegExMatch(titleLower, "\.go\b")) {
            return "go"
        }
        if (RegExMatch(titleLower, "\.sql\b")) {
            return "sql"
        }
        if (RegExMatch(titleLower, "\.(ps1|psm1)\b")) {
            return "powershell"
        }
        if (RegExMatch(titleLower, "\.(sh|bash)\b")) {
            return "bash"
        }
        if (RegExMatch(titleLower, "\.(js|jsx)\b")) {
            return "typescript"  ; Use TS snippets for JS
        }
        
        ; Check for known editors/IDEs
        if (InStr(processLower, "code") || InStr(titleLower, "visual studio code")) {
            ; VS Code - try to detect from title
            if (RegExMatch(titleLower, "\.(ts|tsx|js|jsx)\b")) {
                return "typescript"
            }
            if (InStr(titleLower, ".py")) {
                return "python"
            }
            if (InStr(titleLower, ".go")) {
                return "go"
            }
            return "typescript"  ; Default for VS Code
        }
        
        if (InStr(processLower, "nvim") || InStr(processLower, "vim") || InStr(titleLower, "neovim")) {
            ; Vim/Neovim - check title
            if (RegExMatch(titleLower, "\.(ts|tsx|js|jsx)\b")) {
                return "typescript"
            }
            if (InStr(titleLower, ".py")) {
                return "python"
            }
            if (InStr(titleLower, ".go")) {
                return "go"
            }
            return "typescript"
        }
        
        ; SQL tools
        if (InStr(processLower, "ssms") || InStr(processLower, "azuredatastudio") || 
            InStr(titleLower, "sql server") || InStr(titleLower, "azure data studio") ||
            InStr(processLower, "dbeaver") || InStr(titleLower, "dbeaver")) {
            return "sql"
        }
        
        ; Python-specific editors
        if (InStr(processLower, "pycharm") || InStr(titleLower, "pycharm") ||
            InStr(processLower, "jupyter") || InStr(titleLower, "jupyter")) {
            return "python"
        }
        
        ; Go-specific
        if (InStr(processLower, "goland") || InStr(titleLower, "goland")) {
            return "go"
        }
        
        return "typescript"  ; Default fallback
    }
    
    ; Get word under cursor using clipboard trick
    static GetWordUnderCursor() {
        ; Save current clipboard
        savedClipboard := A_Clipboard
        A_Clipboard := ""
        
        ; Try to select word and copy
        try {
            ; Select word (Ctrl+Shift+Left, then Ctrl+Shift+Right to get full word)
            Send("^+{Left}")
            Sleep(30)
            Send("^+{Right}")
            Sleep(30)
            
            ; If that selects too much, try double-click selection
            ; Send ^c to copy
            Send("^c")
            
            ; Wait for clipboard
            if (!ClipWait(0.3)) {
                ; Try alternative: select word with Ctrl+D (VS Code) or similar
                A_Clipboard := savedClipboard
                return ""
            }
            
            word := Trim(A_Clipboard)
            
            ; Restore cursor position
            Send("{Right}")
        } catch {
            A_Clipboard := savedClipboard
            return ""
        }
        
        ; Restore clipboard
        A_Clipboard := savedClipboard
        
        ; Validate - should be a valid identifier
        if (RegExMatch(word, "^[a-zA-Z_][a-zA-Z0-9_]*$")) {
            return word
        }
        
        return ""
    }
    
    ; Get word under cursor using alternative method (select current word)
    static GetWordUnderCursorAlt() {
        ; Save current clipboard
        savedClipboard := A_Clipboard
        A_Clipboard := ""
        
        try {
            ; Double-click to select word (some editors)
            ; Or use Ctrl+W in some editors
            Send("{Home}+{End}")  ; Select line as fallback
            Sleep(50)
            Send("^c")
            
            if (!ClipWait(0.3)) {
                A_Clipboard := savedClipboard
                return ""
            }
            
            line := A_Clipboard
            A_Clipboard := savedClipboard
            
            ; Try to extract a reasonable word from the line
            ; Look for class/function names
            if (RegExMatch(line, "class\s+(\w+)", &match)) {
                return match[1]
            }
            if (RegExMatch(line, "function\s+(\w+)", &match)) {
                return match[1]
            }
            if (RegExMatch(line, "def\s+(\w+)", &match)) {
                return match[1]
            }
            if (RegExMatch(line, "type\s+(\w+)", &match)) {
                return match[1]
            }
            
            ; Find first capitalized word (likely class name)
            if (RegExMatch(line, "\b([A-Z][a-zA-Z0-9]+)", &match)) {
                return match[1]
            }
            
            return ""
        } catch {
            A_Clipboard := savedClipboard
            return ""
        }
    }
    
    ; Simple word capture - just get selected text if any
    static GetSelectedText() {
        savedClipboard := A_Clipboard
        A_Clipboard := ""
        
        try {
            Send("^c")
            if (ClipWait(0.2)) {
                text := Trim(A_Clipboard)
                A_Clipboard := savedClipboard
                if (RegExMatch(text, "^[a-zA-Z_][a-zA-Z0-9_]*$")) {
                    return text
                }
            }
        } catch {
        }
        
        A_Clipboard := savedClipboard
        return ""
    }
}
