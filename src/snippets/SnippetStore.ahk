#Requires AutoHotkey v2.0

class SnippetStore {
    static snippets := []
    static categories := []
    static loaded := false
    
    static Init() {
        if (this.loaded)
            return
        this.LoadBuiltInSnippets()
        this.loaded := true
    }
    
    static LoadBuiltInSnippets() {
        this.categories := [
            {name: "SOLID", subcategories: ["SRP", "OCP", "LSP", "ISP", "DIP"]},
            {name: "Clean Code", subcategories: ["Functions", "Guards", "Refactoring"]},
            {name: "Design Patterns", subcategories: ["Creational", "Behavioral"]},
            {name: "TypeScript", subcategories: ["Basics", "Async", "React"]},
            {name: "Python", subcategories: ["Classes", "Functions"]},
            {name: "SQL", subcategories: ["Queries", "Advanced"]},
            {name: "PowerShell", subcategories: ["Control Flow", "API"]},
            {name: "Bash", subcategories: ["Control Flow", "Functions", "DevOps"]},
            {name: "Go", subcategories: ["Types", "Concurrency", "Web"]},
            {name: "Windows", subcategories: ["Settings", "System", "Network", "Devices", "Apps", "Shell"]}
        ]
        
        this.snippets := []
        
        ; === WINDOWS ms-settings ===
        this.AddSnippet("DisplaySettings", "Windows", "Settings",
            "Display configuration",
            ["windows"], [],
            this.CodeWinDisplay())
        
        this.AddSnippet("SoundSettings", "Windows", "Devices",
            "Sound and audio devices",
            ["windows"], [],
            this.CodeWinSound())
        
        this.AddSnippet("NetworkWifi", "Windows", "Network",
            "WiFi and network settings",
            ["windows"], [],
            this.CodeWinNetwork())
        
        this.AddSnippet("BluetoothDevices", "Windows", "Devices",
            "Bluetooth settings",
            ["windows"], [],
            this.CodeWinBluetooth())
        
        this.AddSnippet("AppsFeatures", "Windows", "System",
            "Installed apps and features",
            ["windows"], [],
            this.CodeWinApps())
        
        this.AddSnippet("WindowsUpdate", "Windows", "System",
            "Windows Update",
            ["windows"], [],
            this.CodeWinUpdate())
        
        this.AddSnippet("StorageSettings", "Windows", "System",
            "Storage and disk usage",
            ["windows"], [],
            this.CodeWinStorage())
        
        this.AddSnippet("PowerSleep", "Windows", "System",
            "Power and sleep settings",
            ["windows"], [],
            this.CodeWinPower())
        
        this.AddSnippet("AllMsSettings", "Windows", "Settings",
            "Complete list of ms-settings URIs",
            ["windows"], [],
            this.CodeWinAllSettings())
        
        this.AddSnippet("MsStore", "Windows", "Apps",
            "Microsoft Store URIs",
            ["windows"], [],
            this.CodeWinStore())
        
        this.AddSnippet("MsApps", "Windows", "Apps",
            "Built-in Windows apps URIs",
            ["windows"], [],
            this.CodeWinAppsUri())
        
        this.AddSnippet("ShellCommands", "Windows", "Shell",
            "Shell: folder shortcuts",
            ["windows"], [],
            this.CodeWinShell())
        
        this.AddSnippet("ControlPanel", "Windows", "Shell",
            "Control Panel shortcuts",
            ["windows"], [],
            this.CodeWinControlPanel())
        
        this.AddSnippet("RunCommands", "Windows", "Shell",
            "Useful Run dialog commands",
            ["windows"], [],
            this.CodeWinRunCommands())
        
        ; === SOLID ===
        this.AddSnippet("SingleResponsibility", "SOLID", "SRP",
            "Class with single responsibility",
            ["typescript", "python"], ["ClassName"],
            this.CodeSolidSRP())
        
        this.AddSnippet("OpenClosed", "SOLID", "OCP",
            "Open for extension, closed for modification",
            ["typescript", "python"], ["ServiceName"],
            this.CodeSolidOCP())
        
        this.AddSnippet("LiskovSubstitution", "SOLID", "LSP",
            "Subtypes must be substitutable",
            ["typescript", "python"], ["BaseName"],
            this.CodeSolidLSP())
        
        this.AddSnippet("InterfaceSegregation", "SOLID", "ISP",
            "Small, focused interfaces",
            ["typescript", "python"], ["EntityName"],
            this.CodeSolidISP())
        
        this.AddSnippet("DependencyInversion", "SOLID", "DIP",
            "Depend on abstractions, not concretions",
            ["typescript", "python"], ["ServiceName"],
            this.CodeSolidDIP())
        
        ; === Clean Code ===
        this.AddSnippet("GuardClause", "Clean Code", "Guards",
            "Early return pattern",
            ["typescript", "python"], ["FunctionName"],
            this.CodeCleanGuard())
        
        this.AddSnippet("ExtractMethod", "Clean Code", "Refactoring",
            "Extract small focused methods",
            ["typescript", "python"], ["ClassName"],
            this.CodeCleanExtract())
        
        this.AddSnippet("NullObject", "Clean Code", "Refactoring",
            "Null Object pattern",
            ["typescript", "python"], ["ObjectName"],
            this.CodeCleanNullObject())
        
        this.AddSnippet("Constants", "Clean Code", "Refactoring",
            "Replace magic numbers with constants",
            ["typescript", "python"], [],
            this.CodeCleanConstants())
        
        ; Design Patterns
        this.AddSnippet("Singleton", "Design Patterns", "Creational", 
            "Ensures a class has only one instance",
            ["typescript", "python", "go"], ["ClassName"],
            this.CodeSingleton())
        
        this.AddSnippet("Factory", "Design Patterns", "Creational",
            "Creates objects without specifying exact class",
            ["typescript", "python"], ["ProductName"],
            this.CodeFactory())
        
        this.AddSnippet("Observer", "Design Patterns", "Behavioral",
            "Defines one-to-many dependency",
            ["typescript", "python"], ["SubjectName"],
            this.CodeObserver())
        
        ; TypeScript
        this.AddSnippet("Interface", "TypeScript", "Basics",
            "TypeScript interface",
            ["typescript"], ["InterfaceName"],
            this.CodeTsInterface())
        
        this.AddSnippet("AsyncAwait", "TypeScript", "Async",
            "Async function with error handling",
            ["typescript"], ["FunctionName"],
            this.CodeTsAsync())
        
        this.AddSnippet("UseState", "TypeScript", "React",
            "React useState hook",
            ["typescript"], ["stateName"],
            this.CodeTsUseState())
        
        ; Python
        this.AddSnippet("Class", "Python", "Classes",
            "Python class with __init__",
            ["python"], ["ClassName"],
            this.CodePyClass())
        
        this.AddSnippet("Dataclass", "Python", "Classes",
            "Python dataclass",
            ["python"], ["ClassName"],
            this.CodePyDataclass())
        
        ; SQL
        this.AddSnippet("SelectJoin", "SQL", "Queries",
            "SELECT with JOIN",
            ["sql"], ["table1", "table2"],
            this.CodeSqlJoin())
        
        this.AddSnippet("CTE", "SQL", "Advanced",
            "Common Table Expression",
            ["sql"], ["cteName"],
            this.CodeSqlCte())
        
        ; PowerShell
        this.AddSnippet("TryCatch", "PowerShell", "Control Flow",
            "PowerShell try-catch-finally",
            ["powershell"], [],
            this.CodePsTryCatch())
        
        this.AddSnippet("RestApi", "PowerShell", "API",
            "REST API call",
            ["powershell"], ["url"],
            this.CodePsRest())
        
        ; Bash
        this.AddSnippet("Function", "Bash", "Functions",
            "Bash function",
            ["bash"], ["functionName"],
            this.CodeBashFunction())
        
        this.AddSnippet("AwsCli", "Bash", "DevOps",
            "AWS CLI commands",
            ["bash"], ["bucket"],
            this.CodeBashAws())
        
        ; Go
        this.AddSnippet("Struct", "Go", "Types",
            "Go struct with methods",
            ["go"], ["StructName"],
            this.CodeGoStruct())
        
        this.AddSnippet("HttpHandler", "Go", "Web",
            "Go HTTP handler",
            ["go"], ["HandlerName"],
            this.CodeGoHttp())
    }
    
