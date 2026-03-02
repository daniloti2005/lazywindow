#Requires AutoHotkey v2.0

class PromptManager {
    static gui := ""
    static listView := ""
    static inputBox := ""
    static shellFilter := ""
    static footerText := ""
    static isVisible := false
    static prompts := []
    static filtered := []
    static wasArrowMouseOn := false
    static configDir := ""
    static configPath := ""
    static defaults := Map()

    static Init() {
        this.configDir := EnvGet("USERPROFILE") "\.lazywindow"
        this.configPath := this.configDir "\prompts.json"
        if (!DirExist(this.configDir))
            DirCreate(this.configDir)
        this.Load()
        this.MergeBuiltIns()
    }

    ; Ensure all built-in prompts are present in memory (never lost after file reload)
    static MergeBuiltIns() {
        builtinIds := ["minimal-ps", "git-branch-ps", "timestamp-ps", "minimal-bash", "git-color-bash", "starwars-bash", "starwars-ps", "powerline-ps", "powerline-bash", "dragonball-bash", "dragonball-ps"]
        existingIds := []
        for p in this.prompts
            existingIds.Push(p.id)

        ; Save custom prompts before rebuilding
        customs := []
        for p in this.prompts
            if (!p.builtin)
                customs.Push(p)

        ; Check if any builtin is missing
        needMerge := false
        for bid in builtinIds {
            found := false
            for eid in existingIds {
                if (eid = bid) {
                    found := true
                    break
                }
            }
            if (!found) {
                needMerge := true
                break
            }
        }
        if (!needMerge)
            return

        ; Rebuild: load fresh built-ins then re-add customs
        this.prompts := []
        this.LoadBuiltIns()
        for p in customs
            this.prompts.Push(p)
    }

    ; ── Built-in Prompts ──

