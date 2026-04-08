function get_sysinfo {
    Write-Host "`n--- [ SYSTEM HARDWARE DASHBOARD ] ---" -ForegroundColor Cyan

    # 1. CPU Info
    $cpu = Get-CimInstance Win32_Processor
    $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    Write-Host "CPU:    $($cpu.Name) ($($cpu.NumberOfCores) Cores)" -ForegroundColor Gray
    Write-Host "Usage:  $([Math]::Round($cpuUsage, 2))%" -ForegroundColor Yellow

    # 2. RAM Info
    $os = Get-CimInstance Win32_OperatingSystem
    $totalRam = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRam = [Math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRam = [Math]::Round($totalRam - $freeRam, 2)
    Write-Host "RAM:    $usedRam GB / $totalRam GB used" -ForegroundColor Gray

    # 3. GPU Info
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
    Write-Host "GPU:    $($gpu.Name)" -ForegroundColor Gray

    # 4. Storage Info (Hard Drives)
    Write-Host "`n--- [ STORAGE ] ---" -ForegroundColor Cyan
    $drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" # Only local fixed disks
    foreach ($drive in $drives) {
        $totalGB = [Math]::Round($drive.Size / 1GB, 2)
        $freeGB = [Math]::Round($drive.FreeSpace / 1GB, 2)
        $usedGB = [Math]::Round($totalGB - $freeGB, 2)
        $percentUsed = [Math]::Round(($usedGB / $totalGB) * 100, 1)

        $driveColor = if ($percentUsed -gt 90) { "Red" } else { "Gray" }

        Write-Host "Drive $($drive.DeviceID) ($($drive.VolumeName)):" -ForegroundColor Cyan
        Write-Host "  Used: $usedGB GB / $totalGB GB ($percentUsed%)" -ForegroundColor $driveColor
    }

    # 5. OS & Uptime
    Write-Host "`n--- [ SYSTEM ] ---" -ForegroundColor Cyan
    $uptime = (Get-Date) - $os.LastBootUpTime
    Write-Host "OS:     $($os.Caption)" -ForegroundColor Gray
    Write-Host "Uptime: $($uptime.Days)d, $($uptime.Hours)h, $($uptime.Minutes)m" -ForegroundColor Gray
    Write-Host "-------------------------------------`n" -ForegroundColor Cyan
}