    static AddSnippet(name, category, subcategory, description, languages, placeholders, codeMap) {
        this.snippets.Push({
            name: name,
            category: category,
            subcategory: subcategory,
            description: description,
            languages: languages,
            placeholders: placeholders,
            code: codeMap
        })
    }
    
    ; === CODE TEMPLATES (using simple string concat) ===
    
    ; === Windows ms-settings ===
    
    static CodeWinDisplay() {
        m := Map()
        m["windows"] := "# Display Settings`n"
            . "ms-settings:display                    # Main display`n"
            . "ms-settings:display-advanced           # Advanced display`n"
            . "ms-settings:nightlight                 # Night light`n"
            . "ms-settings:screenrotation             # Screen rotation`n"
            . "ms-settings:display-advancedgraphics   # Graphics settings"
        return m
    }
    
    static CodeWinSound() {
        m := Map()
        m["windows"] := "# Sound Settings`n"
            . "ms-settings:sound                      # Sound main`n"
            . "ms-settings:sound-devices              # Sound devices`n"
            . "ms-settings:apps-volume                # App volume`n"
            . "ms-settings:easeofaccess-audio         # Audio accessibility"
        return m
    }
    
    static CodeWinNetwork() {
        m := Map()
        m["windows"] := "# Network Settings`n"
            . "ms-settings:network                    # Network status`n"
            . "ms-settings:network-wifi               # WiFi`n"
            . "ms-settings:network-ethernet           # Ethernet`n"
            . "ms-settings:network-vpn                # VPN`n"
            . "ms-settings:network-proxy              # Proxy`n"
            . "ms-settings:network-airplanemode       # Airplane mode`n"
            . "ms-settings:network-mobilehotspot      # Mobile hotspot"
        return m
    }
    
    static CodeWinBluetooth() {
        m := Map()
        m["windows"] := "# Bluetooth Settings`n"
            . "ms-settings:bluetooth                  # Bluetooth main`n"
            . "ms-settings:connecteddevices           # Connected devices`n"
            . "ms-settings:printers                   # Printers`n"
            . "ms-settings:devices-touchpad           # Touchpad`n"
            . "ms-settings:mousetouchpad              # Mouse settings"
        return m
    }
    
    static CodeWinApps() {
        m := Map()
        m["windows"] := "# Apps Settings`n"
            . "ms-settings:appsfeatures               # Apps & features`n"
            . "ms-settings:defaultapps                # Default apps`n"
            . "ms-settings:optionalfeatures           # Optional features`n"
            . "ms-settings:startupapps                # Startup apps`n"
            . "ms-settings:maps                       # Offline maps"
        return m
    }
    
    static CodeWinUpdate() {
        m := Map()
        m["windows"] := "# Windows Update`n"
            . "ms-settings:windowsupdate              # Windows Update`n"
            . "ms-settings:windowsupdate-history      # Update history`n"
            . "ms-settings:windowsupdate-options      # Advanced options`n"
            . "ms-settings:windowsupdate-activehours  # Active hours`n"
            . "ms-settings:windowsdefender            # Windows Security"
        return m
    }
    
    static CodeWinStorage() {
        m := Map()
        m["windows"] := "# Storage Settings`n"
            . "ms-settings:storagesense               # Storage sense`n"
            . "ms-settings:savelocations              # Save locations`n"
            . "ms-settings:disksandvolumes            # Disks & volumes`n"
            . "ms-settings:backup                     # Backup"
        return m
    }
    
    static CodeWinPower() {
        m := Map()
        m["windows"] := "# Power Settings`n"
            . "ms-settings:powersleep                 # Power & sleep`n"
            . "ms-settings:batterysaver               # Battery saver`n"
            . "ms-settings:batterysaver-settings      # Battery settings"
        return m
    }
    
