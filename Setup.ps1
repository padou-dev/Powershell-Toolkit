#-----[0. DETERMINE POWERSHELL VERSION/WARnING]-----
# Check for PowerShell 7+
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host " [!] ERROR: This toolkit requires PowerShell 7+. You are currently running version $($PSVersionTable.PSVersion.Major)." -ForegroundColor Red
    Write-Host " [!] Please install PowerShell 7 from https://aka.ms/powershell and try again." -ForegroundColor Yellow
    exit
}
# --- [1. DYNAMIC PATHS] ---
# $HOME ensures portability for any user on the team
$baseDir = Join-Path $HOME "Documents\PowerShell\Scripts"
$funcDir = Join-Path $baseDir "Functions"
$menuScriptPath = Join-Path $baseDir "Menu.ps1"

Write-Host "`n--- Starting Master Environment Setup ---" -ForegroundColor Cyan

# --- [2. Administrator Check] ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script as an Administrator to ensure modules can be installed."
    return
}

# --- [3. Dependency Check & Visual Requirements] ---
if (!(Get-Module -ListAvailable Terminal-Icons)) {
    Write-Host "[!] Terminal-Icons not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -AllowClobber
}

Write-Host "`n*********************************************************" -ForegroundColor Yellow
Write-Host " [IMPORTANT] VISUAL SETUP" -ForegroundColor White -BackgroundColor Red
Write-Host " 1. Download/Install a Nerd Font from: nerdfonts.com" -ForegroundColor Gray
Write-Host " 2. In Terminal Settings, set Font Face to that Nerd Font." -ForegroundColor Gray
Write-Host "*********************************************************`n" -ForegroundColor Yellow
Pause

# --- [4. Folder & Function Creation] ---
if (!(Test-Path $funcDir)) { 
    New-Item -Path $funcDir -ItemType Directory -Force 
}