    static LoadBuiltIns() {
        now := FormatTime(, "yyyy-MM-ddTHH:mm:ss")

        ; PowerShell prompts
        minimalCode := 'function prompt { "$($executionContext.SessionState.Path.CurrentLocation)> " }'
        this.prompts.Push({
            id: "minimal-ps",
            name: "Minimal",
            shellType: "powershell",
            code: minimalCode,
            builtin: true,
            favorite: false,
            lastUsed: ""
        })

        gitBranchCode := 'function prompt { $loc = $executionContext.SessionState.Path.CurrentLocation; $b = ""; try { $b = (git branch --show-current 2>$null) } catch {}'
        gitBranchCode .= "; if ($b) { " Chr(34) "$loc ``e[32m($b)``e[0m> " Chr(34) " } else { " Chr(34) "$loc> " Chr(34) " } }"
        this.prompts.Push({
            id: "git-branch-ps",
            name: "Git Branch",
            shellType: "powershell",
            code: gitBranchCode,
            builtin: true,
            favorite: false,
            lastUsed: ""
        })

        timestampCode := "function prompt { " Chr(34) "[$(Get-Date -Format 'HH:mm:ss')] $($executionContext.SessionState.Path.CurrentLocation)> " Chr(34) " }"
        this.prompts.Push({
            id: "timestamp-ps",
            name: "Timestamp",
            shellType: "powershell",
            code: timestampCode,
            builtin: true,
            favorite: false,
            lastUsed: ""
        })

        ; Bash prompts
        minimalBash := "export PS1='\[\033[01;34m\]\w\[\033[00m\]\$ '"
        this.prompts.Push({
            id: "minimal-bash",
            name: "Minimal Color",
            shellType: "bash",
            code: minimalBash,
            builtin: true,
            favorite: false,
            lastUsed: ""
        })

        gitColorBash := "export PS1='\[\033[01;34m\]\w\[\033[00;32m\]$(git branch --show-current 2>/dev/null | sed " Chr(34) "s/^/ (/;s/$/)/" Chr(34) ")\[\033[00m\]\$ '"
        this.prompts.Push({
            id: "git-color-bash",
            name: "Git Color",
            shellType: "bash",
            code: gitColorBash,
            builtin: true,
            favorite: false,
            lastUsed: ""
        })

        ; ── Star Wars (Bash) — auto-detect: Jedi (user) ↔ Sith (root) + animation ──
        ; set +H disables history expansion to avoid ! issues in $'...' strings
        swBash := "set +H; prompt_starwars() { if [ $EUID -eq 0 ]; then "
        ; One-shot animation: Anakin → Darth Vader (6 full-screen frames)
        swBash .= "if [ -z " Chr(34) "$_SW_ANIMATED" Chr(34) " ]; then export _SW_ANIMATED=1; "
        ; Frame 1: Young Anakin — Hooded Jedi with blue lightsaber
        swBash .= "clear; echo -e '\n\033[1;34m"
        swBash .= "              .        .     *        .    *     .        .\n"
        swBash .= "      *    .       .        .    .        .       *    .     \n"
        swBash .= "                     \033[1;36m     |          \033[1;34m                         \n"
        swBash .= "                     \033[1;36m     |          \033[1;34m            *             \n"
        swBash .= "                     \033[1;36m     |          \033[1;34m                          \n"
        swBash .= "                     \033[1;36m     |          \033[1;34m                          \n"
        swBash .= "                     \033[1;33m   __|__        \033[1;34m                          \n"
        swBash .= "                     \033[1;33m  / o o \\       \033[1;34m                          \n"
        swBash .= "                     \033[1;33m |  ---  |      \033[1;34m                          \n"
        swBash .= "                     \033[1;33m  \\_____/       \033[1;34m                          \n"
        swBash .= "                  \033[0;33m  __|     |__     \033[1;34m                          \n"
        swBash .= "                  \033[0;33m /   |   |   \\    \033[1;34m                          \n"
        swBash .= "                  \033[0;33m/    |   |    \\   \033[1;34m                          \n"
        swBash .= "                  \033[0;33m     |   |        \033[1;34m                          \n"
        swBash .= "                  \033[0;33m    / \\ / \\       \033[1;34m                          \n"
        swBash .= "                  \033[0;33m   /   V   \\      \033[1;34m                          \n"
        swBash .= "\n"
        swBash .= "        \033[1;36m⭐  A N A K I N   S K Y W A L K E R  ⭐\033[0m\n"
        swBash .= "        \033[0;36m     The Chosen One has arrived...\033[0m\n"
        swBash .= "        \033[0;34m   A long time ago in a galaxy far, far away...\033[0m\n"
        swBash .= "\033[0m'; sleep 2.5; "
        ; Frame 2: Conflict — Between light and dark
        swBash .= "clear; echo -e '\n\033[0m"
        swBash .= "  \033[1;34m ░░░░░░░░░░░░░░\033[0m          ║          \033[1;31m░░░░░░░░░░░░░░\033[0m\n"
        swBash .= "  \033[1;34m ░░ LIGHT  ░░░░\033[0m          ║          \033[1;31m░░░░  DARK ░░░\033[0m\n"
        swBash .= "  \033[1;34m ░░  SIDE  ░░░░\033[0m          ║          \033[1;31m░░░░  SIDE ░░░\033[0m\n"
        swBash .= "  \033[1;34m ░░░░░░░░░░░░░░\033[0m          ║          \033[1;31m░░░░░░░░░░░░░░\033[0m\n"
        swBash .= "  \033[1;36m     |  |       \033[0m          ║          \033[1;31m       |  |\033[0m\n"
        swBash .= "  \033[1;36m     |  |       \033[0m        \033[1;33m__|__\033[0m        \033[1;31m       |  |\033[0m\n"
        swBash .= "  \033[1;36m     |  |       \033[0m       \033[1;33m/ o o \\\033[0m       \033[1;31m       |  |\033[0m\n"
        swBash .= "  \033[1;36m     |  |       \033[0m      \033[1;33m|  ---  |\033[0m      \033[1;31m       |  |\033[0m\n"
        swBash .= "  \033[1;36m     |  |       \033[0m       \033[1;33m\\_____/\033[0m       \033[1;31m       |  |\033[0m\n"
        swBash .= "  \033[1;36m     |  |       \033[0m      \033[1;33m__|   |__\033[0m      \033[1;31m       |  |\033[0m\n"
        swBash .= "  \033[1;36m     |  |       \033[0m     \033[1;33m/  |   |  \\\033[0m     \033[1;31m       |  |\033[0m\n"
        swBash .= "  \033[1;36m     |  |       \033[0m        \033[1;33m|   |\033[0m        \033[1;31m       |  |\033[0m\n"
        swBash .= "  \033[1;36m     |  |       \033[0m       \033[1;33m/ \\ / \\\033[0m       \033[1;31m       |  |\033[0m\n"
        swBash .= "  \033[1;36m     |  |       \033[0m      \033[1;33m/       \\\033[0m      \033[1;31m       |  |\033[0m\n"
        swBash .= "\n"
        swBash .= "     \033[1;33m⚡  I can feel it... the dark side calls to me...  ⚡\033[0m\n"
        swBash .= "     \033[0;33m        The Force is pulling me apart...\033[0m\n"
        swBash .= "\033[0m'; sleep 2.5; "
        ; Frame 3: The Fall — Burning temple, yellow eyes
        swBash .= "clear; echo -e '\n\033[1;31m"
        swBash .= "       )\\        /(          )\\       /(        )\\        /(\n"
        swBash .= "      ) \\ \\    / / (        ) \\ \\   / / (      ) \\ \\    / / (\n"
        swBash .= "     )  \\ \\  / /  (        )  \\ \\ / /  (     )  \\ \\  / /  (\n"
        swBash .= "    )   |\\ \\/ /|  (       )   |\\ V /|  (    )   |\\ \\/ /|  (\n"
        swBash .= "    )   | \\  / |  (       )   | \\ / |  (    )   | \\  / |  (\n"
        swBash .= "   )    |  \\/  |   (      )   |  V  |   (   )   |  \\/  |   (\n"
        swBash .= "   )    |      |   (      )   |     |   (   )   |      |   (\n"
        swBash .= "  )     |      |    (     )   |     |    (  )   |      |    (\033[0m\n"
        swBash .= "\n"
        swBash .= "                        \033[1;33m   ___________\033[0m\n"
        swBash .= "                        \033[1;33m  /  \033[1;33;43m O \033[0;1;33m   \033[1;33;43m O \033[0;1;33m  \\\033[0m\n"
        swBash .= "                        \033[1;33m |    \\___/    |\033[0m\n"
        swBash .= "                        \033[1;31m  \\___________/\033[0m\n"
        swBash .= "\n"
        swBash .= "  \033[1;37m ╔═══════════════════════════════════════════════════════╗\033[0m\n"
        swBash .= "  \033[1;37m ║  \033[1;36m You were supposed to destroy the Sith, not join them! \033[1;37m ║\033[0m\n"
        swBash .= "  \033[1;37m ║  \033[1;33m You were my brother, Anakin... I loved you.          \033[1;37m ║\033[0m\n"
        swBash .= "  \033[1;37m ╚═══════════════════════════════════════════════════════╝\033[0m\n"
        swBash .= "\033[0m'; sleep 3; "
        ; Frame 4: The Mask — Surgery scene, mask descending
        swBash .= "clear; echo -e '\n\033[0m"
        swBash .= "  \033[0;37m ┌─────────────────────────────────────────────────────────┐\033[0m\n"
        swBash .= "  \033[0;37m │\033[1;31m              THE SURGICAL RECONSTRUCTION               \033[0;37m│\033[0m\n"
        swBash .= "  \033[0;37m └─────────────────────────────────────────────────────────┘\033[0m\n"
        swBash .= "\n"
        swBash .= "                    \033[1;37m         ▼ ▼ ▼\033[0m\n"
        swBash .= "                    \033[0;37m    ┌───────────────┐\033[0m\n"
        swBash .= "                    \033[0;37m   ╱   ╱─────────╲   ╲\033[0m\n"
        swBash .= "                    \033[0;37m  ╱   ╱  ▄▄   ▄▄  ╲   ╲\033[0m\n"
        swBash .= "                    \033[0;37m │   │  █▀▀█ █▀▀█  │   │\033[0m\n"
        swBash .= "                    \033[0;37m │   │  ▀▄▄▀ ▀▄▄▀  │   │\033[0m\n"
        swBash .= "                    \033[0;37m │   │     ╲▄╱     │   │\033[0m\n"
        swBash .= "                    \033[0;37m  ╲   ╲  ▄▄▄▄▄▄▄ ╱   ╱\033[0m\n"
        swBash .= "                    \033[0;37m   ╲   ╲─────────╱   ╱\033[0m\n"
        swBash .= "                    \033[0;37m    └───────────────┘\033[0m\n"
        swBash .= "\n"
        swBash .= "             \033[0;37m ═══╦═══   ═══╦═══   ═══╦═══   ═══╦═══\033[0m\n"
        swBash .= "             \033[0;37m    ║          ║          ║          ║\033[0m\n"
        swBash .= "  \033[0;90m ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\033[0m\n"
        swBash .= "\n"
        swBash .= "         \033[0;31m   Anakin Skywalker is no more...\033[0m\n"
        swBash .= "         \033[0;37m   The mask descends. The transformation begins.\033[0m\n"
        swBash .= "\033[0m'; sleep 3; "
        ; Frame 5: Vader Rises — Full body with cape and red saber
        swBash .= "clear; echo -e '\n\033[1;31m"
        swBash .= "                        ┌───────────────┐\n"
        swBash .= "                       ╱   ╱─────────╲   ╲\n"
        swBash .= "                      ╱   ╱  ▄▄   ▄▄  ╲   ╲\n"
        swBash .= "                     │   │  █▀▀█ █▀▀█  │   │\n"
        swBash .= "                     │   │  ▀▄▄▀ ▀▄▄▀  │   │\n"
        swBash .= "                     │   │     ╲▄╱     │   │\n"
        swBash .= "                      ╲   ╲  ▄▄▄▄▄▄▄ ╱   ╱\n"
        swBash .= "                       ╲   ╲─────────╱   ╱\n"
        swBash .= "                        └───────┬───────┘\n"
        swBash .= "                    ┌───────────┼───────────┐\n"
        swBash .= "               ╱╲   │  ┌─┐ ┌───┼───┐ ┌─┐  │   ╱╲\n"
        swBash .= "              ╱  ╲  │  │○│ │ ◆ │ ◆ │ │○│  │  ╱  ╲\n"
        swBash .= "             ╱    ╲ │  └─┘ └───┼───┘ └─┘  │ ╱    ╲\n"
        swBash .= "            ╱      ╲│          │          │╱      ╲\n"
        swBash .= "           ╱        │         ╱ ╲         │        ╲\n"
        swBash .= "          ╱         │        ╱   ╲        │         ╲\n"
        swBash .= "         ╱          │       ╱     ╲       │          ╲\n"
        swBash .= "        ╱           └──────╱       ╲──────┘           ╲\033[0m\n"
        swBash .= "\n"
        swBash .= "   \033[1;37m KSSHHH...\033[0m  \033[1;31m━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m  \033[1;37m*lightsaber ignites*\033[0m\n"
        swBash .= "\033[0m'; sleep 3; "
        ; Frame 6: Final — Iconic close-up
        swBash .= "clear; echo -e '\n\n\033[1;31m"
        swBash .= "            ╔═══════════════════════════════════════════╗\n"
        swBash .= "           ╱         ╱───────────────────╲         ╲\n"
        swBash .= "          ╱         ╱    ╱───────────╲    ╲         ╲\n"
        swBash .= "         ╱         ╱    ╱  ▄▄▄   ▄▄▄  ╲    ╲         ╲\n"
        swBash .= "        │         │    │  █████ █████  │    │         │\n"
        swBash .= "        │         │    │  ▀▀▀▀▀ ▀▀▀▀▀  │    │         │\n"
        swBash .= "        │         │    │      ╲▄▄╱      │    │         │\n"
        swBash .= "        │         │     ╲    ▄▄▄▄▄    ╱     │         │\n"
        swBash .= "         ╲         ╲     ╲───────────╱     ╱         ╱\n"
        swBash .= "          ╲         ╲───────────────────╱         ╱\n"
        swBash .= "           ╲═══════════════════════════════════════╱\033[0m\n"
        swBash .= "\n"
        swBash .= "\033[1;37m  ╔═══════════════════════════════════════════════════════════╗\033[0m\n"
        swBash .= "\033[1;37m  ║                                                           ║\033[0m\n"
        swBash .= "\033[1;37m  ║         \033[1;31m  I  am...  D A R T H   V A D E R .  \033[1;37m            ║\033[0m\n"
        swBash .= "\033[1;37m  ║                                                           ║\033[0m\n"
        swBash .= "\033[1;37m  ╚═══════════════════════════════════════════════════════════╝\033[0m\n"
        swBash .= "\033[0m'; sleep 3.5; clear; fi; "
        ; Root = Sith prompt
        swBash .= "PS1=$'\n\033[1;31m███████ ██ ████████ ██   ██\033[0m"
        swBash .= "\n\033[1;31m██      ██    ██    ██   ██\033[0m"
        swBash .= "\n\033[1;31m███████ ██    ██    ███████\033[0m   \033[0;36mORDER\033[0m"
        swBash .= "\n\033[1;31m     ██ ██    ██    ██   ██\033[0m"
        swBash .= "\n\033[1;31m███████ ██    ██    ██   ██\033[0m"
        swBash .= "\n\033[1;31mGreetings, Lord root. The dark side awaits.\033[0m"
        swBash .= "\n\033[0;36m🔗 \033[1;36m'$(. /etc/os-release 2>/dev/null && echo $NAME || echo Linux)'\033[0m  \033[1;33m⚠ \033[0;33m'$(uname -r | cut -d- -f1)'\033[0m  \033[1;35m◆ \033[0;35m'${HOSTNAME}'\033[0m"
        swBash .= '\n\033[0;37m"Anger leads to hate. Hate leads to suffering."\033[0m'
        swBash .= "\n"
        swBash .= "\n\033[0;36m🔗 '$(. /etc/os-release 2>/dev/null && echo $ID || echo linux)'\033[0m | \033[1;33m⚠ Linux\033[0m | \033[1;31m👤 \u@\H\033[0m | \033[0;36m⏰ \A\033[0m | \033[1;31m🔥 Sith\033[0m"
        swBash .= "\n\033[1;31m📁 \w\033[0m"
        swBash .= "\n\033[1;31m✔ ▶\033[0m ';"
        swBash .= " else "
        ; Normal = Jedi
        swBash .= "PS1=$'\n\033[1;33m     ██ ███████ ██████  ██\033[0m"
        swBash .= "\n\033[1;33m     ██ ██      ██   ██ ██\033[0m"
        swBash .= "\n\033[1;33m     ██ █████   ██   ██ ██\033[0m      \033[0;36mORDER\033[0m"
        swBash .= "\n\033[1;33m██   ██ ██      ██   ██ ██\033[0m"
        swBash .= "\n\033[1;33m █████  ███████ ██████  ██\033[0m"
        swBash .= "\n\033[0;32mWelcome, Padawan \u. The Force is strong with you.\033[0m"
        swBash .= "\n\033[0;36m🔗 \033[1;36m'$(. /etc/os-release 2>/dev/null && echo $NAME || echo Linux)'\033[0m  \033[1;33m⚠ \033[0;33m'$(uname -r | cut -d- -f1)'\033[0m  \033[1;35m◆ \033[0;35m'${HOSTNAME}'\033[0m"
        swBash .= '\n\033[0;37m"Anger leads to hate. Hate leads to suffering."\033[0m'
        swBash .= "\n"
        swBash .= "\n\033[0;36m🔗 '$(. /etc/os-release 2>/dev/null && echo $ID || echo linux)'\033[0m | \033[1;33m⚠ Linux\033[0m | \033[1;32m👤 \u@\H\033[0m | \033[0;36m⏰ \A\033[0m | \033[1;33m⭐ Jedi\033[0m"
        swBash .= "\n\033[1;34m📁 \w\033[0m"
        swBash .= "\n\033[1;34m✔ ▶\033[0m ';"
        swBash .= " fi; }; PROMPT_COMMAND=prompt_starwars; set -H"
        this.prompts.Push({
            id: "starwars-bash",
            name: "⚔ Star Wars",
            shellType: "bash",
            code: swBash,
            builtin: true,
            favorite: false,
            lastUsed: ""
        })

        ; ── Star Wars (PowerShell) — auto-detect: Jedi (normal) ↔ Sith (admin) + animation ──
        swPs := "function prompt { $e = [char]27; $u = $env:USERNAME; $h = $env:COMPUTERNAME; $t = Get-Date -Format 'HH:mm'; $loc = $executionContext.SessionState.Path.CurrentLocation; "
        swPs .= "$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator); "
        ; One-shot animation: Anakin → Darth Vader (6 full-screen frames)
        swPs .= "if ($isAdmin -and -not $global:_SW_ANIMATED) { $global:_SW_ANIMATED = $true; "
        ; Frame 1: Young Anakin
        swPs .= "Clear-Host; Write-Host " Chr(34) "``n$e[1;34m"
        swPs .= "              .        .     *        .    *     .        .``n"
        swPs .= "      *    .       .        .    .        .       *    .     ``n"
        swPs .= "                     $e[1;36m     |          $e[1;34m                         ``n"
        swPs .= "                     $e[1;36m     |          $e[1;34m            *             ``n"
        swPs .= "                     $e[1;36m     |          $e[1;34m                          ``n"
        swPs .= "                     $e[1;36m     |          $e[1;34m                          ``n"
        swPs .= "                     $e[1;33m   __|__        $e[1;34m                          ``n"
        swPs .= "                     $e[1;33m  / o o \       $e[1;34m                          ``n"
        swPs .= "                     $e[1;33m |  ---  |      $e[1;34m                          ``n"
        swPs .= "                     $e[1;33m  \_____/       $e[1;34m                          ``n"
        swPs .= "                  $e[0;33m  __|     |__     $e[1;34m                          ``n"
        swPs .= "                  $e[0;33m /   |   |   \    $e[1;34m                          ``n"
        swPs .= "                  $e[0;33m/    |   |    \   $e[1;34m                          ``n"
        swPs .= "                  $e[0;33m     |   |        $e[1;34m                          ``n"
        swPs .= "                  $e[0;33m    / \ / \       $e[1;34m                          ``n"
        swPs .= "                  $e[0;33m   /   V   \      $e[1;34m                          ``n"
        swPs .= "``n"
        swPs .= "        $e[1;36m⭐  A N A K I N   S K Y W A L K E R  ⭐$e[0m``n"
        swPs .= "        $e[0;36m     The Chosen One has arrived...$e[0m``n"
        swPs .= "        $e[0;34m   A long time ago in a galaxy far, far away...$e[0m``n"
        swPs .= "$e[0m" Chr(34) "; Start-Sleep -Milliseconds 2500; "
        ; Frame 2: Conflict
        swPs .= "Clear-Host; Write-Host " Chr(34) "``n$e[0m"
        swPs .= "  $e[1;34m ░░░░░░░░░░░░░░$e[0m          ║          $e[1;31m░░░░░░░░░░░░░░$e[0m``n"
        swPs .= "  $e[1;34m ░░ LIGHT  ░░░░$e[0m          ║          $e[1;31m░░░░  DARK ░░░$e[0m``n"
        swPs .= "  $e[1;34m ░░  SIDE  ░░░░$e[0m          ║          $e[1;31m░░░░  SIDE ░░░$e[0m``n"
        swPs .= "  $e[1;34m ░░░░░░░░░░░░░░$e[0m          ║          $e[1;31m░░░░░░░░░░░░░░$e[0m``n"
        swPs .= "  $e[1;36m     |  |       $e[0m          ║          $e[1;31m       |  |$e[0m``n"
        swPs .= "  $e[1;36m     |  |       $e[0m        $e[1;33m__|__$e[0m        $e[1;31m       |  |$e[0m``n"
        swPs .= "  $e[1;36m     |  |       $e[0m       $e[1;33m/ o o \$e[0m       $e[1;31m       |  |$e[0m``n"
        swPs .= "  $e[1;36m     |  |       $e[0m      $e[1;33m|  ---  |$e[0m      $e[1;31m       |  |$e[0m``n"
        swPs .= "  $e[1;36m     |  |       $e[0m       $e[1;33m\_____/$e[0m       $e[1;31m       |  |$e[0m``n"
        swPs .= "  $e[1;36m     |  |       $e[0m      $e[1;33m__|   |__$e[0m      $e[1;31m       |  |$e[0m``n"
        swPs .= "  $e[1;36m     |  |       $e[0m     $e[1;33m/  |   |  \$e[0m     $e[1;31m       |  |$e[0m``n"
        swPs .= "  $e[1;36m     |  |       $e[0m        $e[1;33m|   |$e[0m        $e[1;31m       |  |$e[0m``n"
        swPs .= "  $e[1;36m     |  |       $e[0m       $e[1;33m/ \ / \$e[0m       $e[1;31m       |  |$e[0m``n"
        swPs .= "  $e[1;36m     |  |       $e[0m      $e[1;33m/       \$e[0m      $e[1;31m       |  |$e[0m``n"
        swPs .= "``n"
        swPs .= "     $e[1;33m⚡  I can feel it... the dark side calls to me...  ⚡$e[0m``n"
        swPs .= "     $e[0;33m        The Force is pulling me apart...$e[0m``n"
        swPs .= "$e[0m" Chr(34) "; Start-Sleep -Milliseconds 2500; "
        ; Frame 3: The Fall
        swPs .= "Clear-Host; Write-Host " Chr(34) "``n$e[1;31m"
        swPs .= "       )\        /(          )\       /(        )\        /(``n"
        swPs .= "      ) \ \    / / (        ) \ \   / / (      ) \ \    / / (``n"
        swPs .= "     )  \ \  / /  (        )  \ \ / /  (     )  \ \  / /  (``n"
        swPs .= "    )   |\ \/ /|  (       )   |\ V /|  (    )   |\ \/ /|  (``n"
        swPs .= "    )   | \  / |  (       )   | \ / |  (    )   | \  / |  (``n"
        swPs .= "   )    |  \/  |   (      )   |  V  |   (   )   |  \/  |   (``n"
        swPs .= "   )    |      |   (      )   |     |   (   )   |      |   (``n"
        swPs .= "  )     |      |    (     )   |     |    (  )   |      |    ($e[0m``n"
        swPs .= "``n"
        swPs .= "                        $e[1;33m   ___________$e[0m``n"
        swPs .= "                        $e[1;33m  / $e[1;33;43m O $e[0;1;33m   $e[1;33;43m O $e[0;1;33m  \$e[0m``n"
        swPs .= "                        $e[1;33m |    \___/    |$e[0m``n"
        swPs .= "                        $e[1;31m  \___________/$e[0m``n"
        swPs .= "``n"
        swPs .= "  $e[1;37m ╔═══════════════════════════════════════════════════════╗$e[0m``n"
        swPs .= "  $e[1;37m ║  $e[1;36m You were supposed to destroy the Sith, not join them! $e[1;37m ║$e[0m``n"
        swPs .= "  $e[1;37m ║  $e[1;33m You were my brother, Anakin... I loved you.          $e[1;37m ║$e[0m``n"
        swPs .= "  $e[1;37m ╚═══════════════════════════════════════════════════════╝$e[0m``n"
        swPs .= "$e[0m" Chr(34) "; Start-Sleep -Milliseconds 3000; "
        ; Frame 4: The Mask — Surgery
        swPs .= "Clear-Host; Write-Host " Chr(34) "``n$e[0m"
        swPs .= "  $e[0;37m ┌─────────────────────────────────────────────────────────┐$e[0m``n"
        swPs .= "  $e[0;37m │$e[1;31m              THE SURGICAL RECONSTRUCTION               $e[0;37m│$e[0m``n"
        swPs .= "  $e[0;37m └─────────────────────────────────────────────────────────┘$e[0m``n"
        swPs .= "``n"
        swPs .= "                    $e[1;37m         ▼ ▼ ▼$e[0m``n"
        swPs .= "                    $e[0;37m    ┌───────────────┐$e[0m``n"
        swPs .= "                    $e[0;37m   ╱   ╱─────────╲   ╲$e[0m``n"
        swPs .= "                    $e[0;37m  ╱   ╱  ▄▄   ▄▄  ╲   ╲$e[0m``n"
        swPs .= "                    $e[0;37m │   │  █▀▀█ █▀▀█  │   │$e[0m``n"
        swPs .= "                    $e[0;37m │   │  ▀▄▄▀ ▀▄▄▀  │   │$e[0m``n"
        swPs .= "                    $e[0;37m │   │     ╲▄╱     │   │$e[0m``n"
        swPs .= "                    $e[0;37m  ╲   ╲  ▄▄▄▄▄▄▄ ╱   ╱$e[0m``n"
        swPs .= "                    $e[0;37m   ╲   ╲─────────╱   ╱$e[0m``n"
        swPs .= "                    $e[0;37m    └───────────────┘$e[0m``n"
        swPs .= "``n"
        swPs .= "             $e[0;37m ═══╦═══   ═══╦═══   ═══╦═══   ═══╦═══$e[0m``n"
        swPs .= "             $e[0;37m    ║          ║          ║          ║$e[0m``n"
        swPs .= "  $e[0;90m ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓$e[0m``n"
        swPs .= "``n"
        swPs .= "         $e[0;31m   Anakin Skywalker is no more...$e[0m``n"
        swPs .= "         $e[0;37m   The mask descends. The transformation begins.$e[0m``n"
        swPs .= "$e[0m" Chr(34) "; Start-Sleep -Milliseconds 3000; "
        ; Frame 5: Vader Rises
        swPs .= "Clear-Host; Write-Host " Chr(34) "``n$e[1;31m"
        swPs .= "                        ┌───────────────┐``n"
        swPs .= "                       ╱   ╱─────────╲   ╲``n"
        swPs .= "                      ╱   ╱  ▄▄   ▄▄  ╲   ╲``n"
        swPs .= "                     │   │  █▀▀█ █▀▀█  │   │``n"
        swPs .= "                     │   │  ▀▄▄▀ ▀▄▄▀  │   │``n"
        swPs .= "                     │   │     ╲▄╱     │   │``n"
        swPs .= "                      ╲   ╲  ▄▄▄▄▄▄▄ ╱   ╱``n"
        swPs .= "                       ╲   ╲─────────╱   ╱``n"
        swPs .= "                        └───────┬───────┘``n"
        swPs .= "                    ┌───────────┼───────────┐``n"
        swPs .= "               ╱╲   │  ┌─┐ ┌───┼───┐ ┌─┐  │   ╱╲``n"
        swPs .= "              ╱  ╲  │  │○│ │ ◆ │ ◆ │ │○│  │  ╱  ╲``n"
        swPs .= "             ╱    ╲ │  └─┘ └───┼───┘ └─┘  │ ╱    ╲``n"
        swPs .= "            ╱      ╲│          │          │╱      ╲``n"
        swPs .= "           ╱        │         ╱ ╲         │        ╲``n"
        swPs .= "          ╱         │        ╱   ╲        │         ╲``n"
        swPs .= "         ╱          │       ╱     ╲       │          ╲``n"
        swPs .= "        ╱           └──────╱       ╲──────┘           ╲$e[0m``n"
        swPs .= "``n"
        swPs .= "   $e[1;37m KSSHHH...$e[0m  $e[1;31m━━━━━━━━━━━━━━━━━━━━━━━━━━$e[0m  $e[1;37m*lightsaber ignites*$e[0m``n"
        swPs .= "$e[0m" Chr(34) "; Start-Sleep -Milliseconds 3000; "
        ; Frame 6: Final — Iconic close-up
        swPs .= "Clear-Host; Write-Host " Chr(34) "``n``n$e[1;31m"
        swPs .= "            ╔═══════════════════════════════════════════╗``n"
        swPs .= "           ╱         ╱───────────────────╲         ╲``n"
        swPs .= "          ╱         ╱    ╱───────────╲    ╲         ╲``n"
        swPs .= "         ╱         ╱    ╱  ▄▄▄   ▄▄▄  ╲    ╲         ╲``n"
        swPs .= "        │         │    │  █████ █████  │    │         │``n"
        swPs .= "        │         │    │  ▀▀▀▀▀ ▀▀▀▀▀  │    │         │``n"
        swPs .= "        │         │    │      ╲▄▄╱      │    │         │``n"
        swPs .= "        │         │     ╲    ▄▄▄▄▄    ╱     │         │``n"
        swPs .= "         ╲         ╲     ╲───────────╱     ╱         ╱``n"
        swPs .= "          ╲         ╲───────────────────╱         ╱``n"
        swPs .= "           ╲═══════════════════════════════════════╱$e[0m``n"
        swPs .= "``n"
        swPs .= "$e[1;37m  ╔═══════════════════════════════════════════════════════════╗$e[0m``n"
        swPs .= "$e[1;37m  ║                                                           ║$e[0m``n"
        swPs .= "$e[1;37m  ║         $e[1;31m  I  am...  D A R T H   V A D E R .  $e[1;37m            ║$e[0m``n"
        swPs .= "$e[1;37m  ║                                                           ║$e[0m``n"
        swPs .= "$e[1;37m  ╚═══════════════════════════════════════════════════════════╝$e[0m``n"
        swPs .= "$e[0m" Chr(34) "; Start-Sleep -Milliseconds 3500; Clear-Host; }; "
        swPs .= "if ($isAdmin) { "
        ; Admin = Sith
        swPs .= "Write-Host " Chr(34) "$e[1;31m███████ ██ ████████ ██   ██$e[0m" Chr(34) "; "
        swPs .= "Write-Host " Chr(34) "$e[1;31m██      ██    ██    ██   ██$e[0m" Chr(34) "; "
        swPs .= "Write-Host " Chr(34) "$e[1;31m███████ ██    ██    ███████$e[0m   $e[0;36mORDER$e[0m" Chr(34) "; "
        swPs .= "Write-Host " Chr(34) "$e[1;31m     ██ ██    ██    ██   ██$e[0m" Chr(34) "; "
        swPs .= "Write-Host " Chr(34) "$e[1;31m███████ ██    ██    ██   ██$e[0m" Chr(34) "; "
        swPs .= "Write-Host " Chr(34) "$e[1;31mGreetings, Lord $u. The dark side awaits.$e[0m" Chr(34) "; "
        swPs .= "Write-Host " Chr(34) "$e[0;36m🔗 $e[1;36mWindows$e[0m  $e[1;33m⚠ $e[0;33mPS $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)$e[0m  $e[1;35m◆ $e[0;35m$h$e[0m" Chr(34) "; "
        swPs .= "Write-Host " Chr(34) "$e[0;37m``" Chr(34) "Anger leads to hate. Hate leads to suffering.``" Chr(34) "$e[0m" Chr(34) "; "
        swPs .= "Write-Host; "
        swPs .= "Write-Host " Chr(34) "$e[0;36m🔗 Windows$e[0m | $e[1;33m⚠ PS$e[0m | $e[1;31m👤 $u@$h$e[0m | $e[0;36m⏰ $t$e[0m | $e[1;31m🔥 Sith$e[0m" Chr(34) "; "
        swPs .= "Write-Host " Chr(34) "$e[1;31m📁 $loc$e[0m" Chr(34) "; "
        swPs .= Chr(34) "$e[1;31m✔ ▶$e[0m " Chr(34)
        swPs .= " } else { "
        ; Normal = Jedi
        swPs .= "Write-Host " Chr(34) "$e[1;33m     ██ ███████ ██████  ██$e[0m" Chr(34) "; "
        swPs .= "Write-Host " Chr(34) "$e[1;33m     ██ ██      ██   ██ ██$e[0m" Chr(34) "; "
        swPs .= "Write-Host " Chr(34) "$e[1;33m     ██ █████   ██   ██ ██      $e[0;36mORDER$e[0m" Chr(34) "; "
        swPs .= "Write-Host " Chr(34) "$e[1;33m██   ██ ██      ██   ██ ██$e[0m" Chr(34) "; "
        swPs .= "Write-Host " Chr(34) "$e[1;33m █████  ███████ ██████  ██$e[0m" Chr(34) "; "
        swPs .= "Write-Host " Chr(34) "$e[0;32mWelcome, Padawan $u. The Force is strong with you.$e[0m" Chr(34) "; "
        swPs .= "Write-Host " Chr(34) "$e[0;36m🔗 $e[1;36mWindows$e[0m  $e[1;33m⚠ $e[0;33mPS $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)$e[0m  $e[1;35m◆ $e[0;35m$h$e[0m" Chr(34) "; "
        swPs .= "Write-Host " Chr(34) "$e[0;37m``" Chr(34) "Anger leads to hate. Hate leads to suffering.``" Chr(34) "$e[0m" Chr(34) "; "
        swPs .= "Write-Host; "
        swPs .= "Write-Host " Chr(34) "$e[0;36m🔗 Windows$e[0m | $e[1;33m⚠ PS$e[0m | $e[1;32m👤 $u@$h$e[0m | $e[0;36m⏰ $t$e[0m | $e[1;33m⭐ Jedi$e[0m" Chr(34) "; "
        swPs .= "Write-Host " Chr(34) "$e[1;34m📁 $loc$e[0m" Chr(34) "; "
        swPs .= Chr(34) "$e[1;34m✔ ▶$e[0m " Chr(34)
        swPs .= " } }"
        this.prompts.Push({
            id: "starwars-ps",
            name: "⚔ Star Wars",
            shellType: "powershell",
            code: swPs,
            builtin: true,
            favorite: false,
            lastUsed: ""
        })

        ; ── Powerline (PowerShell) ──
        plPs := "function prompt { $e = [char]27; $u = $env:USERNAME; $h = $env:COMPUTERNAME; $t = Get-Date -Format 'HH:mm:ss'; $loc = $executionContext.SessionState.Path.CurrentLocation; "
        plPs .= "$b = ''; try { $b = (git branch --show-current 2>$null) } catch {}; "
        plPs .= "$w = $Host.UI.RawUI.WindowSize.Width; "
        plPs .= "$right = " Chr(34) " 👤 $u / $h / $t " Chr(34) "; "
        plPs .= "$folder = if ($loc.Path -eq $HOME) { '🏠 ~' } else { " Chr(34) "📁 $($loc.Path | Split-Path -Leaf)" Chr(34) " }; "
        plPs .= "$git = if ($b) { " Chr(34) " $e[32m $b$e[0m" Chr(34) " } else { '' }; "
        plPs .= "$left = " Chr(34) " $folder$git " Chr(34) "; "
        plPs .= "$pad = $w - ($left.Length + $right.Length) - 2; if ($pad -lt 0) { $pad = 0 }; "
        plPs .= "Write-Host " Chr(34) "$e[30;46m$left$e[0m$e[36m$e[0m$(' ' * $pad)$e[30;45m$right$e[0m$e[35m$e[0m" Chr(34) "; "
        plPs .= Chr(34) "$e[36m❯$e[0m " Chr(34) " }"
        this.prompts.Push({
            id: "powerline-ps",
            name: "⚡ Powerline",
            shellType: "powershell",
            code: plPs,
            builtin: true,
            favorite: false,
            lastUsed: ""
        })

        ; ── Powerline (Bash) ──
        plBash := "export PS1='"
        plBash .= "\[\033[30;46m\] $(if [ " Chr(34) "\w" Chr(34) " = " Chr(34) "~" Chr(34) " ]; then echo " Chr(34) "🏠 ~" Chr(34) "; else echo " Chr(34) "📁 \W" Chr(34) "; fi)$(git branch --show-current 2>/dev/null | sed " Chr(34) "s/^/  /;s/$//" Chr(34) ") \[\033[0m\]\[\033[36m\]\[\033[0m\]"
        plBash .= " \[\033[30;45m\] 👤 \u / \H / \A \[\033[0m\]\[\033[35m\]\[\033[0m\]"
        plBash .= "\n\[\033[36m\]❯\[\033[0m\] '"
        this.prompts.Push({
            id: "powerline-bash",
            name: "⚡ Powerline",
            shellType: "bash",
            code: plBash,
            builtin: true,
            favorite: false,
            lastUsed: ""
        })

        ; ── Dragon Ball (Bash) — auto-detect root vs user via function + animation ──
        ; set +H disables history expansion to avoid ! issues in $'...' strings
        dbBash := "set +H; prompt_dragonball() { if [ $EUID -eq 0 ]; then "
        ; One-shot animation: Goku gathering 7 dragon balls + Shenlong (6 full-screen frames)
        dbBash .= "if [ -z " Chr(34) "$_DB_ANIMATED" Chr(34) " ]; then export _DB_ANIMATED=1; "
        ; Frame 1: Goku searching on Nimbus cloud
        dbBash .= "clear; echo -e '\n\033[1;38;5;208m"
        dbBash .= "                          .-``````-.                                  \n"
        dbBash .= "                        .`           `.                               \n"
        dbBash .= "                       /  .-```````-.  \\                              \n"
        dbBash .= "                      |  /   o   o  \\  |                             \n"
        dbBash .= "                      | |     <      | |                              \n"
        dbBash .= "                      |  \\   ___   /  |                              \n"
        dbBash .= "                       \\  ``-......-``  /                              \n"
        dbBash .= "                      __|``-.______.-``|__                             \n"
        dbBash .= "                     /   |          |   \\                             \n"
        dbBash .= "                    /    |    ||    |    \\                            \n"
        dbBash .= "                         |    ||    |                                  \n"
        dbBash .= "                        /\\   /  \\   /\\                               \n"
        dbBash .= "                       /  \\ /    \\ /  \\                              \n"
        dbBash .= "          \033[1;37m    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\033[1;38;5;208m           \n"
        dbBash .= "          \033[1;37m   ~   ~   ~   NUVEM VOADORA   ~   ~   ~   ~\033[1;38;5;208m          \n"
        dbBash .= "          \033[1;37m    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\033[1;38;5;208m           \n"
        dbBash .= "\n"
        dbBash .= "     \033[1;38;5;208m⭐  G O K U   procurando as esferas do dragao...  ⭐\033[0m\n"
        dbBash .= "     \033[0;33m           O radar do dragao esta apitando...\033[0m\n"
        dbBash .= "\033[0m'; sleep 2.5; "
        ; Frame 2: 7 Dragon Balls found — arranged with stars inside
        dbBash .= "clear; echo -e '\n\033[1;33m"
        dbBash .= "                   AS  7  ESFERAS  DO  DRAGAO                       \n"
        dbBash .= "\n"
        dbBash .= "          \033[1;38;5;208m ___     ___     ___     ___\033[0m\n"
        dbBash .= "          \033[1;38;5;208m/   \\   /   \\   /   \\   /   \\\033[0m\n"
        dbBash .= "          \033[1;38;5;208m| ★ |   |★★ |   |★★★|   |★ ★|\033[0m\n"
        dbBash .= "          \033[1;38;5;208m|   |   |   |   |   |   |★★ |\033[0m\n"
        dbBash .= "          \033[1;38;5;208m\\___/   \\___/   \\___/   \\___/\033[0m\n"
        dbBash .= "\n"
        dbBash .= "             \033[1;38;5;208m ___     ___     ___\033[0m\n"
        dbBash .= "             \033[1;38;5;208m/   \\   /   \\   /   \\\033[0m\n"
        dbBash .= "             \033[1;38;5;208m|★★★|   |★★★|   |★★★|\033[0m\n"
        dbBash .= "             \033[1;38;5;208m|★★ |   |★★★|   |★★★|\033[0m\n"
        dbBash .= "             \033[1;38;5;208m\\___/   \\___/   \\___/\033[0m\n"
        dbBash .= "\n"
        dbBash .= "     \033[1;33m⭐  Todas as 7 esferas foram reunidas!  ⭐\033[0m\n"
        dbBash .= "     \033[0;33m       O ceu esta ficando escuro...\033[0m\n"
        dbBash .= "\033[0m'; sleep 2.5; "
        ; Frame 3: Sky darkens — Lightning, balls shooting energy
        dbBash .= "clear; echo -e '\n\033[0m"
        dbBash .= "  \033[1;33m              ⚡                    ⚡              ⚡\033[0m\n"
        dbBash .= "  \033[1;33m           ⚡    ⚡              ⚡    ⚡                \033[0m\n"
        dbBash .= "  \033[0;90m ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░\033[0m\n"
        dbBash .= "  \033[0;90m ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░\033[0m\n"
        dbBash .= "\n"
        dbBash .= "                     \033[1;33m   |         |         |\033[0m\n"
        dbBash .= "                     \033[1;33m   |    |    |    |    |\033[0m\n"
        dbBash .= "                     \033[1;33m   |    |    |    |    |\033[0m\n"
        dbBash .= "\n"
        dbBash .= "             \033[1;38;5;208m   ★    ★    ★    ★    ★    ★    ★\033[0m\n"
        dbBash .= "             \033[1;38;5;208m  (1)  (2)  (3)  (4)  (5)  (6)  (7)\033[0m\n"
        dbBash .= "\n"
        dbBash .= "                     \033[1;33m   |    |    |    |    |\033[0m\n"
        dbBash .= "                     \033[1;33m   |    |    |    |    |\033[0m\n"
        dbBash .= "                     \033[1;33m   |         |         |\033[0m\n"
        dbBash .= "\n"
        dbBash .= "  \033[1;33m ⚡⚡  O ceu escurece... Shenlong esta chegando...  ⚡⚡\033[0m\n"
        dbBash .= "\033[0m'; sleep 3; "
        dbBash .= "clear; echo -e '\n\033[1;32m"
        dbBash .= "  \033[0;90m ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░\033[0m\n"
        dbBash .= "  \033[0;90m ░░░░░░░░░░░\033[1;32m        ___....___        \033[0;90m░░░░░░░░░░░░░░░░░\033[0m\n"
        dbBash .= "  \033[0;90m ░░░░░░░░\033[1;32m      .--``            ``--.     \033[0;90m░░░░░░░░░░░░░░\033[0m\n"
        dbBash .= "  \033[0;90m ░░░░░\033[1;32m      /``    \033[1;33m@@\033[1;32m          \033[1;33m@@\033[1;32m    ``\\     \033[0;90m░░░░░░░░░░░\033[0m\n"
        dbBash .= "  \033[0;90m ░░░\033[1;32m       |    \033[1;31m<\033[1;32m                \033[1;31m>\033[1;32m    |      \033[0;90m░░░░░░░░░\033[0m\n"
        dbBash .= "  \033[0;90m ░░\033[1;32m        |      .-``````````-.      |       \033[0;90m░░░░░░░░\033[0m\n"
        dbBash .= "  \033[0;90m ░\033[1;32m         |     /  \\\\\\\\\\\\\\\\  \\     |        \033[0;90m░░░░░░░\033[0m\n"
        dbBash .= "  \033[1;32m          \\     ``-..________...-``     /                     \n"
        dbBash .= "           ``--.                      .--``                      \n"
        dbBash .= "               ``----.............----``                         \n"
        dbBash .= "\n"
        dbBash .= "     \033[1;32m🐉  S H E N L O N G   esta surgindo das nuvens...  🐉\033[0m\n"
        dbBash .= "\033[0m'; sleep 3; "
        ; Frame 5: Shenlong full body — serpentine dragon coiling
        dbBash .= "clear; echo -e '\n\033[1;32m"
        dbBash .= "                        .---.\n"
        dbBash .= "                   .---``     ``---.\n"
        dbBash .= "              .---``    \033[1;33m@@  @@\033[1;32m    ``---.\n"
        dbBash .= "         .---``     \033[1;31m<\033[1;32m            \033[1;31m>\033[1;32m     ``---.\n"
        dbBash .= "    .---``          .---````----.          ``---.\n"
        dbBash .= "   /         .----``            ``----.         \\\n"
        dbBash .= "  |     .---``                        ``---.     |\n"
        dbBash .= "  |    /          \033[1;33m S H E N L O N G \033[1;32m         \\    |\n"
        dbBash .= "   \\  |     .---``                    ``---.     |  /\n"
        dbBash .= "    ``-|    /                              \\    |-``\n"
        dbBash .= "      |   |    .---.              .---.    |   |\n"
        dbBash .= "       \\  |   /     \\            /     \\   |  /\n"
        dbBash .= "        ``-|  |       |          |       |  |-``\n"
        dbBash .= "          |   \\     /            \\     /   |\n"
        dbBash .= "           \\   ``---``              ``---``   /\n"
        dbBash .= "            ``---.                  .---``\n"
        dbBash .= "                ``------......------``\n"
        dbBash .= "\n"
        dbBash .= "  \033[1;33m╔══════════════════════════════════════════════════════════╗\033[0m\n"
        dbBash .= "  \033[1;33m║    \033[1;32m🐉  FALE SEU DESEJO, MORTAL! EU O REALIZAREI!  🐉\033[1;33m    ║\033[0m\n"
        dbBash .= "  \033[1;33m╚══════════════════════════════════════════════════════════╝\033[0m\n"
        dbBash .= "\033[0m'; sleep 3; "
        ; Frame 6: Wish granted — Golden power explosion
        dbBash .= "clear; echo -e '\n\n\033[1;33m"
        dbBash .= "                          ⚡  ⚡  ⚡\n"
        dbBash .= "                    ⚡                    ⚡\n"
        dbBash .= "               ⚡      .============.      ⚡\n"
        dbBash .= "            ⚡       //              \\\\       ⚡\n"
        dbBash .= "          ⚡       //    \033[1;37mP O D E R\033[1;33m    \\\\       ⚡\n"
        dbBash .= "         ⚡       ||     \033[1;37m  T O T A L\033[1;33m   ||       ⚡\n"
        dbBash .= "          ⚡       \\\\   \033[1;37mCONCEDIDO!\033[1;33m   //       ⚡\n"
        dbBash .= "            ⚡       \\\\              //       ⚡\n"
        dbBash .= "               ⚡      ``============``      ⚡\n"
        dbBash .= "                    ⚡                    ⚡\n"
        dbBash .= "                          ⚡  ⚡  ⚡\n"
        dbBash .= "\n"
        dbBash .= "  \033[1;37m╔══════════════════════════════════════════════════════════╗\033[0m\n"
        dbBash .= "  \033[1;37m║                                                          ║\033[0m\n"
        dbBash .= "  \033[1;37m║     \033[1;33m⚡  Voce agora e  S U P E R   S A I Y A N !  ⚡\033[1;37m     ║\033[0m\n"
        dbBash .= "  \033[1;37m║                                                          ║\033[0m\n"
        dbBash .= "  \033[1;37m╚══════════════════════════════════════════════════════════╝\033[0m\n"
        dbBash .= "\033[0m'; sleep 3.5; clear; fi; "
        ; Root = Super Saiyan + Shenlong
        dbBash .= "PS1=$'\n\033[1;33m███████ ███████      ██\033[0m"
        dbBash .= "\n\033[1;33m██      ██           ██\033[0m"
        dbBash .= "\n\033[1;33m███████ ███████      ██\033[0m   \033[0;36mSUPER SAIYAN\033[0m"
        dbBash .= "\n\033[1;33m     ██      ██ ██   ██\033[0m"
        dbBash .= "\n\033[1;33m███████ ███████  █████ \033[0m"
        dbBash .= "\n\033[1;33m🐉 As 7 esferas foram reunidas! Shenlong, realize meu desejo!\033[0m"
        dbBash .= "\n\033[1;32mSeu desejo foi realizado. Voce agora tem poder TOTAL.\033[0m"
        dbBash .= "\n\033[0;36m🔗 \033[1;36m'$(. /etc/os-release 2>/dev/null && echo $NAME || echo Linux)'\033[0m  \033[1;33m⚠ \033[0;33m'$(uname -r | cut -d- -f1)'\033[0m  \033[1;35m◆ \033[0;35m'${HOSTNAME}'\033[0m"
        dbBash .= '\n\033[0;37m"O poder vem do treinamento, nao do desejo."\033[0m'
        dbBash .= "\n"
        dbBash .= "\n\033[0;36m🐉 '$(. /etc/os-release 2>/dev/null && echo $ID || echo linux)'\033[0m | \033[1;33m⚠ Linux\033[0m | \033[1;31m👤 \u@\H\033[0m | \033[0;36m⏰ \A\033[0m | \033[1;33m⚡ Super Saiyan\033[0m"
        dbBash .= "\n\033[1;33m📁 \w\033[0m"
        dbBash .= "\n\033[1;33m✔ ▶\033[0m ';"
        dbBash .= " else "
        ; Normal = Goku
        dbBash .= "PS1=$'\n\033[1;38;5;208m ██████   ██████  ██   ██ ██   ██\033[0m"
        dbBash .= "\n\033[1;38;5;208m██       ██    ██ ██  ██  ██   ██\033[0m"
        dbBash .= "\n\033[1;38;5;208m██   ███ ██    ██ █████   ██   ██\033[0m   \033[0;36mDRAGON BALL\033[0m"
        dbBash .= "\n\033[1;38;5;208m██    ██ ██    ██ ██  ██  ██   ██\033[0m"
        dbBash .= "\n\033[1;38;5;208m ██████   ██████  ██   ██  █████ \033[0m"
        dbBash .= "\n\033[1;38;5;208mEu sou Goku! Vou treinar e ficar mais forte!\033[0m"
        dbBash .= "\n\033[0;36m🔗 \033[1;36m'$(. /etc/os-release 2>/dev/null && echo $NAME || echo Linux)'\033[0m  \033[1;33m⚠ \033[0;33m'$(uname -r | cut -d- -f1)'\033[0m  \033[1;35m◆ \033[0;35m'${HOSTNAME}'\033[0m"
        dbBash .= '\n\033[0;37m"O poder vem do treinamento, nao do desejo."\033[0m'
        dbBash .= "\n"
        dbBash .= "\n\033[0;36m🟠 '$(. /etc/os-release 2>/dev/null && echo $ID || echo linux)'\033[0m | \033[1;33m⚠ Linux\033[0m | \033[1;32m👤 \u@\H\033[0m | \033[0;36m⏰ \A\033[0m | \033[1;38;5;208m⭐ Goku\033[0m"
        dbBash .= "\n\033[1;38;5;208m📁 \w\033[0m"
        dbBash .= "\n\033[1;38;5;208m✔ ▶\033[0m ';"
        dbBash .= " fi; }; PROMPT_COMMAND=prompt_dragonball; set -H"
        this.prompts.Push({
            id: "dragonball-bash",
            name: "🐉 Dragon Ball",
            shellType: "bash",
            code: dbBash,
            builtin: true,
            favorite: false,
            lastUsed: ""
        })

        ; ── Dragon Ball (PowerShell) — auto-detect admin vs normal + animation ──
        dbPs := "function prompt { $e = [char]27; $u = $env:USERNAME; $h = $env:COMPUTERNAME; $t = Get-Date -Format 'HH:mm'; $loc = $executionContext.SessionState.Path.CurrentLocation; "
        dbPs .= "$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator); "
        ; One-shot animation: Goku gathering 7 dragon balls + Shenlong (6 full-screen frames)
        dbPs .= "if ($isAdmin -and -not $global:_DB_ANIMATED) { $global:_DB_ANIMATED = $true; "
        ; Frame 1: Goku searching on Nimbus cloud
        dbPs .= "Clear-Host; Write-Host " Chr(34) "``n$e[1;38;5;208m"
        dbPs .= "                          .-``````````-.                                  ``n"
        dbPs .= "                        .``           ``.                               ``n"
        dbPs .= "                       /  .-``````````````-.  \                              ``n"
        dbPs .= "                      |  /   o   o  \  |                             ``n"
        dbPs .= "                      | |     <      | |                              ``n"
        dbPs .= "                      |  \   ___   /  |                              ``n"
        dbPs .= "                       \  ``-......-``  /                              ``n"
        dbPs .= "                      __|``-.______.-``|__                             ``n"
        dbPs .= "                     /   |          |   \                             ``n"
        dbPs .= "                    /    |    ||    |    \                            ``n"
        dbPs .= "                         |    ||    |                                  ``n"
        dbPs .= "                        /\   /  \   /\                               ``n"
        dbPs .= "                       /  \ /    \ /  \                              ``n"
        dbPs .= "          $e[1;37m    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$e[1;38;5;208m           ``n"
        dbPs .= "          $e[1;37m   ~   ~   ~   NUVEM VOADORA   ~   ~   ~   ~$e[1;38;5;208m          ``n"
        dbPs .= "          $e[1;37m    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$e[1;38;5;208m           ``n"
        dbPs .= "``n"
        dbPs .= "     $e[1;38;5;208m⭐  G O K U   procurando as esferas do dragao...  ⭐$e[0m``n"
        dbPs .= "     $e[0;33m           O radar do dragao esta apitando...$e[0m``n"
        dbPs .= "$e[0m" Chr(34) "; Start-Sleep -Milliseconds 2500; "
        ; Frame 2: 7 Dragon Balls found
        dbPs .= "Clear-Host; Write-Host " Chr(34) "``n$e[1;33m"
        dbPs .= "                   AS  7  ESFERAS  DO  DRAGAO                       ``n"
        dbPs .= "``n"
        dbPs .= "          $e[1;38;5;208m ___     ___     ___     ___$e[0m``n"
        dbPs .= "          $e[1;38;5;208m/   \   /   \   /   \   /   \$e[0m``n"
        dbPs .= "          $e[1;38;5;208m| ★ |   |★★ |   |★★★|   |★ ★|$e[0m``n"
        dbPs .= "          $e[1;38;5;208m|   |   |   |   |   |   |★★ |$e[0m``n"
        dbPs .= "          $e[1;38;5;208m\___/   \___/   \___/   \___/$e[0m``n"
        dbPs .= "``n"
        dbPs .= "             $e[1;38;5;208m ___     ___     ___$e[0m``n"
        dbPs .= "             $e[1;38;5;208m/   \   /   \   /   \$e[0m``n"
        dbPs .= "             $e[1;38;5;208m|★★★|   |★★★|   |★★★|$e[0m``n"
        dbPs .= "             $e[1;38;5;208m|★★ |   |★★★|   |★★★|$e[0m``n"
        dbPs .= "             $e[1;38;5;208m\___/   \___/   \___/$e[0m``n"
        dbPs .= "``n"
        dbPs .= "     $e[1;33m⭐  Todas as 7 esferas foram reunidas!  ⭐$e[0m``n"
        dbPs .= "     $e[0;33m       O ceu esta ficando escuro...$e[0m``n"
        dbPs .= "$e[0m" Chr(34) "; Start-Sleep -Milliseconds 2500; "
        ; Frame 3: Sky darkens — Lightning
        dbPs .= "Clear-Host; Write-Host " Chr(34) "``n$e[0m"
        dbPs .= "  $e[1;33m              ⚡                    ⚡              ⚡$e[0m``n"
        dbPs .= "  $e[1;33m           ⚡    ⚡              ⚡    ⚡                $e[0m``n"
        dbPs .= "  $e[0;90m ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░$e[0m``n"
        dbPs .= "  $e[0;90m ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░$e[0m``n"
        dbPs .= "``n"
        dbPs .= "                     $e[1;33m   |         |         |$e[0m``n"
        dbPs .= "                     $e[1;33m   |    |    |    |    |$e[0m``n"
        dbPs .= "                     $e[1;33m   |    |    |    |    |$e[0m``n"
        dbPs .= "``n"
        dbPs .= "             $e[1;38;5;208m   ★    ★    ★    ★    ★    ★    ★$e[0m``n"
        dbPs .= "             $e[1;38;5;208m  (1)  (2)  (3)  (4)  (5)  (6)  (7)$e[0m``n"
        dbPs .= "``n"
        dbPs .= "                     $e[1;33m   |    |    |    |    |$e[0m``n"
        dbPs .= "                     $e[1;33m   |    |    |    |    |$e[0m``n"
        dbPs .= "                     $e[1;33m   |         |         |$e[0m``n"
        dbPs .= "``n"
        dbPs .= "  $e[1;33m ⚡⚡  O ceu escurece... Shenlong esta chegando...  ⚡⚡$e[0m``n"
        dbPs .= "$e[0m" Chr(34) "; Start-Sleep -Milliseconds 3000; "
        ; Frame 4: Shenlong emerges
        dbPs .= "Clear-Host; Write-Host " Chr(34) "``n$e[1;32m"
        dbPs .= "  $e[0;90m ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░$e[0m``n"
        dbPs .= "  $e[0;90m ░░░░░░░░░░░$e[1;32m        ___....___        $e[0;90m░░░░░░░░░░░░░░░░░$e[0m``n"
        dbPs .= "  $e[0;90m ░░░░░░░░$e[1;32m      .--``            ``--.     $e[0;90m░░░░░░░░░░░░░░$e[0m``n"
        dbPs .= "  $e[0;90m ░░░░░$e[1;32m      /``    $e[1;33m@@$e[1;32m          $e[1;33m@@$e[1;32m    ``\     $e[0;90m░░░░░░░░░░░$e[0m``n"
        dbPs .= "  $e[0;90m ░░░$e[1;32m       |    $e[1;31m<$e[1;32m                $e[1;31m>$e[1;32m    |      $e[0;90m░░░░░░░░░$e[0m``n"
        dbPs .= "  $e[0;90m ░░$e[1;32m        |      .-``````````-.      |       $e[0;90m░░░░░░░░$e[0m``n"
        dbPs .= "  $e[0;90m ░$e[1;32m         |     /  \\\\\\\\  \     |        $e[0;90m░░░░░░░$e[0m``n"
        dbPs .= "  $e[1;32m          \     ``-..________...-``     /                     ``n"
        dbPs .= "           ``--.                      .--``                      ``n"
        dbPs .= "               ``----.............----``                         ``n"
        dbPs .= "``n"
        dbPs .= "     $e[1;32m🐉  S H E N L O N G   esta surgindo das nuvens...  🐉$e[0m``n"
        dbPs .= "$e[0m" Chr(34) "; Start-Sleep -Milliseconds 3000; "
        ; Frame 5: Shenlong full body
        dbPs .= "Clear-Host; Write-Host " Chr(34) "``n$e[1;32m"
        dbPs .= "                        .---.``n"
        dbPs .= "                   .---``     ``---.``n"
        dbPs .= "              .---``    $e[1;33m@@  @@$e[1;32m    ``---.``n"
        dbPs .= "         .---``     $e[1;31m<$e[1;32m            $e[1;31m>$e[1;32m     ``---.``n"
        dbPs .= "    .---``          .---````----.          ``---.``n"
        dbPs .= "   /         .----``            ``----.         \``n"
        dbPs .= "  |     .---``                        ``---.     |``n"
        dbPs .= "  |    /          $e[1;33m S H E N L O N G $e[1;32m         \    |``n"
        dbPs .= "   \  |     .---``                    ``---.     |  /``n"
        dbPs .= "    ``-|    /                              \    |-````n"
        dbPs .= "      |   |    .---.              .---.    |   |``n"
        dbPs .= "       \  |   /     \            /     \   |  /``n"
        dbPs .= "        ``-|  |       |          |       |  |-````n"
        dbPs .= "          |   \     /            \     /   |``n"
        dbPs .= "           \   ``---``              ``---``   /``n"
        dbPs .= "            ``---.                  .---````n"
        dbPs .= "                ``------......------````n"
        dbPs .= "``n"
        dbPs .= "  $e[1;33m╔══════════════════════════════════════════════════════════╗$e[0m``n"
        dbPs .= "  $e[1;33m║    $e[1;32m🐉  FALE SEU DESEJO, MORTAL! EU O REALIZAREI!  🐉$e[1;33m    ║$e[0m``n"
        dbPs .= "  $e[1;33m╚══════════════════════════════════════════════════════════╝$e[0m``n"
        dbPs .= "$e[0m" Chr(34) "; Start-Sleep -Milliseconds 3000; "
        ; Frame 6: Wish granted — Golden power explosion
        dbPs .= "Clear-Host; Write-Host " Chr(34) "``n``n$e[1;33m"
        dbPs .= "                          ⚡  ⚡  ⚡``n"
        dbPs .= "                    ⚡                    ⚡``n"
        dbPs .= "               ⚡      .============.      ⚡``n"
        dbPs .= "            ⚡       //              \\       ⚡``n"
        dbPs .= "          ⚡       //    $e[1;37mP O D E R$e[1;33m    \\       ⚡``n"
        dbPs .= "         ⚡       ||     $e[1;37m  T O T A L$e[1;33m   ||       ⚡``n"
        dbPs .= "          ⚡       \\   $e[1;37mCONCEDIDO!$e[1;33m   //       ⚡``n"
        dbPs .= "            ⚡       \\              //       ⚡``n"
        dbPs .= "               ⚡      ``============``      ⚡``n"
        dbPs .= "                    ⚡                    ⚡``n"
        dbPs .= "                          ⚡  ⚡  ⚡``n"
        dbPs .= "``n"
        dbPs .= "  $e[1;37m╔══════════════════════════════════════════════════════════╗$e[0m``n"
        dbPs .= "  $e[1;37m║                                                          ║$e[0m``n"
        dbPs .= "  $e[1;37m║     $e[1;33m⚡  Voce agora e  S U P E R   S A I Y A N !  ⚡$e[1;37m     ║$e[0m``n"
        dbPs .= "  $e[1;37m║                                                          ║$e[0m``n"
        dbPs .= "  $e[1;37m╚══════════════════════════════════════════════════════════╝$e[0m``n"
        dbPs .= "$e[0m" Chr(34) "; Start-Sleep -Milliseconds 3500; Clear-Host; }; "
        dbPs .= "if ($isAdmin) { "
        ; Admin = Super Saiyan
        dbPs .= "Write-Host " Chr(34) "$e[1;33m███████ ███████      ██$e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[1;33m██      ██           ██$e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[1;33m███████ ███████      ██$e[0m   $e[0;36mSUPER SAIYAN$e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[1;33m     ██      ██ ██   ██$e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[1;33m███████ ███████  █████ $e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[1;33m🐉 As 7 esferas foram reunidas! Shenlong, realize meu desejo!$e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[1;32mSeu desejo foi realizado. Voce agora tem poder TOTAL.$e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[0;36m🔗 $e[1;36mWindows$e[0m  $e[1;33m⚠ $e[0;33mPS $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)$e[0m  $e[1;35m◆ $e[0;35m$h$e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[0;37m``" Chr(34) "O poder vem do treinamento, nao do desejo.``" Chr(34) "$e[0m" Chr(34) "; "
        dbPs .= "Write-Host; "
        dbPs .= "Write-Host " Chr(34) "$e[0;36m🐉 Windows$e[0m | $e[1;33m⚠ PS$e[0m | $e[1;31m👤 $u@$h$e[0m | $e[0;36m⏰ $t$e[0m | $e[1;33m⚡ Super Saiyan$e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[1;33m📁 $loc$e[0m" Chr(34) "; "
        dbPs .= Chr(34) "$e[1;33m✔ ▶$e[0m " Chr(34)
        dbPs .= " } else { "
        ; Normal = Goku
        dbPs .= "Write-Host " Chr(34) "$e[1;38;5;208m ██████   ██████  ██   ██ ██   ██$e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[1;38;5;208m██       ██    ██ ██  ██  ██   ██$e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[1;38;5;208m██   ███ ██    ██ █████   ██   ██$e[0m   $e[0;36mDRAGON BALL$e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[1;38;5;208m██    ██ ██    ██ ██  ██  ██   ██$e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[1;38;5;208m ██████   ██████  ██   ██  █████ $e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[1;38;5;208mEu sou Goku! Vou treinar e ficar mais forte!$e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[0;36m🔗 $e[1;36mWindows$e[0m  $e[1;33m⚠ $e[0;33mPS $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)$e[0m  $e[1;35m◆ $e[0;35m$h$e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[0;37m``" Chr(34) "O poder vem do treinamento, nao do desejo.``" Chr(34) "$e[0m" Chr(34) "; "
        dbPs .= "Write-Host; "
        dbPs .= "Write-Host " Chr(34) "$e[0;36m🟠 Windows$e[0m | $e[1;33m⚠ PS$e[0m | $e[1;32m👤 $u@$h$e[0m | $e[0;36m⏰ $t$e[0m | $e[1;38;5;208m⭐ Goku$e[0m" Chr(34) "; "
        dbPs .= "Write-Host " Chr(34) "$e[1;38;5;208m📁 $loc$e[0m" Chr(34) "; "
        dbPs .= Chr(34) "$e[1;38;5;208m✔ ▶$e[0m " Chr(34)
        dbPs .= " } }"
        this.prompts.Push({
            id: "dragonball-ps",
            name: "🐉 Dragon Ball",
            shellType: "powershell",
            code: dbPs,
            builtin: true,
            favorite: false,
            lastUsed: ""
        })

        this.defaults["powershell"] := "minimal-ps"
        this.defaults["bash"] := "minimal-bash"
        this.Persist()
    }