    static CodeWinAllSettings() {
        m := Map()
        m["windows"] := "# === SYSTEM ===`n"
            . "ms-settings:display`n"
            . "ms-settings:sound`n"
            . "ms-settings:notifications`n"
            . "ms-settings:powersleep`n"
            . "ms-settings:batterysaver`n"
            . "ms-settings:storagesense`n"
            . "ms-settings:multitasking`n"
            . "ms-settings:project`n"
            . "ms-settings:clipboard`n"
            . "ms-settings:remotedesktop`n"
            . "ms-settings:about`n`n"
            . "# === DEVICES ===`n"
            . "ms-settings:bluetooth`n"
            . "ms-settings:printers`n"
            . "ms-settings:mousetouchpad`n"
            . "ms-settings:typing`n"
            . "ms-settings:pen`n"
            . "ms-settings:autoplay`n"
            . "ms-settings:usb`n`n"
            . "# === NETWORK ===`n"
            . "ms-settings:network-status`n"
            . "ms-settings:network-wifi`n"
            . "ms-settings:network-ethernet`n"
            . "ms-settings:network-dialup`n"
            . "ms-settings:network-vpn`n"
            . "ms-settings:network-proxy`n`n"
            . "# === PERSONALIZATION ===`n"
            . "ms-settings:personalization-background`n"
            . "ms-settings:colors`n"
            . "ms-settings:lockscreen`n"
            . "ms-settings:themes`n"
            . "ms-settings:fonts`n"
            . "ms-settings:taskbar`n`n"
            . "# === ACCOUNTS ===`n"
            . "ms-settings:yourinfo`n"
            . "ms-settings:emailandaccounts`n"
            . "ms-settings:signinoptions`n"
            . "ms-settings:workplace`n"
            . "ms-settings:otherusers`n"
            . "ms-settings:sync`n`n"
            . "# === TIME & LANGUAGE ===`n"
            . "ms-settings:dateandtime`n"
            . "ms-settings:regionlanguage`n"
            . "ms-settings:speech`n`n"
            . "# === GAMING ===`n"
            . "ms-settings:gaming-gamebar`n"
            . "ms-settings:gaming-gamedvr`n"
            . "ms-settings:gaming-gamemode`n`n"
            . "# === ACCESSIBILITY ===`n"
            . "ms-settings:easeofaccess-display`n"
            . "ms-settings:easeofaccess-cursor`n"
            . "ms-settings:easeofaccess-magnifier`n"
            . "ms-settings:easeofaccess-colorfilter`n"
            . "ms-settings:easeofaccess-highcontrast`n"
            . "ms-settings:easeofaccess-narrator`n"
            . "ms-settings:easeofaccess-keyboard`n"
            . "ms-settings:easeofaccess-mouse`n`n"
            . "# === PRIVACY ===`n"
            . "ms-settings:privacy`n"
            . "ms-settings:privacy-location`n"
            . "ms-settings:privacy-webcam`n"
            . "ms-settings:privacy-microphone`n"
            . "ms-settings:privacy-notifications`n"
            . "ms-settings:privacy-speechtyping`n`n"
            . "# === UPDATE & SECURITY ===`n"
            . "ms-settings:windowsupdate`n"
            . "ms-settings:windowsdefender`n"
            . "ms-settings:backup`n"
            . "ms-settings:troubleshoot`n"
            . "ms-settings:recovery`n"
            . "ms-settings:activation`n"
            . "ms-settings:findmydevice`n"
            . "ms-settings:developers"
        return m
    }
    
    static CodeWinStore() {
        m := Map()
        m["windows"] := "# Microsoft Store URIs`n"
            . "ms-windows-store:                      # Open Store`n"
            . "ms-windows-store:home                  # Store home`n"
            . "ms-windows-store:search?query=vscode  # Search app`n"
            . "ms-windows-store:pdp?PFN=PackageName  # App page`n"
            . "ms-windows-store:downloads            # Downloads`n"
            . "ms-windows-store:Settings             # Store settings`n"
            . "ms-windows-store:updates              # Update apps"
        return m
    }
    
    static CodeWinAppsUri() {
        m := Map()
        m["windows"] := "# Built-in Windows Apps`n"
            . "ms-clock:                              # Clock & alarms`n"
            . "ms-calculator:                         # Calculator`n"
            . "calculator:                            # Calculator (alt)`n"
            . "ms-photos:                             # Photos`n"
            . "ms-paint:                              # Paint`n"
            . "ms-screenclip:                         # Snipping Tool`n"
            . "ms-screensketch:                       # Snip & Sketch`n"
            . "ms-people:                             # People/Contacts`n"
            . "ms-cxh:                                # Feedback Hub`n"
            . "ms-contact-support:                    # Get Help`n"
            . "ms-gamebar:                            # Xbox Game Bar`n"
            . "ms-gamebarservices:                    # Game Bar Services`n"
            . "ms-actioncenter:                       # Action Center`n"
            . "ms-availablenetworks:                  # WiFi networks popup`n"
            . "microsoft-edge:                        # Microsoft Edge`n"
            . "microsoft-edge:https://google.com     # Edge with URL`n"
            . "mailto:                                # Default mail`n"
            . "mailto:user@email.com                  # Compose email"
        return m
    }
    
    static CodeWinShell() {
        m := Map()
        m["windows"] := "# Shell: Folder Shortcuts (use in Run or Explorer)`n"
            . "shell:startup                          # Startup folder`n"
            . "shell:common startup                   # All users startup`n"
            . "shell:sendto                           # SendTo folder`n"
            . "shell:recent                           # Recent files`n"
            . "shell:downloads                        # Downloads`n"
            . "shell:desktop                          # Desktop`n"
            . "shell:documents                        # Documents`n"
            . "shell:pictures                         # Pictures`n"
            . "shell:videos                           # Videos`n"
            . "shell:music                            # Music`n"
            . "shell:personal                         # Documents (alt)`n"
            . "shell:appsfolder                       # All apps`n"
            . "shell:programs                         # Start menu programs`n"
            . "shell:common programs                  # All users programs`n"
            . "shell:fonts                            # Fonts folder`n"
            . "shell:system                           # System32`n"
            . "shell:windows                          # Windows folder`n"
            . "shell:profile                          # User profile`n"
            . "shell:public                           # Public folder`n"
            . "shell:local appdata                    # LocalAppData`n"
            . "shell:appdata                          # Roaming AppData`n"
            . "shell:programfiles                     # Program Files`n"
            . "shell:programfilesx86                  # Program Files x86`n"
            . "shell:recyclebinfolder                 # Recycle Bin"
        return m
    }
    
