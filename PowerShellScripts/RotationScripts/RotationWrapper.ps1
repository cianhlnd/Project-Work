# Resolve paths relative to this script's own folder so the suite is portable
$CsvPath          = Join-Path $PSScriptRoot "RotationInput.csv"
$RotationScript   = Join-Path $PSScriptRoot "TraineeRotation.ps1"

Write-Host "`nRunning (WhatIf) Parameter" -ForegroundColor Cyan
& $RotationScript -Csv $CsvPath -WhatIf

Write-Host "`nReview the changes above." -ForegroundColor Cyan
do {
    $confirm = Read-Host "Type RUN to proceed or SKIP to cancel"
    $confirm = $confirm.Trim().ToUpper()
} while ($confirm -notin @("RUN", "SKIP"))

if ($confirm -eq "RUN") {
    Write-Host "`nRunning live update..." -ForegroundColor Green
    & $RotationScript -Csv $CsvPath -Confirm:$false
}
else {
    Write-Host "`nSkipped." -ForegroundColor Yellow
}
