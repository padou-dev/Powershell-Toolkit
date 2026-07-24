#Requires -Version 7.0
<#
.SYNOPSIS
    Installer for the Powershell-Toolkit (github.com/padou-dev/Powershell-Toolkit).

.DESCRIPTION
    Installs the toolkit entirely in USER scope — no administrator rights needed.
    - Reads manifest.json (the single registry of functions and modules)
    - Copies/downloads function scripts into <ProfileDir>\Toolkit\Functions
    - Manages a clearly-marked block in your PowerShell profile (never
      overwrites anything outside the markers, backs up before every change)
    - Optionally injects a Windows Terminal color scheme (backed up first)

    Source auto-detection: if manifest.json sits next to this script (i.e. you
    cloned the repo), files are copied locally — ideal for testing changes
    before pushing. Otherwise everything is downloaded from GitHub.

.PARAMETER Uninstall
    Removes the managed profile block and the Toolkit directory. Backups and
    Windows Terminal changes are left in place (paths are printed).

.PARAMETER SkipTerminal
    Skip the Windows Terminal color scheme step entirely.

.EXAMPLE
    .\Setup.ps1              # install / update
    .\Setup.ps1 -Uninstall   # clean removal
#>
[CmdletBinding()]
param(
    [switch]$Uninstall,
    [switch]$SkipTerminal
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ----------------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------------
$RepoRaw   = 'https://raw.githubusercontent.com/padou-dev/Powershell-Toolkit/main'
$StartMark = '# >>> powershell-toolkit start >>>'
$EndMark   = '# <<< powershell-toolkit end <<<'

# WHY derive from $PROFILE instead of "$HOME\Documents": OneDrive folder
# redirection moves Documents (and the profile with it). $PROFILE is always
# the truth, so everything we install lives next to it.
$ProfileDir = Split-Path -Parent $PROFILE
$ToolkitDir = Join-Path $ProfileDir 'Toolkit'
$FuncDir    = Join-Path $ToolkitDir 'Functions'

function Write-Step { param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "    $Msg" -ForegroundColor Green }

# ----------------------------------------------------------------------------
# Profile block management
# ----------------------------------------------------------------------------
function Get-ManagedBlock {
    # Everything the profile needs, fenced by markers so we can update or
    # remove it later without touching the user's own profile content.
    @"
$StartMark
# Managed by Powershell-Toolkit Setup.ps1 — edits inside this block are
# overwritten on every install/update. Put personal config outside it.
`$toolkitRoot = Join-Path (Split-Path -Parent `$PROFILE) 'Toolkit'
if (Test-Path (Join-Path `$toolkitRoot 'Functions')) {
    Get-ChildItem -Path (Join-Path `$toolkitRoot 'Functions') -Filter '*.ps1' |
        ForEach-Object { . `$_.FullName }
}
function toolkit { & (Join-Path `$toolkitRoot 'Menu.ps1') }
$EndMark
"@
}

function Remove-ManagedBlock {
    param([string]$Content)
    # (?s) = singleline mode so .* spans newlines. \r?\n? swallows the blank
    # line the block leaves behind, keeping repeated runs from stacking gaps.
    $pattern = "(?s)\r?\n?" + [regex]::Escape($StartMark) + ".*?" + [regex]::Escape($EndMark) + "\r?\n?"
    return ($Content -replace $pattern, "`n").TrimEnd()
}

function Update-Profile {
    param([switch]$Remove)

    $existing = if (Test-Path $PROFILE) { Get-Content $PROFILE -Raw } else { '' }

    # WHY back up first: a profile is personal, hand-tuned config. Even though
    # the marker approach is non-destructive by design, a timestamped backup
    # makes every change reversible if the regex ever meets an edge case.
    if ($existing) {
        $bak = "$PROFILE.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -Path $PROFILE -Destination $bak
        Write-Ok "Profile backed up to $bak"
    }

    $cleaned = Remove-ManagedBlock -Content $existing
    $newContent = if ($Remove) { $cleaned } else { ($cleaned, (Get-ManagedBlock)) -join "`n`n" }

    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
    Set-Content -Path $PROFILE -Value $newContent.TrimStart()
    Write-Ok $(if ($Remove) { 'Managed block removed from profile' } else { 'Managed block written to profile' })
}

# ----------------------------------------------------------------------------
# Uninstall
# ----------------------------------------------------------------------------
if ($Uninstall) {
    Write-Step 'Uninstalling Powershell-Toolkit'
    Update-Profile -Remove
    if (Test-Path $ToolkitDir) {
        Remove-Item -Path $ToolkitDir -Recurse -Force
        Write-Ok "Removed $ToolkitDir"
    }
    Write-Host "`nDone. Profile backups (*.bak-*) and any Windows Terminal backups were kept." -ForegroundColor Yellow
    return
}

# ----------------------------------------------------------------------------
# Locate source: local clone vs GitHub
# ----------------------------------------------------------------------------
$LocalSource = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot 'manifest.json'))) {
    $LocalSource = $PSScriptRoot
    Write-Step "Local repo detected at $LocalSource — installing from local files"
} else {
    Write-Step 'Installing from GitHub'
}