    ; ── Toggle / Show / Hide ──

    static Toggle() {
        if (this.isVisible)
            this.Hide()
        else
            this.Show()
    }

    static Show() {
        if (this.isVisible) {
            this.Hide()
            return
        }

        if (ArrowMouse.IsEnabled()) {
            this.wasArrowMouseOn := true
            ArrowMouse.PauseForSwitcher()
        } else {
            this.wasArrowMouseOn := false
        }

        this.CreateGui()
        this.isVisible := true
    }

    static Hide() {
        try Hotkey("*Enter", "Off")
        if (this.gui) {
            this.gui.Destroy()
            this.gui := ""
        }
        this.isVisible := false

        if (this.wasArrowMouseOn) {
            this.wasArrowMouseOn := false
            ArrowMouse.Enable()
        }
    }

    ; ── GUI ──

    static CreateGui() {
        this.gui := Gui("+AlwaysOnTop +ToolWindow +Resize +OwnDialogs", "LazyWindow - Prompt Manager")
        this.gui.Opt("-DPIScale")
        this.gui.BackColor := "1a1a2e"

        ; Header instructions
        this.gui.SetFont("s11 cWhite", "Consolas")
        this.gui.AddText("x15 y10 w900 h25", "Digite: [nº][ação] + Enter     Ex: 1A=sessão  1W=persistir  2E=editar  3F=favorito")
        this.gui.AddText("x15 y35 w900 h25", "Ações: A=sessão  W=persistir  E=editar  D=deletar  F=favorito  S=default | N=novo")

        ; Input box
        this.gui.SetFont("s14 cWhite", "Consolas")
        this.gui.AddText("x15 y70 w20 h30", ">")
        this.inputBox := this.gui.AddEdit("x35 y65 w400 h30 Background0d1117 cWhite -Border")
        this.inputBox.OnEvent("Change", (*) => this.ApplyFilter())

        ; Shell filter
        this.gui.SetFont("s10 cWhite", "Consolas")
        this.gui.AddText("x470 y70 w50 h25", "Shell:")
        this.shellFilter := this.gui.AddDropDownList("x520 y65 w150 h200 Background0d1117", ["Todos", "PowerShell", "Bash"])
        this.shellFilter.OnEvent("Change", (*) => this.ApplyFilter())

        ; ListView
        this.gui.SetFont("s11 cWhite", "Consolas")
        this.listView := this.gui.AddListView("x15 y105 w960 h440 Background0d1117 c00ff88 -Hdr +Grid +ReadOnly", ["#", "★", "Nome", "Tipo", "Shell", "Preview", "Usado"])
        this.listView.ModifyCol(1, 40)
        this.listView.ModifyCol(2, 30)
        this.listView.ModifyCol(3, 150)
        this.listView.ModifyCol(4, 70)
        this.listView.ModifyCol(5, 100)
        this.listView.ModifyCol(6, 420)
        this.listView.ModifyCol(7, 80)

        ; Footer
        this.gui.SetFont("s10 cGray", "Segoe UI")
        this.footerText := this.gui.AddText("x15 y565 w900 h22", "")

        this.gui.OnEvent("Size", (guiObj, minMax, w, h) => this.OnResize(w, h))
        this.gui.OnEvent("Escape", (*) => this.Hide())
        this.gui.OnEvent("Close", (*) => this.Hide())

        ; Populate and show fullscreen
        this.filtered := this.prompts.Clone()
        this.PopulateList()
        this.ShowFullScreen()
        this.inputBox.Focus()

        Hotkey("*Enter", (*) => this.Execute(), "On")
    }

