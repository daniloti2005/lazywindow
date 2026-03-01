#Requires AutoHotkey v2.0

#Include "SnippetStore.ahk"
#Include "ContextDetector.ahk"

class SnippetManager {
    static gui := ""
    static visible := false
    static searchEdit := ""
    static categoryList := ""
    static snippetList := ""
    static previewEdit := ""
    static languageDropdown := ""
    static searchModeText := ""
    static currentLanguage := "typescript"
    static currentCategory := ""
    static currentSnippets := []
    static capturedWord := ""
    static selectedSnippet := ""
    static searchMode := "name"  ; "name" ou "content"
    
    static Show() {
        if (this.visible) {
            this.Hide()
            return
        }
        
        ; Detect context before showing GUI
        this.currentLanguage := ContextDetector.DetectLanguage()
        this.capturedWord := ContextDetector.GetSelectedText()
        
        ; Create or show GUI
        if (!this.gui) {
            this.CreateGui()
        }
        
        ; Update language dropdown
        this.languageDropdown.Choose(this.GetLanguageIndex(this.currentLanguage))
        
        ; Load snippets for detected language
        this.LoadSnippetsForLanguage()
        
        ; Show GUI
        this.gui.Show()
        this.visible := true
        this.searchEdit.Focus()
    }
    
    static Hide() {
        if (this.gui) {
            this.gui.Hide()
        }
        this.visible := false
    }
    
    static CreateGui() {
        this.gui := Gui("+AlwaysOnTop -MinimizeBox", "Snippet Manager")
        this.gui.SetFont("s10", "Segoe UI")
        this.gui.BackColor := "1e1e1e"
        
        ; Search box with mode toggle
        this.gui.SetFont("s10 cWhite", "Segoe UI")
        this.gui.AddText("x10 y10 w80 h25", "Search:")
        this.searchEdit := this.gui.AddEdit("x90 y7 w250 h25 Background2d2d2d cWhite")
        this.searchEdit.OnEvent("Change", (*) => this.OnSearchChange())
        
        ; Search mode toggle button
        this.searchModeBtn := this.gui.AddButton("x345 y6 w55 h26", "Nome")
        this.searchModeBtn.OnEvent("Click", (*) => this.ToggleSearchMode())
        
        ; Language dropdown
        this.gui.AddText("x410 y10 w60 h25", "Lang:")
        languages := ["TypeScript", "Python", "SQL", "PowerShell", "Bash", "Go", "Windows"]
        this.languageDropdown := this.gui.AddDropDownList("x470 y7 w110 Choose1 Background2d2d2d", languages)
        this.languageDropdown.OnEvent("Change", (*) => this.OnLanguageChange())
        
        ; Search mode indicator
        this.gui.AddText("x10 y40 w80 h20", "Modo:")
        this.searchModeText := this.gui.AddText("x90 y40 w150 h20 c00ff00", "Busca por NOME")
        
        ; Context word display
        this.gui.AddText("x250 y40 w60 h20", "Context:")
        this.contextText := this.gui.AddText("x310 y40 w270 h20 c808080", "")
        
        ; Category list
        this.gui.AddText("x10 y65 w150 h20", "Categories:")
        this.categoryList := this.gui.AddListBox("x10 y85 w150 h200 Background2d2d2d cWhite")
        this.categoryList.OnEvent("Change", (*) => this.OnCategoryChange())
        
        ; Snippet list
        this.gui.AddText("x170 y65 w150 h20", "Snippets:")
        this.snippetList := this.gui.AddListBox("x170 y85 w200 h200 Background2d2d2d cWhite")
        this.snippetList.OnEvent("Change", (*) => this.OnSnippetChange())
        this.snippetList.OnEvent("DoubleClick", (*) => this.InsertSnippet())
        
        ; Preview
        this.gui.AddText("x380 y65 w200 h20", "Preview:")
        this.previewEdit := this.gui.AddEdit("x380 y85 w200 h200 ReadOnly Multi Background2d2d2d cWhite -WantReturn")
        
        ; Buttons
        this.gui.SetFont("s9", "Segoe UI")
        insertBtn := this.gui.AddButton("x10 y295 w120 h30", "Insert (Enter)")
        insertBtn.OnEvent("Click", (*) => this.InsertSnippet())
        
        cancelBtn := this.gui.AddButton("x140 y295 w80 h30", "Cancel")
        cancelBtn.OnEvent("Click", (*) => this.Hide())
        
        toggleModeBtn := this.gui.AddButton("x230 y295 w140 h30", "Tab = Modo Busca")
        toggleModeBtn.OnEvent("Click", (*) => this.ToggleSearchMode())
        
        ; Keyboard shortcuts
        this.gui.OnEvent("Escape", (*) => this.Hide())
        
        ; Position center screen
        this.gui.Show("w590 h335 Hide")
    }
    