    static CodeWinControlPanel() {
        m := Map()
        m["windows"] := "# Control Panel Shortcuts`n"
            . "control                                # Control Panel`n"
            . "control admintools                     # Administrative Tools`n"
            . "control desktop                        # Personalization`n"
            . "control folders                        # File Explorer Options`n"
            . "control fonts                          # Fonts`n"
            . "control keyboard                       # Keyboard Properties`n"
            . "control mouse                          # Mouse Properties`n"
            . "control netconnections                 # Network Connections`n"
            . "control printers                       # Devices and Printers`n"
            . "control schedtasks                     # Task Scheduler`n"
            . "control userpasswords                  # User Accounts`n"
            . "control userpasswords2                 # Advanced User Accounts`n"
            . "control /name Microsoft.System         # System Properties`n"
            . "control /name Microsoft.DeviceManager  # Device Manager`n"
            . "control /name Microsoft.NetworkAndSharingCenter # Network Center"
        return m
    }
    
    static CodeWinRunCommands() {
        m := Map()
        m["windows"] := "# Useful Run Dialog Commands (Win+R)`n"
            . "# === SYSTEM TOOLS ===`n"
            . "cmd                                    # Command Prompt`n"
            . "powershell                             # PowerShell`n"
            . "wt                                     # Windows Terminal`n"
            . "taskmgr                                # Task Manager`n"
            . "resmon                                 # Resource Monitor`n"
            . "perfmon                                # Performance Monitor`n"
            . "msinfo32                               # System Information`n"
            . "dxdiag                                 # DirectX Diagnostics`n"
            . "devmgmt.msc                            # Device Manager`n"
            . "diskmgmt.msc                           # Disk Management`n"
            . "compmgmt.msc                           # Computer Management`n"
            . "services.msc                           # Services`n"
            . "eventvwr.msc                           # Event Viewer`n"
            . "gpedit.msc                             # Group Policy Editor`n"
            . "regedit                                # Registry Editor`n"
            . "msconfig                               # System Configuration`n"
            . "cleanmgr                               # Disk Cleanup`n"
            . "dfrgui                                 # Defragment and Optimize`n`n"
            . "# === NETWORK ===`n"
            . "ncpa.cpl                               # Network Connections`n"
            . "firewall.cpl                           # Windows Firewall`n"
            . "inetcpl.cpl                            # Internet Properties`n`n"
            . "# === DISPLAY & SOUND ===`n"
            . "desk.cpl                               # Display Settings`n"
            . "mmsys.cpl                              # Sound Settings`n"
            . "main.cpl                               # Mouse Properties`n`n"
            . "# === PROGRAMS ===`n"
            . "appwiz.cpl                             # Programs and Features`n"
            . "optionalfeatures                       # Windows Features`n"
            . "winver                                 # Windows Version`n"
            . "calc                                   # Calculator`n"
            . "notepad                                # Notepad`n"
            . "mspaint                                # Paint`n"
            . "snippingtool                           # Snipping Tool"
        return m
    }
    
    ; === SOLID Principles ===
    
    static CodeSolidSRP() {
        m := Map()
        m["typescript"] := "// Single Responsibility: Each class does ONE thing`n"
            . "class `${ClassName}Repository {`n"
            . "    async findById(id: string): Promise<`${ClassName}> {`n"
            . "        // Only handles data access`n"
            . "        return await db.query(id);`n"
            . "    }`n"
            . "}`n`n"
            . "class `${ClassName}Validator {`n"
            . "    validate(data: `${ClassName}): ValidationResult {`n"
            . "        // Only handles validation`n"
            . "        return { valid: true, errors: [] };`n"
            . "    }`n"
            . "}`n`n"
            . "class `${ClassName}Service {`n"
            . "    constructor(`n"
            . "        private repo: `${ClassName}Repository,`n"
            . "        private validator: `${ClassName}Validator`n"
            . "    ) {}`n"
            . "    // Orchestrates, doesn't implement details`n"
            . "}"
        m["python"] := "# Single Responsibility: Each class does ONE thing`n"
            . "class `${ClassName}Repository:`n"
            . "    def find_by_id(self, id: str) -> `${ClassName}:`n"
            . "        # Only handles data access`n"
            . "        return db.query(id)`n`n"
            . "class `${ClassName}Validator:`n"
            . "    def validate(self, data: `${ClassName}) -> ValidationResult:`n"
            . "        # Only handles validation`n"
            . "        return ValidationResult(valid=True, errors=[])`n`n"
            . "class `${ClassName}Service:`n"
            . "    def __init__(self, repo: `${ClassName}Repository, validator: `${ClassName}Validator):`n"
            . "        self.repo = repo`n"
            . "        self.validator = validator`n"
            . "    # Orchestrates, doesn't implement details"
        return m
    }
    
    static CodeSolidOCP() {
        m := Map()
        m["typescript"] := "// Open/Closed: Open for extension, closed for modification`n"
            . "interface `${ServiceName}Strategy {`n"
            . "    execute(data: any): Result;`n"
            . "}`n`n"
            . "class `${ServiceName}StrategyA implements `${ServiceName}Strategy {`n"
            . "    execute(data: any): Result {`n"
            . "        return { success: true };`n"
            . "    }`n"
            . "}`n`n"
            . "class `${ServiceName}StrategyB implements `${ServiceName}Strategy {`n"
            . "    execute(data: any): Result {`n"
            . "        return { success: true };`n"
            . "    }`n"
            . "}`n`n"
            . "// Add new strategies without modifying existing code`n"
            . "class `${ServiceName} {`n"
            . "    constructor(private strategy: `${ServiceName}Strategy) {}`n"
            . "    run(data: any): Result {`n"
            . "        return this.strategy.execute(data);`n"
            . "    }`n"
            . "}"
        m["python"] := "# Open/Closed: Open for extension, closed for modification`n"
            . "from abc import ABC, abstractmethod`n`n"
            . "class `${ServiceName}Strategy(ABC):`n"
            . "    @abstractmethod`n"
            . "    def execute(self, data) -> Result:`n"
            . "        pass`n`n"
            . "class `${ServiceName}StrategyA(`${ServiceName}Strategy):`n"
            . "    def execute(self, data) -> Result:`n"
            . "        return Result(success=True)`n`n"
            . "class `${ServiceName}StrategyB(`${ServiceName}Strategy):`n"
            . "    def execute(self, data) -> Result:`n"
            . "        return Result(success=True)`n`n"
            . "# Add new strategies without modifying existing code`n"
            . "class `${ServiceName}:`n"
            . "    def __init__(self, strategy: `${ServiceName}Strategy):`n"
            . "        self.strategy = strategy`n"
            . "    def run(self, data) -> Result:`n"
            . "        return self.strategy.execute(data)"
        return m
    }
    