    static ShowFullScreen() {
        monitorNum := this.GetMonitorFromMouse()
        work := Monitor.GetWorkArea(monitorNum)
        if (!work) {
            this.gui.Show("Maximize")
            return
        }
        this.gui.Show("x" work.x " y" work.y " w" work.width " h" work.height)
        this.OnResize(work.width, work.height)
        WinMaximize("ahk_id " this.gui.Hwnd)
    }

    static OnResize(w, h) {
        if (this.listView)
            this.listView.Move(15, 105, w - 30, h - 160)
        if (this.footerText)
            this.footerText.Move(15, h - 35, w - 30, 22)
    }

    static GetMonitorFromMouse() {
        MouseGetPos(&mx, &my)
        count := MonitorGetCount()
        Loop count {
            MonitorGet(A_Index, &left, &top, &right, &bottom)
            if (mx >= left && mx < right && my >= top && my < bottom)
                return A_Index
        }
        return 1
    }

    static PopulateList() {
        this.listView.Delete()
        defPs := this.defaults.Has("powershell") ? this.defaults["powershell"] : ""
        defBash := this.defaults.Has("bash") ? this.defaults["bash"] : ""
        for idx, p in this.filtered {
            fav := p.favorite ? "★" : ""
            tipo := p.builtin ? "Built-in" : "Custom"
            shellLabel := (p.shellType = "powershell") ? "PowerShell" : "Bash"
            isDefault := (p.id = defPs || p.id = defBash)
            if (isDefault)
                shellLabel .= " ◄"
            preview := StrLen(p.code) > 60 ? SubStr(p.code, 1, 60) "..." : p.code
            preview := StrReplace(preview, "`n", " ")
            timeAgo := this.FormatTimeAgo(p.lastUsed)
            this.listView.Add(, idx, fav, p.name, tipo, shellLabel, preview, timeAgo)
        }
        total := this.prompts.Length
        shown := this.filtered.Length
        footer := shown " de " total " prompts"
        footer .= " | ★=favorito  Ctrl+F8=Quick-Apply  Ctrl+Alt+F8=Quick-Save"
        if (this.footerText)
            this.footerText.Value := footer
    }