    static GetLanguageIndex(lang) {
        languages := ["typescript", "python", "sql", "powershell", "bash", "go", "windows"]
        for i, l in languages {
            if (StrLower(lang) = l) {
                return i
            }
        }
        return 1
    }
    
    static GetLanguageFromIndex(index) {
        languages := ["typescript", "python", "sql", "powershell", "bash", "go", "windows"]
        if (index > 0 && index <= languages.Length) {
            return languages[index]
        }
        return "typescript"
    }
    
    static OnLanguageChange() {
        this.currentLanguage := this.GetLanguageFromIndex(this.languageDropdown.Value)
        this.LoadSnippetsForLanguage()
    }
    
    static LoadSnippetsForLanguage() {
        ; Update context display
        if (this.capturedWord != "") {
            this.contextText.Value := "Word: " . this.capturedWord
        } else {
            this.contextText.Value := "(no word captured - select text before opening)"
        }
        
        ; Get categories
        categories := this.GetCategoriesForLanguage(this.currentLanguage)
        
        ; Update category list
        this.categoryList.Delete()
        this.categoryList.Add(["All"])
        for cat in categories {
            this.categoryList.Add([cat])
        }
        this.categoryList.Choose(1)
        this.currentCategory := ""
        
        ; Load all snippets for this language
        this.currentSnippets := SnippetStore.GetByLanguage(this.currentLanguage)
        this.UpdateSnippetList()
    }
    
    static GetCategoriesForLanguage(lang) {
        snippets := SnippetStore.GetByLanguage(lang)
        categories := Map()
        for snippet in snippets {
            if (!categories.Has(snippet.category)) {
                categories[snippet.category] := true
            }
        }
        result := []
        for cat, _ in categories {
            result.Push(cat)
        }
        return result
    }
    
    static OnCategoryChange() {
        if (this.categoryList.Value = 0) {
            return
        }
        
        selected := this.categoryList.Text
        if (selected = "All") {
            this.currentCategory := ""
        } else {
            this.currentCategory := selected
        }
        this.UpdateSnippetList()
    }
    
    static OnSearchChange() {
        this.UpdateSnippetList()
    }
    
    static ToggleSearchMode() {
        if (this.searchMode = "name") {
            this.searchMode := "content"
            this.searchModeBtn.Text := "Código"
            this.searchModeText.Value := "Busca por CÓDIGO"
        } else {
            this.searchMode := "name"
            this.searchModeBtn.Text := "Nome"
            this.searchModeText.Value := "Busca por NOME"
        }
        this.UpdateSnippetList()
    }
    
    static UpdateSnippetList() {
        searchQuery := this.searchEdit.Value
        
        ; Filter snippets
        filtered := []
        allSnippets := SnippetStore.GetByLanguage(this.currentLanguage)
        
        for snippet in allSnippets {
            ; Category filter
            if (this.currentCategory != "" && snippet.category != this.currentCategory) {
                continue
            }
            
            ; Search filter based on mode
            if (searchQuery != "") {
                queryLower := StrLower(searchQuery)
                
                if (this.searchMode = "name") {
                    ; Search by name and description
                    if (!InStr(StrLower(snippet.name), queryLower) && 
                        !InStr(StrLower(snippet.description), queryLower)) {
                        continue
                    }
                } else {
                    ; Search by code content
                    found := false
                    if (snippet.code.Has(this.currentLanguage)) {
                        codeContent := snippet.code[this.currentLanguage]
                        if (InStr(StrLower(codeContent), queryLower)) {
                            found := true
                        }
                    }
                    ; Also search in all language codes
                    if (!found) {
                        for lang, code in snippet.code {
                            if (InStr(StrLower(code), queryLower)) {
                                found := true
                                break
                            }
                        }
                    }
                    if (!found) {
                        continue
                    }
                }
            }
            
            filtered.Push(snippet)
        }
        
        this.currentSnippets := filtered
        
        ; Update list
        this.snippetList.Delete()
        for snippet in filtered {
            this.snippetList.Add([snippet.name])
        }
        
        ; Select first if available
        if (filtered.Length > 0) {
            this.snippetList.Choose(1)
            this.OnSnippetChange()
        } else {
            this.previewEdit.Value := ""
            this.selectedSnippet := ""
        }
    }
    