    static CodeSolidLSP() {
        m := Map()
        m["typescript"] := "// Liskov Substitution: Subtypes must be substitutable`n"
            . "abstract class `${BaseName} {`n"
            . "    abstract process(): void;`n"
            . "}`n`n"
            . "class `${BaseName}TypeA extends `${BaseName} {`n"
            . "    process(): void {`n"
            . "        // Valid: fulfills the contract`n"
            . "        console.log('Processing A');`n"
            . "    }`n"
            . "}`n`n"
            . "class `${BaseName}TypeB extends `${BaseName} {`n"
            . "    process(): void {`n"
            . "        // Valid: fulfills the contract`n"
            . "        console.log('Processing B');`n"
            . "    }`n"
            . "}`n`n"
            . "// Any subtype can replace the base type`n"
            . "function handle(item: `${BaseName}): void {`n"
            . "    item.process(); // Works with any subtype`n"
            . "}"
        m["python"] := "# Liskov Substitution: Subtypes must be substitutable`n"
            . "from abc import ABC, abstractmethod`n`n"
            . "class `${BaseName}(ABC):`n"
            . "    @abstractmethod`n"
            . "    def process(self) -> None:`n"
            . "        pass`n`n"
            . "class `${BaseName}TypeA(`${BaseName}):`n"
            . "    def process(self) -> None:`n"
            . "        # Valid: fulfills the contract`n"
            . '        print("Processing A")`n`n'
            . "class `${BaseName}TypeB(`${BaseName}):`n"
            . "    def process(self) -> None:`n"
            . "        # Valid: fulfills the contract`n"
            . '        print("Processing B")`n`n'
            . "# Any subtype can replace the base type`n"
            . "def handle(item: `${BaseName}) -> None:`n"
            . "    item.process()  # Works with any subtype"
        return m
    }
    
    static CodeSolidISP() {
        m := Map()
        m["typescript"] := "// Interface Segregation: Small, focused interfaces`n"
            . "// BAD: Fat interface`n"
            . "// interface `${EntityName}Service {`n"
            . "//     create(); read(); update(); delete(); export(); import(); `n"
            . "// }`n`n"
            . "// GOOD: Segregated interfaces`n"
            . "interface `${EntityName}Reader {`n"
            . "    findById(id: string): `${EntityName};`n"
            . "    findAll(): `${EntityName}[];`n"
            . "}`n`n"
            . "interface `${EntityName}Writer {`n"
            . "    create(data: `${EntityName}): `${EntityName};`n"
            . "    update(id: string, data: `${EntityName}): `${EntityName};`n"
            . "    delete(id: string): void;`n"
            . "}`n`n"
            . "interface `${EntityName}Exporter {`n"
            . "    exportToCsv(): string;`n"
            . "    exportToJson(): string;`n"
            . "}`n`n"
            . "// Classes implement only what they need`n"
            . "class `${EntityName}ReadOnlyService implements `${EntityName}Reader {`n"
            . "    findById(id: string): `${EntityName} { /* */ }`n"
            . "    findAll(): `${EntityName}[] { /* */ }`n"
            . "}"
        m["python"] := "# Interface Segregation: Small, focused interfaces`n"
            . "from abc import ABC, abstractmethod`n"
            . "from typing import List`n`n"
            . "# GOOD: Segregated interfaces`n"
            . "class `${EntityName}Reader(ABC):`n"
            . "    @abstractmethod`n"
            . "    def find_by_id(self, id: str) -> `${EntityName}:`n"
            . "        pass`n"
            . "    @abstractmethod`n"
            . "    def find_all(self) -> List[`${EntityName}]:`n"
            . "        pass`n`n"
            . "class `${EntityName}Writer(ABC):`n"
            . "    @abstractmethod`n"
            . "    def create(self, data: `${EntityName}) -> `${EntityName}:`n"
            . "        pass`n"
            . "    @abstractmethod`n"
            . "    def delete(self, id: str) -> None:`n"
            . "        pass`n`n"
            . "# Classes implement only what they need`n"
            . "class `${EntityName}ReadOnlyService(`${EntityName}Reader):`n"
            . "    def find_by_id(self, id: str) -> `${EntityName}:`n"
            . "        pass`n"
            . "    def find_all(self) -> List[`${EntityName}]:`n"
            . "        pass"
        return m
    }
    
    static CodeSolidDIP() {
        m := Map()
        m["typescript"] := "// Dependency Inversion: Depend on abstractions`n"
            . "interface I`${ServiceName}Repository {`n"
            . "    save(data: any): Promise<void>;`n"
            . "    find(id: string): Promise<any>;`n"
            . "}`n`n"
            . "interface I`${ServiceName}Logger {`n"
            . "    log(message: string): void;`n"
            . "}`n`n"
            . "// High-level module depends on abstractions`n"
            . "class `${ServiceName} {`n"
            . "    constructor(`n"
            . "        private repository: I`${ServiceName}Repository,`n"
            . "        private logger: I`${ServiceName}Logger`n"
            . "    ) {}`n`n"
            . "    async process(id: string): Promise<void> {`n"
            . "        const data = await this.repository.find(id);`n"
            . '        this.logger.log(`Processing ${id}`);`n'
            . "    }`n"
            . "}`n`n"
            . "// Implementations can be swapped`n"
            . "const service = new `${ServiceName}(`n"
            . "    new PostgresRepository(),  // or MongoRepository`n"
            . "    new ConsoleLogger()         // or FileLogger`n"
            . ");"
        m["python"] := "# Dependency Inversion: Depend on abstractions`n"
            . "from abc import ABC, abstractmethod`n`n"
            . "class I`${ServiceName}Repository(ABC):`n"
            . "    @abstractmethod`n"
            . "    async def save(self, data) -> None:`n"
            . "        pass`n"
            . "    @abstractmethod`n"
            . "    async def find(self, id: str):`n"
            . "        pass`n`n"
            . "class I`${ServiceName}Logger(ABC):`n"
            . "    @abstractmethod`n"
            . "    def log(self, message: str) -> None:`n"
            . "        pass`n`n"
            . "# High-level module depends on abstractions`n"
            . "class `${ServiceName}:`n"
            . "    def __init__(self, repository: I`${ServiceName}Repository, logger: I`${ServiceName}Logger):`n"
            . "        self.repository = repository`n"
            . "        self.logger = logger`n`n"
            . "    async def process(self, id: str) -> None:`n"
            . "        data = await self.repository.find(id)`n"
            . '        self.logger.log(f"Processing {id}")`n`n'
            . "# Implementations can be swapped`n"
            . "service = `${ServiceName}(`n"
            . "    PostgresRepository(),  # or MongoRepository`n"
            . "    ConsoleLogger()         # or FileLogger`n"
            . ")"
        return m
    }
    
