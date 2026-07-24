function space_to_dots {
    <#
    Replaces spaces with dots in filenames in the current directory.

    Design notes:
    - -File: only rename files, never directories (renaming a dir you're
      inside of, or one another program has open, causes confusing failures)
    - -match ' ': skip files with no spaces. Rename-Item errors when the new
      name equals the old one, so filtering no-ops out avoids error spam.
    - Preview + confirm before touching anything, same contract as
      mass_rename: destructive operations always show their work first.
    #>
    $files = Get-ChildItem -File | Where-Object { $_.Name -match ' ' }
    if (-not $files) {
        Write-Host 'No filenames containing spaces found.' -ForegroundColor Yellow
        return
    }

    Write-Host "`nPreview:" -ForegroundColor Cyan
    foreach ($file in $files) {
        Write-Host "$($file.Name) -> $($file.Name -replace ' ', '.')"
    }

    if ((Read-Host "`nProceed with rename? (y/n)") -ne 'y') { return }

    $files | Rename-Item -NewName { $_.Name -replace ' ', '.' }
    Write-Host "Done - $($files.Count) file(s) renamed." -ForegroundColor Green
}
