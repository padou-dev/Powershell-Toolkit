#-----[0. DETERMINE POWERSHELL VERSION/WARNING]-----
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

# --- [4. Folder & Function Sync] ---
if (!(Test-Path $funcDir)) { New-Item -Path $funcDir -ItemType Directory -Force }

# List of functions to sync from GitHub
$functionNames = @("mass_rename.ps1", "space_to_dots.ps1", "hash_ls.ps1")

foreach ($funcName in $functionNames) {
    Write-Host "[*] Syncing $funcName from GitHub..." -ForegroundColor Gray
    $destPath = Join-Path $funcDir $funcName
    try {
        Invoke-WebRequest -Uri ($baseUrl + $funcName) -OutFile $destPath -ErrorAction Stop
    } catch {
        Write-Host " [!] Failed to sync $funcName." -ForegroundColor Red
    }
}
Write-Host "[+] Toolkit functions synchronized in $funcDir" -ForegroundColor Green

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

if (`$selection -eq 'u' -or `$selection -eq 'U') {
    `$setupPath = Join-Path "$baseDir" "Setup.ps1"
    Invoke-WebRequest -Uri `$repoUrl -OutFile `$setupPath -ErrorAction Stop
    & `$setupPath
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

# --- [6. Update Profile] ---
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

# --- [7. Terminal Customization (Omitted for brevity, keep your original JSON code here)] ---
# ... (Paste your Section 8 from your previous Setup.ps1 here) ...

Write-Host "`n[+++] SETUP COMPLETE! Restart PowerShell to enable the 'menu' command." -ForegroundColor Green