    ; === Clean Code ===
    
    static CodeCleanGuard() {
        m := Map()
        m["typescript"] := "// Guard Clauses: Early returns for cleaner code`n"
            . "function `${FunctionName}(user: User | null, data: Data | null): Result {`n"
            . "    // Guards at the top`n"
            . "    if (!user) {`n"
            . '        return { error: "User required" };`n'
            . "    }`n"
            . "    if (!data) {`n"
            . '        return { error: "Data required" };`n'
            . "    }`n"
            . "    if (!user.hasPermission) {`n"
            . '        return { error: "Permission denied" };`n'
            . "    }`n`n"
            . "    // Main logic (not nested)`n"
            . "    const result = processData(user, data);`n"
            . "    return { success: true, result };`n"
            . "}"
        m["python"] := "# Guard Clauses: Early returns for cleaner code`n"
            . "def `${FunctionName}(user: User | None, data: Data | None) -> Result:`n"
            . "    # Guards at the top`n"
            . "    if not user:`n"
            . '        return Result(error="User required")`n'
            . "    if not data:`n"
            . '        return Result(error="Data required")`n'
            . "    if not user.has_permission:`n"
            . '        return Result(error="Permission denied")`n`n'
            . "    # Main logic (not nested)`n"
            . "    result = process_data(user, data)`n"
            . "    return Result(success=True, result=result)"
        return m
    }
    
    static CodeCleanExtract() {
        m := Map()
        m["typescript"] := "// Extract Method: Small, focused functions`n"
            . "class `${ClassName} {`n"
            . "    // BAD: Long method doing too much`n"
            . "    // process() { validate; transform; save; notify; log; }`n`n"
            . "    // GOOD: Each step is a focused method`n"
            . "    async process(data: Data): Promise<Result> {`n"
            . "        const validated = this.validate(data);`n"
            . "        const transformed = this.transform(validated);`n"
            . "        const saved = await this.save(transformed);`n"
            . "        await this.notify(saved);`n"
            . "        return saved;`n"
            . "    }`n`n"
            . "    private validate(data: Data): ValidatedData {`n"
            . "        // Only validation logic`n"
            . "    }`n`n"
            . "    private transform(data: ValidatedData): TransformedData {`n"
            . "        // Only transformation logic`n"
            . "    }`n`n"
            . "    private async save(data: TransformedData): Promise<Result> {`n"
            . "        // Only persistence logic`n"
            . "    }`n`n"
            . "    private async notify(result: Result): Promise<void> {`n"
            . "        // Only notification logic`n"
            . "    }`n"
            . "}"
        m["python"] := "# Extract Method: Small, focused functions`n"
            . "class `${ClassName}:`n"
            . "    # BAD: Long method doing too much`n"
            . "    # def process(): validate; transform; save; notify; log`n`n"
            . "    # GOOD: Each step is a focused method`n"
            . "    async def process(self, data: Data) -> Result:`n"
            . "        validated = self._validate(data)`n"
            . "        transformed = self._transform(validated)`n"
            . "        saved = await self._save(transformed)`n"
            . "        await self._notify(saved)`n"
            . "        return saved`n`n"
            . "    def _validate(self, data: Data) -> ValidatedData:`n"
            . "        # Only validation logic`n"
            . "        pass`n`n"
            . "    def _transform(self, data: ValidatedData) -> TransformedData:`n"
            . "        # Only transformation logic`n"
            . "        pass`n`n"
            . "    async def _save(self, data: TransformedData) -> Result:`n"
            . "        # Only persistence logic`n"
            . "        pass`n`n"
            . "    async def _notify(self, result: Result) -> None:`n"
            . "        # Only notification logic`n"
            . "        pass"
        return m
    }
    
    static CodeCleanNullObject() {
        m := Map()
        m["typescript"] := "// Null Object: Avoid null checks everywhere`n"
            . "interface `${ObjectName} {`n"
            . "    getName(): string;`n"
            . "    execute(): void;`n"
            . "}`n`n"
            . "class Real`${ObjectName} implements `${ObjectName} {`n"
            . "    constructor(private name: string) {}`n"
            . "    getName(): string { return this.name; }`n"
            . "    execute(): void { /* real logic */ }`n"
            . "}`n`n"
            . "class Null`${ObjectName} implements `${ObjectName} {`n"
            . '    getName(): string { return "Unknown"; }`n'
            . "    execute(): void { /* do nothing */ }`n"
            . "}`n`n"
            . "// Usage: No null checks needed`n"
            . "function get`${ObjectName}(id: string): `${ObjectName} {`n"
            . "    const found = repository.find(id);`n"
            . "    return found ?? new Null`${ObjectName}();`n"
            . "}"
        m["python"] := "# Null Object: Avoid null checks everywhere`n"
            . "from abc import ABC, abstractmethod`n`n"
            . "class `${ObjectName}(ABC):`n"
            . "    @abstractmethod`n"
            . "    def get_name(self) -> str:`n"
            . "        pass`n"
            . "    @abstractmethod`n"
            . "    def execute(self) -> None:`n"
            . "        pass`n`n"
            . "class Real`${ObjectName}(`${ObjectName}):`n"
            . "    def __init__(self, name: str):`n"
            . "        self._name = name`n"
            . "    def get_name(self) -> str:`n"
            . "        return self._name`n"
            . "    def execute(self) -> None:`n"
            . "        # real logic`n"
            . "        pass`n`n"
            . "class Null`${ObjectName}(`${ObjectName}):`n"
            . "    def get_name(self) -> str:`n"
            . '        return "Unknown"`n'
            . "    def execute(self) -> None:`n"
            . "        pass  # do nothing`n`n"
            . "# Usage: No null checks needed`n"
            . "def get_`${ObjectName}(id: str) -> `${ObjectName}:`n"
            . "    found = repository.find(id)`n"
            . "    return found if found else Null`${ObjectName}()"
        return m
    }
    