# Define and create Function 1: mass_rename
$massRenameContent = @"
function mass_rename {
    `$oldText = Read-Host "Enter the part of the filename you want to rename"
    `$newText = Read-Host "Enter what you want to rename it to"
    if ([string]::IsNullOrWhiteSpace(`$oldText)) { return }
    `$files = Get-ChildItem -File | Where-Object { `$_.Name -like "*`$oldText*" }
    if (-not `$files) { Write-Host "No matching files found." -ForegroundColor Yellow; return }
    Write-Host "`nPreview:" -ForegroundColor Cyan
    foreach (`$file in `$files) {
        `$newName = `$file.Name -replace [regex]::Escape(`$oldText), `$newText
        Write-Host "`$(`$file.Name) → `$newName"
    }
    if ((Read-Host "`nProceed with rename? (y/n)") -ne 'y') { return }
    `$files | Rename-Item -NewName { `$_.Name -replace [regex]::Escape(`$oldText), `$newText }
}
"@

# Define and create Function 2: space_to_dots
$spaceToDotsContent = @"
function space_to_dots {
    Get-ChildItem | Rename-Item -NewName { `$_.Name -replace " ", "." }
    Write-Host "Spaces converted to dots." -ForegroundColor Green
}
"@

Set-Content -Path (Join-Path $funcDir "mass_rename.ps1") -Value $massRenameContent -Force
Set-Content -Path (Join-Path $funcDir "space_to_dots.ps1") -Value $spaceToDotsContent -Force
Write-Host "[+] Toolkit functions generated in $funcDir" -ForegroundColor Green

# --- [5. Generate Menu.ps1] ---
$menuContent = @"
`$toolkitPath = "$funcDir"
`$toolkitScripts = Get-ChildItem -Path `$toolkitPath -Filter *.ps1
`$repoUrl = "https://raw.githubusercontent.com/padou-dev/Powershell-Toolkit/main/Setup.ps1"

Clear-Host
Write-Host "=========================================" -ForegroundColor Green
Write-Host " CURRENT FOLDER: `$((Get-Location).Path)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Green

if (Get-Module -Name Terminal-Icons) {
    Get-ChildItem | Format-TerminalIcons | Out-String | Write-Host
} else {
    Get-ChildItem | Format-Table -AutoSize | Out-String | Write-Host
}

Write-Host "=========================================" -ForegroundColor Green
Write-Host "        AVAILABLE TOOLKIT FUNCTIONS       " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Green

for (`$i = 0; `$i -lt `$toolkitScripts.Count; `$i++) {
    Write-Host (" [`$(`$i + 1)] " + `$toolkitScripts[`$i].BaseName) -ForegroundColor Yellow
}
Write-Host "-----------------------------------------" -ForegroundColor DarkGray
Write-Host " [U] Update Toolkit from GitHub" -ForegroundColor Cyan
Write-Host " [Q] Quit" -ForegroundColor Red
Write-Host "=========================================" -ForegroundColor Green

`$selection = Read-Host "`nEnter selection"

# --- Handle Update ---
if (`$selection -eq 'u' -or `$selection -eq 'U') {
    Write-Host "[*] Downloading latest Setup.ps1..." -ForegroundColor Cyan
    try {
        `$setupPath = Join-Path "$baseDir" "Setup.ps1"
        Invoke-WebRequest -Uri `$repoUrl -OutFile `$setupPath -ErrorAction Stop
        Write-Host "[+] Download complete. Re-running setup..." -ForegroundColor Green
        & `$setupPath
        return
    } catch {
        Write-Host "[!] Update failed: `$($_.Exception.Message)" -ForegroundColor Red
        Pause
        return
    }
}

if (`$selection -eq 'q' -or `$selection -eq 'Q') { return }

if (`$selection -match '^\d+`$' -and [int]`$selection -le `$toolkitScripts.Count) {
    `$selectedFile = `$toolkitScripts[[int]`$selection - 1]
    . `$selectedFile.FullName
    & `$selectedFile.BaseName
}
"@
Set-Content -Path $menuScriptPath -Value $menuContent -Force

# --- [6. Update Profile] ---
$profileContent = @"
Import-Module -Name Terminal-Icons
Import-Module PSReadLine
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

`$functionsPath = "$funcDir"
if (Test-Path `$functionsPath) {
    Get-ChildItem `$functionsPath -Filter *.ps1 | ForEach-Object { . `$_.FullName }
}

Set-Alias -Name menu -Value "$menuScriptPath"
"@

# Targets the correct $PROFILE for the current pwsh session
$profileDir = Split-Path $PROFILE
if (!(Test-Path $profileDir)) { New-Item -Path $profileDir -ItemType Directory -Force }
Set-Content -Path $PROFILE -Value $profileContent -Force

# --- [7. Post-Installation Instructions] ---
Write-Host "`n[+++] SETUP COMPLETE!" -ForegroundColor Green
Write-Host "Please RESTART your PowerShell window to enable the 'menu' command." -ForegroundColor Cyan
Write-Host "*********************************************************" -ForegroundColor Yellow

# --- [8. INTERACTIVE TERMINAL CUSTOMIZATION] ---
Write-Host "`n--- Optional: Windows Terminal Customization ---" -ForegroundColor Cyan
$installThemes = Read-Host "Would you like to install the custom color schemes (Catppuccin, CyberPunk, etc.)? (y/n)"
$applyOpacity = Read-Host "Would you like to apply 92% opacity to your terminal profiles? (y/n)"

if ($installThemes -eq 'y' -or $applyOpacity -eq 'y') {
    $terminalPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    if (Test-Path $terminalPath) {
        # Create a backup before modifying JSON
        Copy-Item $terminalPath "$terminalPath.bak" -Force
        $settings = Get-Content $terminalPath -Raw | ConvertFrom-Json

        # --- Handle Themes ---
        if ($installThemes -eq 'y') {
            Write-Host "[*] Injecting Color Schemes..." -ForegroundColor Gray
            $mySchemes = @(
                @{ name = "Apple System Colors"; background = "#1E1E1E"; foreground = "#FFFFFF"; black = "#1A1A1A"; blue = "#0869CB"; brightBlack = "#464646"; brightBlue = "#0A84FF"; brightCyan = "#76D6FF"; brightGreen = "#32D74B"; brightPurple = "#BF5AF2"; brightRed = "#FF453A"; brightWhite = "#FFFFFF"; brightYellow = "#FFD60A"; cursorColor = "#98989D"; cyan = "#479EC2"; green = "#26A439"; purple = "#9647BF"; red = "#CC372E"; selectionBackground = "#3F638B"; white = "#98989D"; yellow = "#CDAC08" },
                @{ name = "Catppuccin Mocha"; background = "#1E1E2E"; foreground = "#CDD6F4"; black = "#45475A"; blue = "#89B4FA"; brightBlack = "#585B70"; brightBlue = "#89B4FA"; brightCyan = "#94E2D5"; brightGreen = "#A6E3A1"; brightPurple = "#F5C2E7"; brightRed = "#F38BA8"; brightWhite = "#A6ADC8"; brightYellow = "#F9E2AF"; cursorColor = "#F5E0DC"; cyan = "#94E2D5"; green = "#A6E3A1"; purple = "#F5C2E7"; red = "#F38BA8"; selectionBackground = "#585B70"; white = "#BAC2DE"; yellow = "#F9E2AF" },
                @{ name = "CyberPunk2077"; background = "#272932"; foreground = "#E455AE"; black = "#272932"; blue = "#9381FF"; brightBlack = "#7B8097"; brightBlue = "#37EBF3"; brightCyan = "#37EBF3"; brightGreen = "#40FFE9"; brightPurple = "#CB1DCD"; brightRed = "#C71515"; brightWhite = "#C1DEFF"; brightYellow = "#FFF955"; cursorColor = "#FDF500"; cyan = "#00D0DB"; green = "#1AC5B0"; purple = "#742D8B"; red = "#710000"; selectionBackground = "#742D8B"; white = "#D1C5C0"; yellow = "#FDF500" },
                @{ name = "Dracula+"; background = "#212121"; foreground = "#F8F8F2"; black = "#21222C"; blue = "#82AAFF"; brightBlack = "#545454"; brightBlue = "#D6ACFF"; brightCyan = "#A4FFFF"; brightGreen = "#69FF94"; brightPurple = "#FF92DF"; brightRed = "#FF6E6E"; brightWhite = "#F8F8F2"; brightYellow = "#FFCB6B"; cursorColor = "#ECEFF4"; cyan = "#8BE9FD"; green = "#50FA7B"; purple = "#C792EA"; red = "#FF5555"; selectionBackground = "#F8F8F2"; white = "#F8F8F2"; yellow = "#FFCB6B" },
                @{ name = "Flatland"; background = "#1D1F21"; foreground = "#B8DBEF"; black = "#1D1D19"; blue = "#5096BE"; brightBlack = "#1D1D19"; brightBlue = "#61B9D0"; brightCyan = "#D63865"; brightGreen = "#A7D42C"; brightPurple = "#695ABC"; brightRed = "#D22A24"; brightWhite = "#FFFFFF"; brightYellow = "#FF8949"; cursorColor = "#708284"; cyan = "#D63865"; green = "#9FD364"; purple = "#695ABC"; red = "#F18339"; selectionBackground = "#2B2A24"; white = "#FFFFFF"; yellow = "#F4EF6D" },
                @{ name = "GitHub Dark"; background = "#101216"; foreground = "#8B949E"; black = "#000000"; blue = "#6CA4F8"; brightBlack = "#4D4D4D"; brightBlue = "#6CA4F8"; brightCyan = "#2B7489"; brightGreen = "#56D364"; brightPurple = "#DB61A2"; brightRed = "#F78166"; brightWhite = "#FFFFFF"; brightYellow = "#E3B341"; cursorColor = "#C9D1D9"; cyan = "#2B7489"; green = "#56D364"; purple = "#DB61A2"; red = "#F78166"; selectionBackground = "#3B5070"; white = "#FFFFFF"; yellow = "#E3B341" },
                @{ name = "Hacktober"; background = "#141414"; foreground = "#C9C9C9"; black = "#191918"; blue = "#206EC5"; brightBlack = "#2C2B2A"; brightBlue = "#5389C5"; brightCyan = "#EBC587"; brightGreen = "#42824A"; brightPurple = "#E795A5"; brightRed = "#B33323"; brightWhite = "#FFFFFF"; brightYellow = "#C75A22"; cursorColor = "#C9C9C9"; cyan = "#AC9166"; green = "#587744"; purple = "#864651"; red = "#B34538"; selectionBackground = "#141414"; white = "#F1EEE7"; yellow = "#D08949" },
                @{ name = "Obsidian"; background = "#283033"; foreground = "#CDCDCD"; black = "#000000"; blue = "#3A9BDB"; brightBlack = "#555555"; brightBlue = "#A1D7FF"; brightCyan = "#55FFFF"; brightGreen = "#93C863"; brightPurple = "#FF55FF"; brightRed = "#FF0003"; brightWhite = "#FFFFFF"; brightYellow = "#FEF874"; cursorColor = "#C0CAD0"; cyan = "#00BBBB"; green = "#00BB00"; purple = "#BB00BB"; red = "#A60001"; selectionBackground = "#3E4C4F"; white = "#BBBBBB"; yellow = "#FECD22" }
            )

            if ($null -eq $settings.schemes) { $settings.schemes = @() }
            foreach ($scheme in $mySchemes) {
                if ($scheme.name -notin $settings.schemes.name) {
                    $settings.schemes += $scheme
                    Write-Host "  [+] Added: $($scheme.name)" -ForegroundColor Gray
                }
            }
        }

        # --- Handle Opacity ---
        if ($applyOpacity -eq 'y') {
            Write-Host "[*] Applying 92% Opacity..." -ForegroundColor Gray
            if ($null -eq $settings.profiles.defaults) { $settings.profiles.defaults = @{} }
            $settings.profiles.defaults.opacity = 92
            $settings.profiles.defaults.useAcrylic = $false
        }

        # Save changes
        $settings | ConvertTo-Json -Depth 10 | Set-Content $terminalPath -Encoding utf8
        Write-Host "[+] Terminal settings updated." -ForegroundColor Green
    }
} else {
    Write-Host "[!] Skipping terminal customization." -ForegroundColor Yellow
}