    static ApplyFilter() {
        if (!this.inputBox)
            return
        try query := Trim(this.inputBox.Value)
        catch
            return

        shellSel := ""
        try shellSel := this.shellFilter.Text

        this.filtered := []
        queryLower := StrLower(query)

        ; If query matches action pattern, don't filter
        if (RegExMatch(query, "i)^(\d+)([AEDFNSW]?)$") || query = "N" || query = "n")
            query := ""

        for p in this.prompts {
            ; Shell filter
            if (shellSel = "PowerShell" && p.shellType != "powershell")
                continue
            if (shellSel = "Bash" && p.shellType != "bash")
                continue

            ; Text filter
            if (query != "") {
                searchText := StrLower(p.name . " " . p.code)
                if (!InStr(searchText, queryLower))
                    continue
            }
            this.filtered.Push(p)
        }
        this.PopulateList()
    }

    ; ── Execução por input ──

    static Execute() {
        if (!this.gui || !this.inputBox)
            return
        try text := Trim(this.inputBox.Value)
        catch
            return

        if (text = "") {
            this.Hide()
            return
        }

        ; Global actions
        if (text = "N" || text = "n") {
            this.AddPromptManual()
            return
        }

        ; Number + optional action letter
        if (!RegExMatch(text, "i)^(\d+)([AEDFNSW]?)$", &match))
            return

        num := Integer(match[1])
        action := StrUpper(match[2])

        if (num < 1 || num > this.filtered.Length)
            return

        prompt := this.filtered[num]

        switch action {
            case "", "A":
                this.ApplyToTerminal(prompt)
            case "W":
                this.PersistToProfile(prompt)
            case "E":
                this.EditPrompt(prompt)
            case "D":
                this.DeletePrompt(prompt)
            case "F":
                this.ToggleFavorite(prompt)
            case "S":
                this.SetDefault(prompt)
        }
    }

