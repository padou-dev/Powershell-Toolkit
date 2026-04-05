function mass_rename {
    $oldText = Read-Host "Enter the part of the filename you want to rename"
    $newText = Read-Host "Enter what you want to rename it to"
    if ([string]::IsNullOrWhiteSpace($oldText)) { return }
    $files = Get-ChildItem -File | Where-Object { $_.Name -like "*$oldText*" }
    if (-not $files) { Write-Host "No matching files found." -ForegroundColor Yellow; return }
    Write-Host "`nPreview:" -ForegroundColor Cyan
    foreach ($file in $files) {
        $newName = $file.Name -replace [regex]::Escape($oldText), $newText
        Write-Host "$($file.Name) → $newName"
    }
    if ((Read-Host "`nProceed with rename? (y/n)") -ne 'y') { return }
    $files | Rename-Item -NewName { $_.Name -replace [regex]::Escape($oldText), $newText }
}