    static CodeCleanConstants() {
        m := Map()
        m["typescript"] := "// Replace Magic Numbers with Named Constants`n"
            . "// BAD`n"
            . "// if (status === 1) { ... }`n"
            . "// if (age >= 18) { ... }`n"
            . "// setTimeout(() => {}, 86400000);`n`n"
            . "// GOOD`n"
            . "const enum Status {`n"
            . "    PENDING = 0,`n"
            . "    ACTIVE = 1,`n"
            . "    INACTIVE = 2,`n"
            . "}`n`n"
            . "const LEGAL_AGE = 18;`n"
            . "const ONE_DAY_MS = 24 * 60 * 60 * 1000;`n`n"
            . "if (status === Status.ACTIVE) {`n"
            . "    // Clear intent`n"
            . "}`n`n"
            . "if (age >= LEGAL_AGE) {`n"
            . "    // Clear intent`n"
            . "}`n`n"
            . "setTimeout(refresh, ONE_DAY_MS);"
        m["python"] := "# Replace Magic Numbers with Named Constants`n"
            . "from enum import Enum, auto`n`n"
            . "# BAD`n"
            . "# if status == 1: ...`n"
            . "# if age >= 18: ...`n`n"
            . "# GOOD`n"
            . "class Status(Enum):`n"
            . "    PENDING = auto()`n"
            . "    ACTIVE = auto()`n"
            . "    INACTIVE = auto()`n`n"
            . "LEGAL_AGE = 18`n"
            . "ONE_DAY_SECONDS = 24 * 60 * 60`n`n"
            . "if status == Status.ACTIVE:`n"
            . "    # Clear intent`n"
            . "    pass`n`n"
            . "if age >= LEGAL_AGE:`n"
            . "    # Clear intent`n"
            . "    pass"
        return m
    }
    
    static CodeSingleton() {
        m := Map()
        m["typescript"] := "class `${ClassName} {`n"
            . "    private static instance: `${ClassName};`n"
            . "    private constructor() {}`n"
            . "    public static getInstance(): `${ClassName} {`n"
            . "        if (!`${ClassName}.instance) {`n"
            . "            `${ClassName}.instance = new `${ClassName}();`n"
            . "        }`n"
            . "        return `${ClassName}.instance;`n"
            . "    }`n"
            . "}"
        m["python"] := "class `${ClassName}:`n"
            . "    _instance = None`n"
            . "    `n"
            . "    def __new__(cls):`n"
            . "        if cls._instance is None:`n"
            . "            cls._instance = super().__new__(cls)`n"
            . "        return cls._instance"
        m["go"] := "type `${ClassName} struct {}`n`n"
            . "var instance *`${ClassName}`n"
            . "var once sync.Once`n`n"
            . "func Get`${ClassName}() *`${ClassName} {`n"
            . "    once.Do(func() {`n"
            . "        instance = &`${ClassName}{}`n"
            . "    })`n"
            . "    return instance`n"
            . "}"
        return m
    }
    
    static CodeFactory() {
        m := Map()
        m["typescript"] := "interface `${ProductName} {`n"
            . "    operation(): string;`n"
            . "}`n`n"
            . "class Concrete`${ProductName}A implements `${ProductName} {`n"
            . "    operation(): string {`n"
            . '        return "Product A";`n'
            . "    }`n"
            . "}`n`n"
            . "class `${ProductName}Factory {`n"
            . "    static create(type: string): `${ProductName} {`n"
            . "        switch (type) {`n"
            . '            case "A": return new Concrete`${ProductName}A();`n'
            . '            default: throw new Error("Unknown type");`n'
            . "        }`n"
            . "    }`n"
            . "}"
        m["python"] := "from abc import ABC, abstractmethod`n`n"
            . "class `${ProductName}(ABC):`n"
            . "    @abstractmethod`n"
            . "    def operation(self) -> str:`n"
            . "        pass`n`n"
            . "class Concrete`${ProductName}A(`${ProductName}):`n"
            . "    def operation(self) -> str:`n"
            . '        return "Product A"`n`n'
            . "class `${ProductName}Factory:`n"
            . "    @staticmethod`n"
            . "    def create(product_type: str) -> `${ProductName}:`n"
            . '        if product_type == "A":`n'
            . "            return Concrete`${ProductName}A()`n"
            . '        raise ValueError(f"Unknown type: {product_type}")'
        return m
    }
    
    static CodeObserver() {
        m := Map()
        m["typescript"] := "interface Observer {`n"
            . "    update(data: any): void;`n"
            . "}`n`n"
            . "class `${SubjectName} {`n"
            . "    private observers: Observer[] = [];`n`n"
            . "    subscribe(observer: Observer): void {`n"
            . "        this.observers.push(observer);`n"
            . "    }`n`n"
            . "    notify(data: any): void {`n"
            . "        this.observers.forEach(o => o.update(data));`n"
            . "    }`n"
            . "}"
        m["python"] := "from abc import ABC, abstractmethod`n"
            . "from typing import List, Any`n`n"
            . "class Observer(ABC):`n"
            . "    @abstractmethod`n"
            . "    def update(self, data: Any) -> None:`n"
            . "        pass`n`n"
            . "class `${SubjectName}:`n"
            . "    def __init__(self):`n"
            . "        self._observers: List[Observer] = []`n`n"
            . "    def subscribe(self, observer: Observer) -> None:`n"
            . "        self._observers.append(observer)`n`n"
            . "    def notify(self, data: Any) -> None:`n"
            . "        for observer in self._observers:`n"
            . "            observer.update(data)"
        return m
    }
    
    static CodeTsInterface() {
        m := Map()
        m["typescript"] := "interface `${InterfaceName} {`n"
            . "    id: string;`n"
            . "    name: string;`n"
            . "    createdAt: Date;`n"
            . "    updatedAt?: Date;`n"
            . "}"
        return m
    }
    
