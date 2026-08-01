function hash_ls {
    <#
    SHA256 audit of files in the current directory, with optional VirusTotal
    lookup per file.

    Design notes:
    - Only the HASH is sent to VirusTotal, never the file itself.
    - The API key is read from the VT_API_KEY user environment variable so it
      can never end up committed to the repo. Without a key, API lookups are
      skipped but opening the report in the browser still works.
    - Lookups are on-demand per selected file, not for the whole directory:
      the free API tier allows 4 requests/minute.
    #>
    Write-Host "`n--- [SHA256 File Audit] ---" -ForegroundColor Cyan
    $files = Get-ChildItem -File
    if (-not $files) { Write-Host '[!] No files found.' -ForegroundColor Yellow; return }

    $i = 0
    $results = foreach ($file in $files) {
        $i++
        try { $hash = (Get-FileHash $file.FullName -Algorithm SHA256 -ErrorAction Stop).Hash }
        catch { $hash = 'LOCKED/ACCESS DENIED' }

        $sizeValue = $file.Length
        if     ($sizeValue -gt 1GB) { $prettySize = '{0:N2} GB' -f ($sizeValue / 1GB) }
        elseif ($sizeValue -gt 1MB) { $prettySize = '{0:N2} MB' -f ($sizeValue / 1MB) }
        else                        { $prettySize = '{0:N2} KB' -f ($sizeValue / 1KB) }

        [PSCustomObject]@{
            '#'      = $i
            Icon     = if (Get-Module -Name Terminal-Icons) { $file | Format-TerminalIcons } else { '' }
            FileName = $file.Name
            SHA256   = $hash
            Size     = $prettySize
        }
    }
    $results = @($results)
    $results | Format-Table -AutoSize

    # ------------------------------------------------------------------
    # API key: environment variable, offered-once setup, never in the repo
    # ------------------------------------------------------------------
    if (-not $env:VT_API_KEY) {
        Write-Host 'No VT_API_KEY found. Get a free key at virustotal.com (profile > API key).' -ForegroundColor Yellow
        $entered = Read-Host 'Paste your API key to enable lookups, or press Enter to skip'
        if (-not [string]::IsNullOrWhiteSpace($entered)) {
            # 'User' scope persists it for your account across sessions —
            # equivalent to setting it in System Properties, no admin needed.
            [Environment]::SetEnvironmentVariable('VT_API_KEY', $entered.Trim(), 'User')
            $env:VT_API_KEY = $entered.Trim()
            Write-Host 'Saved to your user environment. It will be available in new shells automatically.' -ForegroundColor Green
        }
    }

    # ------------------------------------------------------------------
    # Interactive lookup loop
    # ------------------------------------------------------------------
    while ($true) {
        $choice = Read-Host "`nEnter a file # to check on VirusTotal (Enter to exit)"
        if ([string]::IsNullOrWhiteSpace($choice)) { return }
        if ($choice -notmatch '^\d+$' -or [int]$choice -lt 1 -or [int]$choice -gt $results.Count) {
            Write-Host 'Invalid selection.' -ForegroundColor Yellow
            continue
        }

        $sel = $results[[int]$choice - 1]
        if ($sel.SHA256 -eq 'LOCKED/ACCESS DENIED') {
            Write-Host 'That file could not be hashed, so there is nothing to look up.' -ForegroundColor Yellow
            continue
        }

        if ($env:VT_API_KEY) {
            try {
                $r = Invoke-RestMethod -Uri "https://www.virustotal.com/api/v3/files/$($sel.SHA256)" `
                                       -Headers @{ 'x-apikey' = $env:VT_API_KEY } -ErrorAction Stop
                $stats = $r.data.attributes.last_analysis_stats
                $total = $stats.malicious + $stats.suspicious + $stats.undetected + $stats.harmless

                # Color logic: any 'malicious' verdict is red; 'suspicious'
                # only is yellow; all clear is green.
                $color = if ($stats.malicious -gt 0) { 'Red' }
                         elseif ($stats.suspicious -gt 0) { 'Yellow' }
                         else { 'Green' }
                Write-Host ("{0}: {1}/{2} engines flagged malicious, {3} suspicious" -f `
                    $sel.FileName, $stats.malicious, $total, $stats.suspicious) -ForegroundColor $color
            } catch {
                $status = try { [int]$_.Exception.Response.StatusCode } catch { 0 }
                switch ($status) {
                    # WHY 404 gets special wording: it means VT has never seen
                    # this hash — common for niche or freshly-built files.
                    # Unknown is NOT the same as clean.
                    404     { Write-Host "Not in VirusTotal's database - unknown to VT, which is NOT the same as clean." -ForegroundColor Yellow }
                    429     { Write-Host 'Rate limited (free tier: 4 lookups/minute). Wait a moment and retry.' -ForegroundColor Yellow }
                    401     { Write-Host 'API key rejected. Fix or re-save it (stored in the VT_API_KEY user environment variable).' -ForegroundColor Red }
                    default { Write-Host "Lookup failed: $($_.Exception.Message)" -ForegroundColor Red }
                }
            }
        } else {
            Write-Host 'No API key - skipping detection stats.' -ForegroundColor Yellow
        }

        if ((Read-Host 'Open full report in browser? (y/n)') -eq 'y') {
            Start-Process "https://www.virustotal.com/gui/file/$($sel.SHA256)"
        }
    }
}
