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
Write-Host "       AVAILABLE TOOLKIT FUNCTIONS       " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Green

for (`$i = 0; `$i -lt `$toolkitScripts.Count; `$i++) {
    Write-Host (" [`$(`$i + 1)] " + `$toolkitScripts[`$i].BaseName) -ForegroundColor Yellow
}
Write-Host " [Q] Quit" -ForegroundColor Red
Write-Host "=========================================" -ForegroundColor Green

`$selection = Read-Host "`nEnter selection"
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