    static CodeTsAsync() {
        m := Map()
        m["typescript"] := "async function `${FunctionName}(): Promise<void> {`n"
            . "    try {`n"
            . "        const result = await someAsyncOperation();`n"
            . "        console.log(result);`n"
            . "    } catch (error) {`n"
            . '        console.error("Error:", error);`n'
            . "        throw error;`n"
            . "    }`n"
            . "}"
        return m
    }
    
    static CodeTsUseState() {
        m := Map()
        m["typescript"] := 'const [`${stateName}, set`${StateName}] = useState<string>("");'
        return m
    }
    
    static CodePyClass() {
        m := Map()
        m["python"] := "class `${ClassName}:`n"
            . "    def __init__(self, name: str, value: int = 0):`n"
            . "        self.name = name`n"
            . "        self.value = value`n`n"
            . "    def __repr__(self) -> str:`n"
            . '        return f"`${ClassName}(name={self.name!r}, value={self.value})"'
        return m
    }
    
    static CodePyDataclass() {
        m := Map()
        m["python"] := "from dataclasses import dataclass, field`n"
            . "from typing import Optional`n"
            . "from datetime import datetime`n`n"
            . "@dataclass`n"
            . "class `${ClassName}:`n"
            . "    id: str`n"
            . "    name: str`n"
            . "    created_at: datetime = field(default_factory=datetime.now)`n"
            . "    metadata: Optional[dict] = None"
        return m
    }
    
    static CodeSqlJoin() {
        m := Map()
        m["sql"] := "SELECT `n"
            . "    t1.id,`n"
            . "    t1.name,`n"
            . "    t2.description`n"
            . "FROM `${table1} t1`n"
            . "INNER JOIN `${table2} t2 ON t1.id = t2.`${table1}_id`n"
            . "WHERE t1.active = true`n"
            . "ORDER BY t1.created_at DESC;"
        return m
    }
    
    static CodeSqlCte() {
        m := Map()
        m["sql"] := "WITH `${cteName} AS (`n"
            . "    SELECT `n"
            . "        id,`n"
            . "        name,`n"
            . "        ROW_NUMBER() OVER (PARTITION BY category ORDER BY created_at DESC) as rn`n"
            . "    FROM items`n"
            . ")`n"
            . "SELECT * FROM `${cteName}`n"
            . "WHERE rn = 1;"
        return m
    }
    
    static CodePsTryCatch() {
        m := Map()
        m["powershell"] := "try {`n"
            . "    # Your code here`n"
            . "    `$result = Get-Something`n"
            . "}`n"
            . "catch [System.Exception] {`n"
            . '    Write-Error "Error: `$(`$_.Exception.Message)"`n'
            . "    throw`n"
            . "}`n"
            . "finally {`n"
            . "    # Cleanup`n"
            . "}"
        return m
    }
    
    static CodePsRest() {
        m := Map()
        m["powershell"] := "`$headers = @{`n"
            . '    "Authorization" = "Bearer `$token"`n'
            . '    "Content-Type" = "application/json"`n'
            . "}`n`n"
            . "`$body = @{`n"
            . '    name = "value"`n'
            . "} | ConvertTo-Json`n`n"
            . '`$response = Invoke-RestMethod -Uri "`${url}" -Method POST -Headers `$headers -Body `$body'
        return m
    }
    
    static CodeBashFunction() {
        m := Map()
        m["bash"] := "`${functionName}() {`n"
            . '    local param1="`$1"`n'
            . '    local param2="`${2:-default}"`n`n'
            . '    if [ -z "`$param1" ]; then`n'
            . '        echo "Error: param1 required" >&2`n'
            . "        return 1`n"
            . "    fi`n`n"
            . '    echo "Processing: `$param1, `$param2"`n'
            . "    return 0`n"
            . "}"
        return m
    }
    
    static CodeBashAws() {
        m := Map()
        m["bash"] := "# List S3 buckets`n"
            . "aws s3 ls`n`n"
            . "# Copy to S3`n"
            . "aws s3 cp ./file.txt s3://`${bucket}/path/`n`n"
            . "# Describe EC2 instances`n"
            . 'aws ec2 describe-instances --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name}" --output table'
        return m
    }
    
    static CodeGoStruct() {
        m := Map()
        m["go"] := "type `${StructName} struct {`n"
            . '    ID        string    `json:"id"``n'
            . '    Name      string    `json:"name"``n'
            . '    CreatedAt time.Time `json:"created_at"``n'
            . "}`n`n"
            . "func New`${StructName}(name string) *`${StructName} {`n"
            . "    return &`${StructName}{`n"
            . "        ID:        uuid.New().String(),`n"
            . "        Name:      name,`n"
            . "        CreatedAt: time.Now(),`n"
            . "    }`n"
            . "}"
        return m
    }
    
    static CodeGoHttp() {
        m := Map()
        m["go"] := "func `${HandlerName}(w http.ResponseWriter, r *http.Request) {`n"
            . "    if r.Method != http.MethodPost {`n"
            . '        http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)`n'
            . "        return`n"
            . "    }`n`n"
            . "    var req RequestBody`n"
            . "    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {`n"
            . "        http.Error(w, err.Error(), http.StatusBadRequest)`n"
            . "        return`n"
            . "    }`n`n"
            . "    // Process request`n`n"
            . '    w.Header().Set("Content-Type", "application/json")`n'
            . '    json.NewEncoder(w).Encode(map[string]string{"status": "ok"})`n'
            . "}"
        return m
    }
    
    ; === QUERY METHODS ===
    
    static GetByCategory(category) {
        this.Init()
        filtered := []
        for snippet in this.snippets {
            if (snippet.category = category)
                filtered.Push(snippet)
        }
        return filtered
    }
    
    static GetByLanguage(lang) {
        this.Init()
        filtered := []
        langLower := StrLower(lang)
        for snippet in this.snippets {
            for snippetLang in snippet.languages {
                if (StrLower(snippetLang) = langLower) {
                    filtered.Push(snippet)
                    break
                }
            }
        }
        return filtered
    }
    
    static Search(query) {
        this.Init()
        filtered := []
        queryLower := StrLower(query)
        for snippet in this.snippets {
            if (InStr(StrLower(snippet.name), queryLower) || InStr(StrLower(snippet.description), queryLower))
                filtered.Push(snippet)
        }
        return filtered
    }
    
    static GetCategories() {
        this.Init()
        return this.categories
    }
    
    static GetAll() {
        this.Init()
        return this.snippets
    }
}