function Get-ToolkitFile {
    # One function, two transports. Downloads go to a temp file first and are
    # moved into place only on success, so a dropped connection can never
    # leave a half-written script that the profile would later dot-source.
    param([string]$RelativePath, [string]$Destination)

    if ($LocalSource) {
        Copy-Item -Path (Join-Path $LocalSource $RelativePath) -Destination $Destination -Force
    } else {
        $tmp = [System.IO.Path]::GetTempFileName()
        try {
            Invoke-WebRequest -Uri "$RepoRaw/$($RelativePath -replace '\\','/')" -OutFile $tmp
            Move-Item -Path $tmp -Destination $Destination -Force
        } catch {
            Remove-Item -Path $tmp -ErrorAction SilentlyContinue
            throw "Failed to fetch '$RelativePath': $($_.Exception.Message)"
        }
    }
}

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------
New-Item -ItemType Directory -Path $FuncDir -Force | Out-Null

Write-Step 'Fetching manifest'
Get-ToolkitFile -RelativePath 'manifest.json' -Destination (Join-Path $ToolkitDir 'manifest.json')
$manifest = Get-Content (Join-Path $ToolkitDir 'manifest.json') -Raw | ConvertFrom-Json
Write-Ok "Manifest v$($manifest.version) — $($manifest.functions.Count) function(s)"

Write-Step 'Installing function scripts'
foreach ($fn in $manifest.functions) {
    Get-ToolkitFile -RelativePath (Join-Path 'Functions' $fn.file) -Destination (Join-Path $FuncDir $fn.file)
    Write-Ok "$($fn.file)  ->  $($fn.command)"
}

Write-Step 'Installing menu'
Get-ToolkitFile -RelativePath 'Menu.ps1' -Destination (Join-Path $ToolkitDir 'Menu.ps1')

# WHY -Scope CurrentUser: installs into the user's module path, which needs no
# elevation. This is the reason the whole installer can run without admin.
Write-Step 'Checking PowerShell modules'
foreach ($mod in $manifest.modules) {
    if (Get-Module -ListAvailable -Name $mod) {
        Write-Ok "$mod already installed"
    } else {
        Install-Module -Name $mod -Scope CurrentUser -Force
        Write-Ok "$mod installed (CurrentUser scope)"
    }
}

Write-Step 'Updating PowerShell profile'
Update-Profile

# ----------------------------------------------------------------------------
# Windows Terminal color scheme (optional)
# ----------------------------------------------------------------------------
if (-not $SkipTerminal) {
    $wtSettings = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    if (Test-Path $wtSettings) {
        Write-Step 'Applying Windows Terminal color schemes'

        # Schemes live in terminal_schemes.json — same principle as the
        # manifest: schemes are data, so adding one shouldn't mean editing
        # installer code.
        Get-ToolkitFile -RelativePath 'terminal_schemes.json' -Destination (Join-Path $ToolkitDir 'terminal_schemes.json')
        $mySchemes = Get-Content (Join-Path $ToolkitDir 'terminal_schemes.json') -Raw | ConvertFrom-Json

        $bak = "$wtSettings.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -Path $wtSettings -Destination $bak
        Write-Ok "settings.json backed up to $bak"

        # NOTE: PS7's ConvertFrom-Json tolerates the comments Windows Terminal
        # allows in its JSON, but round-tripping strips them. The backup above
        # is the safety net for that.
        $settings = Get-Content $wtSettings -Raw | ConvertFrom-Json

        # WHY Add-Member instead of plain assignment: ConvertFrom-Json returns
        # PSCustomObjects, and assigning to a property that doesn't exist on
        # one THROWS. On a machine whose settings.json has never defined
        # 'schemes', `$settings.schemes = @()` crashes. Add-Member creates it.
        if (-not ($settings.PSObject.Properties.Name -contains 'schemes')) {
            $settings | Add-Member -NotePropertyName 'schemes' -NotePropertyValue @()
        }

        $existingNames = @($settings.schemes | ForEach-Object { $_.name })
        $added = 0
        foreach ($scheme in $mySchemes) {
            if ($existingNames -contains $scheme.name) {
                Write-Ok "'$($scheme.name)' already present — skipped"
            } else {
                $settings.schemes = @($settings.schemes) + $scheme
                $added++
                Write-Ok "'$($scheme.name)' added"
            }
        }

        # WHY write only when something changed: no reason to rewrite (and
        # strip comments from) a settings file we didn't modify.
        if ($added -gt 0) {
            $settings | ConvertTo-Json -Depth 32 | Set-Content -Path $wtSettings
            Write-Ok "$added scheme(s) written — pick one under Terminal Settings > Appearance"
        }
    } else {
        Write-Ok 'Windows Terminal not found — skipping scheme'
    }
}

Write-Host "`nInstall complete." -ForegroundColor Green
Write-Host "Open a NEW PowerShell window (the profile loads at startup), then run: " -NoNewline
Write-Host 'toolkit' -ForegroundColor Cyan
