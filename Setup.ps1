#-----[0. VERSION & PRE-CHECKS]-----
$currentVersion = "v1.1.1"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host " [!] ERROR: This toolkit requires PowerShell 7+. You are currently running version $($PSVersionTable.PSVersion.Major)." -ForegroundColor Red
    Write-Host " [!] Please install PowerShell 7 from https://aka.ms/powershell and try again." -ForegroundColor Yellow
    exit
}

# --- [1. DYNAMIC PATHS] ---
$baseDir = Join-Path $HOME "Documents\PowerShell\Scripts"
$funcDir = Join-Path $baseDir "Functions"
$menuScriptPath = Join-Path $baseDir "Menu.ps1"
$baseUrl = "https://raw.githubusercontent.com/padou-dev/Powershell-Toolkit/main/Functions/"
$setupUrl = "https://raw.githubusercontent.com/padou-dev/Powershell-Toolkit/main/Setup.ps1"

Write-Host "`n--- Starting Master Environment Setup ($currentVersion) ---" -ForegroundColor Cyan

# --- [2. Administrator Check] ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script as an Administrator to ensure modules can be installed."
    return
}

# --- [3. PRE-FLIGHT INTERNET CHECK] ---
Write-Host "[*] Verifying Cloud Connection..." -ForegroundColor Gray
if (-not (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet)) {
    Write-Host " [!] ERROR: No internet connection detected. Setup/Sync aborted." -ForegroundColor Red
    return
}

# --- [4. Dependency Check] ---
if (!(Get-Module -ListAvailable Terminal-Icons)) {
    Write-Host "[!] Terminal-Icons not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -AllowClobber
}

# --- [5. Function Sync Logic] ---
if (!(Test-Path $funcDir)) { New-Item -Path $funcDir -ItemType Directory -Force }

# Updated list including your new sysinfo tool
$functionNames = @("mass_rename.ps1", "space_to_dots.ps1", "hash_ls.ps1", "get_sysinfo.ps1")

foreach ($funcName in $functionNames) {
    $destPath = Join-Path $funcDir $funcName
    Write-Host "[*] Syncing $funcName from GitHub..." -ForegroundColor Gray
    
    try {
        Invoke-WebRequest -Uri ($baseUrl + $funcName) -OutFile $destPath -ErrorAction Stop
    } catch {
        Write-Host " [!] Failed to sync $funcName. Skipping..." -ForegroundColor Yellow
        if (Test-Path $destPath) { Remove-Item $destPath } # Cleanup partials
    }
}
Write-Host "[+] Toolkit functions synchronized in $funcDir" -ForegroundColor Green

# --- [6. Generate Menu.ps1] ---
$menuContent = @"
`$toolkitPath = "$funcDir"
`$toolkitScripts = Get-ChildItem -Path `$toolkitPath -Filter *.ps1
`$repoUrl = "$setupUrl"
`$version = "$currentVersion"

Clear-Host
Write-Host "=========================================" -ForegroundColor Green
Write-Host " TOOLKIT: `$version | USER: `$env:USERNAME" -ForegroundColor Cyan
Write-Host " CURRENT FOLDER: `$((Get-Location).Path)" -ForegroundColor Gray
Write-Host "=========================================" -ForegroundColor Green

if (Get-Module -Name Terminal-Icons) {
    Get-ChildItem | Format-TerminalIcons | Out-String | Write-Host
} else {
    Get-ChildItem | Format-Table -AutoSize | Out-String | Write-Host
}

Write-Host "=========================================" -ForegroundColor Green
Write-Host "         AVAILABLE FUNCTIONS             " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Green

for (`$i = 0; `$i -lt `$toolkitScripts.Count; `$i++) {
    Write-Host (" [`$(`$i + 1)] " + `$toolkitScripts[`$i].BaseName) -ForegroundColor Yellow
}
Write-Host "-----------------------------------------" -ForegroundColor DarkGray
Write-Host " [U] Update Toolkit" -ForegroundColor Cyan
Write-Host " [Q] Quit" -ForegroundColor Red
Write-Host "=========================================" -ForegroundColor Green

`$selection = Read-Host "`nEnter selection"