    ; ── Ações ──

    ; ── Send code to terminal via clipboard paste (avoids SendInput buffer overflow) ──
    static SendToTerminal(code) {
        savedClip := A_Clipboard
        A_Clipboard := " " code  ; leading space = no bash history
        Sleep(50)
        SendInput("^+v")  ; Ctrl+Shift+V = paste in Windows Terminal
        Sleep(100)
        SendInput("{Enter}")
        Sleep(50)
        A_Clipboard := savedClip
    }

    static ApplyToTerminal(prompt) {
        this.UpdateLastUsed(prompt)
        this.Hide()
        Sleep(100)

        shellType := this.DetectActiveShell()
        if (shellType = "") {
            MsgBox("Janela ativa não é Windows Terminal", "LazyWindow", "Icon!")
            return
        }

        ; Check compatibility
        if (prompt.shellType = "powershell" && shellType != "powershell") {
            MsgBox("Este prompt é para PowerShell, mas o terminal ativo é Bash.", "LazyWindow", "Icon!")
            return
        }
        if (prompt.shellType = "bash" && shellType != "bash") {
            MsgBox("Este prompt é para Bash, mas o terminal ativo é PowerShell.", "LazyWindow", "Icon!")
            return
        }

        this.SendToTerminal(prompt.code)
        ToolTip("Prompt aplicado: " prompt.name)
        SetTimer(() => ToolTip(), -2000)
    }

