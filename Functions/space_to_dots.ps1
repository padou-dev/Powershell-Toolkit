function space_to_dots {
    Get-ChildItem | Rename-Item -NewName { $_.Name -replace " ", "." }
    Write-Host "Spaces converted to dots." -ForegroundColor Green
}