if (`$selection -eq 'u' -or `$selection -eq 'U') {
    Write-Host "[*] Checking Connectivity..." -ForegroundColor Cyan
    if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet) {
        `$setupPath = Join-Path "$baseDir" "Setup.ps1"
        Invoke-WebRequest -Uri `$repoUrl -OutFile `$setupPath -ErrorAction Stop
        & `$setupPath
    } else {
        Write-Host "[!] No Internet. Update Aborted." -ForegroundColor Red
        Pause
    }
    return
}

if (`$selection -eq 'q' -or `$selection -eq 'Q') { return }

if (`$selection -match '^\d+`$' -and [int]`$selection -le `$toolkitScripts.Count) {
    `$selectedFile = `$toolkitScripts[[int]`$selection - 1]
    . `$selectedFile.FullName
    & `$selectedFile.BaseName
}
"@
Set-Content -Path $menuScriptPath -Value $menuContent -Force

# --- [7. Update Profile] ---
$profileContent = @"
Import-Module -Name Terminal-Icons
Import-Module PSReadLine
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
`$functionsPath = "$funcDir"
if (Test-Path `$functionsPath) { Get-ChildItem `$functionsPath -Filter *.ps1 | ForEach-Object { . `$_.FullName } }
Set-Alias -Name menu -Value "$menuScriptPath"
"@
$profileDir = Split-Path $PROFILE
if (!(Test-Path $profileDir)) { New-Item -Path $profileDir -ItemType Directory -Force }
Set-Content -Path $PROFILE -Value $profileContent -Force

# --- [8. TERMINAL CUSTOMIZATION - HARDENED V2] ---
Write-Host "[*] Configuring Windows Terminal Profiles..." -ForegroundColor Gray

$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $settingsPath) {
    try {
        $settingsJson = Get-Content $settingsPath -Raw | ConvertFrom-Json -ErrorAction Stop
        
        # 1. Ensure the 'schemes' array exists
        if ($null -eq $settingsJson.schemes) {
            $settingsJson | Add-Member -MemberType NoteProperty -Name "schemes" -Value @()
        }

        # 2. Add Catppuccin Mocha if it doesn't exist
        $schemeName = "Catppuccin Mocha"
        if ($null -eq ($settingsJson.schemes | Where-Object { $_.name -eq $schemeName })) {
            $catppuccin = [PSCustomObject]@{
                name       = $schemeName
                background = "#1E1E2E"
                foreground = "#CDD6F4"
                black      = "#45475A"; red = "#F38BA8"; green = "#A6E3A1"; yellow = "#F9E2AF"
                blue       = "#89B4FA"; purple = "#CBA6F7"; cyan = "#94E2D5"; white = "#BAC2DE"
            }
            $settingsJson.schemes += $catppuccin
            Write-Host "[+] Injected $schemeName Scheme." -ForegroundColor Green
        }

        # 3. Add "PowerShell Toolkit" Profile
        $profileName = "PowerShell Toolkit"
        if ($null -eq ($settingsJson.profiles.list | Where-Object { $_.name -eq $profileName })) {
            $toolkitProfile = [PSCustomObject]@{
                name        = $profileName
                commandline = "pwsh.exe -NoExit -Command `"menu`""
                font        = [PSCustomObject]@{ face = "JetBrainsMono NF" }
                colorScheme = $schemeName
                useAcrylic  = $true
                acrylicOpacity = 0.85
            }
            $settingsJson.profiles.list += $toolkitProfile
            Write-Host "[+] Added '$profileName' Profile." -ForegroundColor Green
        }

        # 4. Save with high depth and UTF8 to ensure Terminal reads it correctly
        $settingsJson | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding utf8
        Write-Host "[!] Terminal settings updated successfully." -ForegroundColor Green
    } catch {
        Write-Host " [!] Error parsing Terminal settings: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host " [!] Windows Terminal settings not found." -ForegroundColor Yellow
}

Write-Host "`n[+++] SETUP COMPLETE! ($currentVersion)" -ForegroundColor Green
Write-Host "Restart PowerShell or Open Windows Terminal to see your new 'PowerShell Toolkit' profile." -ForegroundColor Yellow