    static OnSnippetChange() {
        if (this.snippetList.Value = 0 || this.snippetList.Value > this.currentSnippets.Length) {
            return
        }
        
        this.selectedSnippet := this.currentSnippets[this.snippetList.Value]
        
        ; Get code for current language
        code := ""
        if (this.selectedSnippet.code.Has(this.currentLanguage)) {
            code := this.selectedSnippet.code[this.currentLanguage]
        } else {
            ; Try to find any available language
            for lang, c in this.selectedSnippet.code {
                code := c
                break
            }
        }
        
        ; If searching in content mode for Windows commands, extract matching line
        searchQuery := this.searchEdit.Value
        if (this.searchMode = "content" && searchQuery != "" && this.currentLanguage = "windows") {
            code := this.ExtractMatchingCommand(code, searchQuery)
        }
        
        ; Show preview with placeholder replacement preview
        preview := this.ReplaceePlaceholders(code)
        this.previewEdit.Value := preview
    }
    
    static ExtractMatchingCommand(code, query) {
        queryLower := StrLower(query)
        lines := StrSplit(code, "`n")
        matchedLines := []
        
        for line in lines {
            ; Skip comment-only lines and empty lines
            trimmedLine := Trim(line)
            if (trimmedLine = "" || SubStr(trimmedLine, 1, 1) = "#") {
                continue
            }
            
            ; Check if line contains the query
            if (InStr(StrLower(line), queryLower)) {
                ; Extract just the command (before the # comment)
                if (InStr(line, "#")) {
                    parts := StrSplit(line, "#", , 2)
                    command := Trim(parts[1])
                    if (command != "") {
                        matchedLines.Push(command)
                    }
                } else {
                    matchedLines.Push(Trim(line))
                }
            }
        }
        
        if (matchedLines.Length > 0) {
            ; Return all matching commands, one per line
            result := ""
            for cmd in matchedLines {
                result .= cmd . "`n"
            }
            return RTrim(result, "`n")
        }
        
        ; If no specific match, return original
        return code
    }
    
    static ReplaceePlaceholders(code) {
        result := code
        
        ; Replace common placeholders
        if (this.capturedWord != "") {
            ; Replace various placeholder formats
            result := StrReplace(result, "${ClassName}", this.capturedWord)
            result := StrReplace(result, "${InterfaceName}", this.capturedWord)
            result := StrReplace(result, "${FunctionName}", this.capturedWord)
            result := StrReplace(result, "${StructName}", this.capturedWord)
            result := StrReplace(result, "${ProductName}", this.capturedWord)
            result := StrReplace(result, "${SubjectName}", this.capturedWord)
            result := StrReplace(result, "${HandlerName}", this.capturedWord)
            result := StrReplace(result, "${ManagerName}", this.capturedWord)
            result := StrReplace(result, "${stateName}", StrLower(this.capturedWord))
            result := StrReplace(result, "${StateName}", this.capturedWord)
            result := StrReplace(result, "${cteName}", StrLower(this.capturedWord))
            result := StrReplace(result, "${functionName}", this.ToCamelCase(this.capturedWord))
            result := StrReplace(result, "${table1}", StrLower(this.capturedWord))
            result := StrReplace(result, "${table2}", StrLower(this.capturedWord) . "s")
            result := StrReplace(result, "${items}", StrLower(this.capturedWord))
            result := StrReplace(result, "${url}", "https://api.example.com/" . StrLower(this.capturedWord))
            result := StrReplace(result, "${condition}", "-n `"$" . this.capturedWord . "`"")
            result := StrReplace(result, "${bucket}", StrLower(this.capturedWord) . "-bucket")
            result := StrReplace(result, "${region}", "us-east-1")
        }
        
        ; Replace date placeholder
        result := StrReplace(result, "${date}", FormatTime(, "yyyy-MM-dd"))
        
        ; Replace user placeholder
        result := StrReplace(result, "${user}", A_UserName)
        
        return result
    }
    
    static ToCamelCase(str) {
        if (StrLen(str) = 0) {
            return str
        }
        return StrLower(SubStr(str, 1, 1)) . SubStr(str, 2)
    }
    
    static InsertSnippet() {
        if (!this.selectedSnippet) {
            return
        }
        
        ; Get code for current language
        code := ""
        if (this.selectedSnippet.code.Has(this.currentLanguage)) {
            code := this.selectedSnippet.code[this.currentLanguage]
        } else {
            for lang, c in this.selectedSnippet.code {
                code := c
                break
            }
        }
        
        ; Replace placeholders
        finalCode := this.ReplaceePlaceholders(code)
        
        ; Hide GUI
        this.Hide()
        
        ; Small delay
        Sleep(50)
        
        ; Copy to clipboard and paste
        savedClipboard := A_Clipboard
        A_Clipboard := finalCode
        ClipWait(1)
        
        Send("^v")
        
        ; Restore clipboard after delay
        SetTimer(() => (A_Clipboard := savedClipboard), -500)
    }
    
    static Toggle() {
        if (this.visible) {
            this.Hide()
        } else {
            this.Show()
        }
    }
}