    static PersistToProfile(prompt) {
        this.UpdateLastUsed(prompt)
        this.Hide()
        Sleep(100)

        shellType := this.DetectActiveShell()
        if (shellType = "") {
            MsgBox("Janela ativa não é Windows Terminal", "LazyWindow", "Icon!")
            return
        }

        ; Check compatibility
        if (prompt.shellType = "powershell" && shellType != "powershell") {
            MsgBox("Este prompt é para PowerShell, mas o terminal ativo é Bash.", "LazyWindow", "Icon!")
            return
        }
        if (prompt.shellType = "bash" && shellType != "bash") {
            MsgBox("Este prompt é para Bash, mas o terminal ativo é PowerShell.", "LazyWindow", "Icon!")
            return
        }

        if (shellType = "powershell") {
            this.PersistPowerShell(prompt)
        } else {
            ; Ask target for bash
            KeyWait("Enter")
            Sleep(100)
            choice := InputBox("Persistir prompt em:`n`n1. ~/.bashrc (usuário atual)`n2. /root/.bashrc (root)`n3. Ambos`n`nDigite 1, 2 ou 3:", "Persistir Prompt", "w350 h200")
            if (choice.Result != "OK")
                return
            val := Trim(choice.Value)
            if (val = "1" || val = "3")
                this.PersistBash(prompt, false)
            if (val = "2" || val = "3") {
                if (val = "3")
                    Sleep(2000)  ; wait for user persist to finish
                this.PersistBash(prompt, true)
            }
        }

        ; Also apply to current session
        Sleep(1500)  ; wait for persist command to finish
        this.SendToTerminal(prompt.code)
        ToolTip("Prompt persistido e aplicado: " prompt.name)
        SetTimer(() => ToolTip(), -2500)
    }

    static PersistPowerShell(prompt) {
        ; Build a PowerShell command that writes the prompt function to $PROFILE
        ; Strategy: Remove existing prompt function, append new one, then dot-source
        code := prompt.code
        ; Escape single quotes for PowerShell here-string
        codeEscaped := StrReplace(code, "'", "''")

        ; Command: remove old LazyWindow prompt, append new, source
        cmd := "(Get-Content $PROFILE -ErrorAction SilentlyContinue | Where-Object { $_ -notmatch '^function prompt' -and $_ -notmatch '^# LazyWindow' }) | Set-Content $PROFILE -ErrorAction SilentlyContinue; "
        cmd .= "Add-Content $PROFILE '# LazyWindow Prompt'; "
        cmd .= "Add-Content $PROFILE '" codeEscaped "'; "
        cmd .= ". $PROFILE"

        this.SendToTerminal(cmd)
    }

