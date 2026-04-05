function hash_ls {
    Write-Host "`n--- [SHA256 File Audit] ---" -ForegroundColor Cyan
    $files = Get-ChildItem -File
    if ($null -eq $files) { Write-Host "[!] No files found." -ForegroundColor Yellow; return }

    $results = foreach ($file in $files) {
        try { $hash = (Get-FileHash $file.FullName -Algorithm SHA256 -ErrorAction Stop).Hash }
        catch { $hash = "LOCKED/ACCESS DENIED" }

        $sizeValue = $file.Length
        if ($sizeValue -gt 1GB) { $prettySize = "$([Math]::Round($sizeValue / 1GB, 2)) GB" }
        elseif ($sizeValue -gt 1MB) { $prettySize = "$([Math]::Round($sizeValue / 1MB, 2)) MB" }
        else { $prettySize = "$([Math]::Round($sizeValue / 1KB, 2)) KB" }

        [PSCustomObject]@{
            "Icon"      = if (Get-Module -Name Terminal-Icons) { $file | Format-TerminalIcons } else { "" }
            "FileName"  = $file.Name
            "SHA256"    = $hash
            "Size"      = $prettySize
        }
    }
    $results | Format-Table -AutoSize
}