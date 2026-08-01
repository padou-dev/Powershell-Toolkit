#Requires -Version 7.0
<#
.SYNOPSIS
    Interactive menu for the Powershell-Toolkit. Launched via the `toolkit`
    command that Setup.ps1 adds to your profile.

.NOTES
    Lives as its own file in the repo (instead of being generated from a
    here-string inside Setup.ps1) so it can be edited and reviewed like any
    normal script — no escaped-backtick maintenance.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ToolkitDir = $PSScriptRoot
$manifest   = Get-Content (Join-Path $ToolkitDir 'manifest.json') -Raw | ConvertFrom-Json

do {
    Write-Host ''
    Write-Host "  Powershell-Toolkit v$($manifest.version)" -ForegroundColor Cyan
    Write-Host '  ---------------------------------------'

    for ($i = 0; $i -lt $manifest.functions.Count; $i++) {
        $fn = $manifest.functions[$i]
        Write-Host ("  [{0}] {1,-22} {2}" -f ($i + 1), $fn.command, $fn.description)
    }
    Write-Host '  [U] Update toolkit from GitHub'
    Write-Host '  [Q] Quit'
    Write-Host ''

    $choice = Read-Host '  Select'

    switch -Regex ($choice) {
        '^[Qq]$' { break }
        '^[Uu]$' {
            # Re-runs the installer straight from GitHub. Downloading to a file
            # and executing it (instead of piping into iex) keeps what ran
            # inspectable afterwards.
            $tmp = Join-Path ([System.IO.Path]::GetTempPath()) 'toolkit-setup.ps1'
            Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/padou-dev/Powershell-Toolkit/main/Setup.ps1' -OutFile $tmp
            & $tmp
            $manifest = Get-Content (Join-Path $ToolkitDir 'manifest.json') -Raw | ConvertFrom-Json
        }
        '^\d+$' {
            $idx = [int]$choice - 1
            if ($idx -ge 0 -and $idx -lt $manifest.functions.Count) {
                $fn = $manifest.functions[$idx]
                # Dot-source then invoke: guarantees the function exists even
                # if this menu was started from a shell without the profile.
                . (Join-Path $ToolkitDir "Functions\$($fn.file)")
                Write-Host ''
                & $fn.command
                Write-Host ''
                # WHY ReadKey instead of Read-Host: Read-Host always waits for
                # Enter, so "press Q" would really mean "press Q then Enter".
                # ReadKey($true) captures a single keypress ($true = don't echo
                # it to the screen) for a true one-key return.
                Write-Host '  Press Q to return to the menu' -ForegroundColor DarkGray
                do { $key = [Console]::ReadKey($true) } until ($key.Key -eq 'Q')
            } else {
                Write-Host '  Invalid selection.' -ForegroundColor Yellow
            }
        }
        default { Write-Host '  Invalid selection.' -ForegroundColor Yellow }
    }
} until ($choice -match '^[Qq]$')