    static PersistBash(prompt, asRoot) {
        code := prompt.code

        ; Write code to a temp file (no quoting issues)
        tempFile := A_Temp "\lw_prompt.tmp"
        try FileDelete(tempFile)
        FileAppend(code "`n", tempFile, "UTF-8-RAW")

        ; Convert Windows temp path to WSL /mnt/c/... format
        drive := SubStr(tempFile, 1, 1)
        rest := SubStr(tempFile, 3)
        rest := StrReplace(rest, "\", "/")
        wslPath := "/mnt/" StrLower(drive) rest

        ; Build sed patterns to clean old LazyWindow prompts
        sedPattern := "/^export PS1=/d;/^# LazyWindow/d;/^prompt_dragonball/d;/^PROMPT_COMMAND=prompt_dragonball/d;/^prompt_starwars/d;/^PROMPT_COMMAND=prompt_starwars/d;/^set +H/d"

        if (asRoot) {
            cmd := "sudo sed -i '" sedPattern "' /root/.bashrc && echo '# LazyWindow Prompt' | sudo tee -a /root/.bashrc > /dev/null && cat '" wslPath "' | sudo tee -a /root/.bashrc > /dev/null"
        } else {
            cmd := "sed -i '" sedPattern "' ~/.bashrc && echo '# LazyWindow Prompt' >> ~/.bashrc && cat '" wslPath "' >> ~/.bashrc && source ~/.bashrc"
        }

        this.SendToTerminal(cmd)
    }

    static QuickApply() {
        shellType := this.DetectActiveShell()
        if (shellType = "") {
            ToolTip("Janela ativa não é Windows Terminal")
            SetTimer(() => ToolTip(), -2000)
            return
        }

        ; Find favorite or default for this shellType
        target := ""

        ; First try favorite
        for p in this.prompts {
            if (p.favorite && p.shellType = shellType) {
                target := p
                break
            }
        }

        ; Then try default
        if (target = "") {
            defId := this.defaults.Has(shellType) ? this.defaults[shellType] : ""
            if (defId != "") {
                for p in this.prompts {
                    if (p.id = defId) {
                        target := p
                        break
                    }
                }
            }
        }

        ; Then try most recently used
        if (target = "") {
            latest := ""
            for p in this.prompts {
                if (p.shellType = shellType && p.lastUsed != "") {
                    if (latest = "" || p.lastUsed > latest.lastUsed)
                        latest := p
                }
            }
            target := latest
        }

        if (target = "") {
            ToolTip("Nenhum prompt configurado para " shellType)
            SetTimer(() => ToolTip(), -2000)
            return
        }

        this.UpdateLastUsed(target)
        this.SendToTerminal(target.code)
        ToolTip("Prompt aplicado: " target.name)
        SetTimer(() => ToolTip(), -2000)
    }

    static QuickSave() {
        shellType := this.DetectActiveShell()
        if (shellType = "") {
            ToolTip("Janela ativa não é Windows Terminal")
            SetTimer(() => ToolTip(), -2000)
            return
        }

        ; Capture current prompt
        savedClip := A_Clipboard
        A_Clipboard := ""

        if (shellType = "powershell") {
            SendInput("{Text} (Get-Command prompt).Definition | clip")
            SendInput("{Enter}")
        } else {
            SendInput("{Text} echo " Chr(34) "$PS1" Chr(34) " | clip.exe")
            SendInput("{Enter}")
        }

        success := ClipWait(3, 1)
        if (!success || A_Clipboard = "") {
            A_Clipboard := savedClip
            ToolTip("Não foi possível capturar o prompt")
            SetTimer(() => ToolTip(), -2500)
            return
        }

        capturedCode := Trim(A_Clipboard, " `t`r`n")
        A_Clipboard := savedClip

        if (capturedCode = "") {
            ToolTip("Prompt capturado vazio")
            SetTimer(() => ToolTip(), -2000)
            return
        }

        ; Wrap captured code
        if (shellType = "powershell") {
            ; Wrap in function prompt { ... }
            if (!InStr(capturedCode, "function prompt"))
                capturedCode := "function prompt { " capturedCode " }"
        } else {
            ; Wrap in export PS1='...'
            if (!InStr(capturedCode, "export PS1"))
                capturedCode := "export PS1='" capturedCode "'"
        }

        KeyWait("Enter")
        Sleep(100)
        nameInput := InputBox("Nome para o prompt salvo:", "Salvar Prompt", "w350 h130")
        if (nameInput.Result != "OK" || Trim(nameInput.Value) = "")
            return

        name := Trim(nameInput.Value)
        id := "custom-" A_TickCount
        now := FormatTime(, "yyyy-MM-ddTHH:mm:ss")

        this.prompts.Push({
            id: id,
            name: name,
            shellType: shellType,
            code: capturedCode,
            builtin: false,
            favorite: false,
            lastUsed: now
        })
        this.Persist()
        ToolTip("Prompt salvo: " name)
        SetTimer(() => ToolTip(), -2000)
    }

    static AddPromptManual() {
        this.Hide()
        KeyWait("Enter")
        Sleep(100)

        nameInput := InputBox("Nome do prompt:", "Novo Prompt", "w350 h130")
        if (nameInput.Result != "OK" || Trim(nameInput.Value) = "")
            return
        name := Trim(nameInput.Value)

        ; Ask shell type
        shellInput := InputBox("Tipo de shell:`n1. PowerShell`n2. Bash`n`nDigite 1 ou 2:", "Shell", "w300 h180")
        if (shellInput.Result != "OK")
            return
        shellType := (Trim(shellInput.Value) = "2") ? "bash" : "powershell"

        ; Ask code
        hint := (shellType = "powershell")
            ? "Cole o código do prompt:`nEx: function prompt { `"$($PWD)> `" }"
            : "Cole o código do prompt:`nEx: export PS1='\w\$ '"
        codeInput := InputBox(hint, "Código do Prompt", "w600 h200")
        if (codeInput.Result != "OK" || Trim(codeInput.Value) = "")
            return

        code := Trim(codeInput.Value)
        id := "custom-" A_TickCount
        now := FormatTime(, "yyyy-MM-ddTHH:mm:ss")

        this.prompts.Push({
            id: id,
            name: name,
            shellType: shellType,
            code: code,
            builtin: false,
            favorite: false,
            lastUsed: ""
        })
        this.Persist()
        this.Show()
    }

    static EditPrompt(prompt) {
        this.Hide()
        KeyWait("Enter")
        Sleep(100)

        codeInput := InputBox("Editar código do prompt '" prompt.name "':", "Editar Prompt", "w600 h200", prompt.code)
        if (codeInput.Result != "OK") {
            this.Show()
            return
        }

        newCode := Trim(codeInput.Value)
        if (newCode != "")
            prompt.code := newCode
        this.Persist()
        this.Show()
    }

    static DeletePrompt(prompt) {
        if (prompt.builtin) {
            ToolTip("Prompts built-in não podem ser deletados")
            SetTimer(() => ToolTip(), -2000)
            if (this.inputBox) {
                this.inputBox.Value := ""
                this.ApplyFilter()
            }
            return
        }

        idx := 0
        for i, p in this.prompts {
            if (p.id = prompt.id) {
                idx := i
                break
            }
        }
        if (idx > 0) {
            this.prompts.RemoveAt(idx)
            this.Persist()
            if (this.inputBox) {
                this.inputBox.Value := ""
                this.ApplyFilter()
            }
            ToolTip("Deletado: " prompt.name)
            SetTimer(() => ToolTip(), -1500)
        }
    }

    static ToggleFavorite(prompt) {
        prompt.favorite := !prompt.favorite
        this.Persist()
        if (this.inputBox) {
            this.inputBox.Value := ""
            this.ApplyFilter()
        }
        label := prompt.favorite ? "★ Favorito" : "Removido favorito"
        ToolTip(label ": " prompt.name)
        SetTimer(() => ToolTip(), -1500)
    }

    static SetDefault(prompt) {
        this.defaults[prompt.shellType] := prompt.id
        this.Persist()
        if (this.inputBox) {
            this.inputBox.Value := ""
            this.ApplyFilter()
        }
        shellLabel := (prompt.shellType = "powershell") ? "PowerShell" : "Bash"
        ToolTip("Default " shellLabel ": " prompt.name)
        SetTimer(() => ToolTip(), -1500)
    }

    static UpdateLastUsed(prompt) {
        prompt.lastUsed := FormatTime(, "yyyy-MM-ddTHH:mm:ss")
        this.Persist()
    }

    ; ── Detecção de shell ──

    static DetectActiveShell() {
        try {
            processName := WinGetProcessName("A")
        } catch {
            return ""
        }

        if (processName != "WindowsTerminal.exe")
            return ""

        title := WinGetTitle("A")
        titleLower := StrLower(title)

        ; Check PowerShell first (higher priority)
        psKeywords := ["powershell", "pwsh", "ps "]
        for kw in psKeywords {
            if (InStr(titleLower, kw))
                return "powershell"
        }

        ; Then check WSL/bash
        wslKeywords := ["ubuntu", "debian", "fedora", "suse", "kali", "arch", "alpine", "wsl", "linux"]
        for kw in wslKeywords {
            if (InStr(titleLower, kw))
                return "bash"
        }

        ; Default to powershell for Windows Terminal
        return "powershell"
    }

    ; ── Persistência ──

    static Persist() {
        if (!DirExist(this.configDir))
            DirCreate(this.configDir)

        ; Only save custom prompts and favorites/defaults — built-ins are always reloaded from code
        json := '{"prompts": [`n'
        customPrompts := []
        for p in this.prompts
            if (!p.builtin)
                customPrompts.Push(p)

        for idx, p in customPrompts {
            json .= '    {'
            json .= '"id": "' this.EscapeJson(p.id) '", '
            json .= '"name": "' this.EscapeJson(p.name) '", '
            json .= '"shellType": "' this.EscapeJson(p.shellType) '", '
            json .= '"code": "' this.EscapeJson(p.code) '", '
            json .= '"builtin": false, '
            json .= '"favorite": ' (p.favorite ? "true" : "false") ', '
            json .= '"lastUsed": "' this.EscapeJson(p.lastUsed) '"'
            json .= '}'
            if (idx < customPrompts.Length)
                json .= ','
            json .= '`n'
        }
        json .= '],`n"defaults": {'

        first := true
        for key, val in this.defaults {
            if (!first)
                json .= ', '
            json .= '"' this.EscapeJson(key) '": "' this.EscapeJson(val) '"'
            first := false
        }
        json .= '}}'

        try FileDelete(this.configPath)
        FileAppend(json, this.configPath, "UTF-8")
    }

    static Load() {
        this.prompts := []
        this.defaults := Map()

        if (!FileExist(this.configPath))
            return

        try content := FileRead(this.configPath, "UTF-8")
        catch
            return

        if (content = "")
            return

        ; Parse prompts array
        arrStart := InStr(content, '"prompts"')
        if (!arrStart)
            return

        bracketStart := InStr(content, "[", , arrStart)
        if (!bracketStart)
            return

        ; Find matching ]
        depth := 0
        bracketEnd := 0
        pos := bracketStart
        Loop StrLen(content) - bracketStart + 1 {
            ch := SubStr(content, pos, 1)
            if (ch = "[")
                depth++
            else if (ch = "]")
                depth--
            if (depth = 0) {
                bracketEnd := pos
                break
            }
            pos++
        }
        if (bracketEnd = 0)
            return

        listContent := SubStr(content, bracketStart, bracketEnd - bracketStart + 1)

        ; Parse each prompt object (respecting string boundaries for code with {})
        objects := this.ParseJsonObjects(listContent)
        for obj in objects {
            id := this.ExtractJsonField(obj, "id")
            name := this.ExtractJsonField(obj, "name")
            shellType := this.ExtractJsonField(obj, "shellType")
            code := this.ExtractJsonField(obj, "code")
            lastUsed := this.ExtractJsonField(obj, "lastUsed")

            builtin := false
            if (RegExMatch(obj, '"builtin"\s*:\s*(true|false)', &bm))
                builtin := (bm[1] = "true")

            favorite := false
            if (RegExMatch(obj, '"favorite"\s*:\s*(true|false)', &fm))
                favorite := (fm[1] = "true")

            if (id != "" && name != "") {
                this.prompts.Push({
                    id: id,
                    name: name,
                    shellType: shellType,
                    code: this.UnescapeJson(code),
                    builtin: builtin,
                    favorite: favorite,
                    lastUsed: lastUsed
                })
            }
        }

        ; Parse defaults
        defStart := InStr(content, '"defaults"')
        if (defStart) {
            defBrace := InStr(content, "{", , defStart)
            if (defBrace) {
                defEnd := InStr(content, "}", , defBrace)
                if (defEnd) {
                    defContent := SubStr(content, defBrace, defEnd - defBrace + 1)
                    defPos := 1
                    while (defPos := RegExMatch(defContent, '"(\w+)"\s*:\s*"([^"]*)"', &dm, defPos)) {
                        this.defaults[dm[1]] := dm[2]
                        defPos += StrLen(dm[0])
                    }
                }
            }
        }
    }

    ; Parse JSON array content into individual object strings, respecting string boundaries
    ; (needed because prompt code fields contain { } chars that break naive regex)
    static ParseJsonObjects(content) {
        objects := []
        pos := 1
        len := StrLen(content)
        while (pos <= len) {
            objStart := InStr(content, "{", , pos)
            if (!objStart)
                break
            objEnd := this.FindMatchingBrace(content, objStart)
            if (!objEnd)
                break
            objects.Push(SubStr(content, objStart, objEnd - objStart + 1))
            pos := objEnd + 1
        }
        return objects
    }

    ; Find the closing } that matches the { at position start, skipping chars inside strings
    static FindMatchingBrace(content, start) {
        depth := 0
        inString := false
        pos := start
        len := StrLen(content)
        while (pos <= len) {
            ch := SubStr(content, pos, 1)
            if (inString) {
                if (ch = "\") {
                    pos += 2
                    continue
                }
                if (ch = '"')
                    inString := false
            } else {
                if (ch = '"')
                    inString := true
                else if (ch = "{")
                    depth++
                else if (ch = "}") {
                    depth--
                    if (depth = 0)
                        return pos
                }
            }
            pos++
        }
        return 0
    }

    static ExtractJsonField(obj, field) {
        if (RegExMatch(obj, '"' field '"\s*:\s*"((?:[^"\\]|\\.)*)"', &m))
            return m[1]
        return ""
    }

    static EscapeJson(str) {
        str := StrReplace(str, "\", "\\")
        str := StrReplace(str, '"', '\"')
        str := StrReplace(str, "`n", "\n")
        str := StrReplace(str, "`r", "\r")
        str := StrReplace(str, "`t", "\t")
        return str
    }

    static UnescapeJson(str) {
        str := StrReplace(str, "\n", "`n")
        str := StrReplace(str, "\r", "`r")
        str := StrReplace(str, "\t", "`t")
        str := StrReplace(str, '\"', '"')
        str := StrReplace(str, "\\", "\")
        return str
    }

    ; ── Utils ──

    static FormatTimeAgo(dateStr) {
        if (dateStr = "")
            return "-"
        try {
            now := FormatTime(, "yyyyMMddHHmmss")
            then := StrReplace(StrReplace(StrReplace(dateStr, "-"), "T"), ":")
            diff := DateDiff(now, then, "Minutes")
            if (diff < 1)
                return "agora"
            if (diff < 60)
                return diff "min"
            hours := diff // 60
            if (hours < 24)
                return hours "h"
            days := hours // 24
            if (days < 7)
                return days "d"
            weeks := days // 7
            if (weeks < 5)
                return weeks "sem"
            months := days // 30
            return months "mes"
        } catch {
            return "-"
        }
    }
}
