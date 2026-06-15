# Resolve all paths relative to this script's own folder so the suite is portable
$CsvPath          = Join-Path $PSScriptRoot "LeaversInput.csv"
$ADScript         = Join-Path $PSScriptRoot "ADLeaverScript.ps1"
$ExchangeScript   = Join-Path $PSScriptRoot "ExchangeLeaverScript.ps1"
$FileServerScript = Join-Path $PSScriptRoot "FileServersLeaverScript.ps1"

# AD Script
Write-Host "`nRunning AD Leaver Script (WhatIf)" -ForegroundColor Cyan
& $ADScript -Csv $CsvPath -WhatIf

Write-Host "`nReview the AD changes above." -ForegroundColor Yellow

do {
    $confirm = Read-Host "Type RUN to proceed or SKIP to cancel"
    $confirm = $confirm.Trim().ToUpper()
} while ($confirm -notin @("RUN", "SKIP"))

if ($confirm -eq "RUN") {
    Write-Host "`nRunning AD Script" -ForegroundColor Green
    & $ADScript -Csv $CsvPath -Confirm:$false
}
else {
    Write-Host "`nSkipped." -ForegroundColor Yellow
}

# Exchange Script
Write-Host "`nRunning Exchange Leaver Script (WhatIf)" -ForegroundColor Yellow

& $ExchangeScript -Csv $CsvPath -WhatIf

Write-Host "`nReview the Exchange changes above." -ForegroundColor Yellow

do {
    $confirm = Read-Host "Type RUN to proceed or SKIP to cancel"
    $confirm = $confirm.Trim().ToUpper()
} while ($confirm -notin @("RUN", "SKIP"))

if ($confirm -eq "RUN") {
    Write-Host "`nRunning Exchange Script" -ForegroundColor Green
    & $ExchangeScript -Csv $CsvPath -Confirm:$false -KeepExchangeSession
}
else {
    Write-Host "`nSkipped." -ForegroundColor Yellow
}
# File Server Script
Write-Host "`nRunning File Server Leaver Script (WhatIf)" -ForegroundColor Yellow

& $FileServerScript -Csv $CsvPath -WhatIf

Write-Host "`nReview the File Server changes above." -ForegroundColor Yellow

do {
    $confirm = Read-Host "Type RUN to proceed or SKIP to cancel"
    $confirm = $confirm.Trim().ToUpper()
} while ($confirm -notin @("RUN", "SKIP"))

if ($confirm -eq "RUN") {
    Write-Host "`nRunning File Server Leaver Script" -ForegroundColor Green
    & $FileServerScript -Csv $CsvPath -Confirm:$false
}
else {
    Write-Host "`nSkipped." -ForegroundColor Yellow
}

Write-Host "`nAll leaver scripts completed." -ForegroundColor Green
