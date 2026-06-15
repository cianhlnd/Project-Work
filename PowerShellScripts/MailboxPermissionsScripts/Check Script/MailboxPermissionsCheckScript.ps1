# Connect to Exchange Online if not already connected
Try {
    Get-OrganizationConfig -ErrorAction Stop | Out-Null
    Write-Host "Already connected to Exchange Online" -ForegroundColor Green
}
Catch {
    Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
    Connect-ExchangeOnline
}

# Hardcoded CSV input path
# Expected columns: SecretaryDelegate, FeeEarnerTargetMailbox, Direction
# SecretaryDelegate can be blank or 'none' to check all permissions
$CsvInputPath = Join-Path $PSScriptRoot "MailboxPermissionCheckInput.csv"

# Helper function - Print a visual separator between operations
function Write-OperationSeparator {
    param([string]$Title)
    Write-Host ""
    Write-Host ""
    Write-Host "##################################################" -ForegroundColor Magenta
    Write-Host "##                                              ##" -ForegroundColor Magenta
    if ($Title) {
        $Padding  = [Math]::Max(0, (46 - $Title.Length) / 2)
        $PadLeft  = " " * [Math]::Floor($Padding)
        $PadRight = " " * [Math]::Ceiling($Padding)
        Write-Host ("##" + $PadLeft + $Title + $PadRight + "##") -ForegroundColor Magenta
    }
    Write-Host "##                                              ##" -ForegroundColor Magenta
    Write-Host "##################################################" -ForegroundColor Magenta
    Write-Host ""
}

# ============================================================
# Helper function - Resolve display name for secretary
# ============================================================
function Get-SecretaryDisplayName {
    param([string]$SecretaryDelegate)
    if ($SecretaryDelegate) {
        return $SecretaryDelegate
    }
    else {
        return "All"
    }
}

# Helper function - Check Full Mailbox Access
function Invoke-CheckFullAccess {
    param(
        [string]$SecretaryDelegate,
        [string]$FeeEarnerTargetMailbox,
        [System.Collections.Generic.List[object]]$OperationResults
    )

    Write-Host "`nChecking Full Mailbox Access on $FeeEarnerTargetMailbox..." -ForegroundColor Cyan

    Try {
        if ($SecretaryDelegate) {
            $FullAccessPerms = Get-MailboxPermission -Identity $FeeEarnerTargetMailbox -ErrorAction Stop |
                Where-Object {
                    $_.User         -eq $SecretaryDelegate -and
                    $_.AccessRights -contains "FullAccess" -and
                    $_.IsInherited  -eq $false
                }
        }
        else {
            $FullAccessPerms = Get-MailboxPermission -Identity $FeeEarnerTargetMailbox -ErrorAction Stop |
                Where-Object {
                    $_.AccessRights -contains "FullAccess"                              -and
                    $_.IsInherited  -eq $false                                          -and
                    $_.User         -notin @("Default", "Anonymous", "NT AUTHORITY\SELF")
                }
        }

        if ($FullAccessPerms) {
            foreach ($Perm in $FullAccessPerms) {
                Write-Host " $($Perm.User) has Full Mailbox Access on $FeeEarnerTargetMailbox" -ForegroundColor Green
                $OperationResults.Add([PSCustomObject]@{
                    Secretary = $Perm.User
                    Mailbox   = $FeeEarnerTargetMailbox
                    Folder    = "N/A"
                    Action    = "Check Full Access"
                    Status    = "Has Access"
                    Error     = ""
                })
            }
        }
        else {
            Write-Host " No Full Mailbox Access entries found on $FeeEarnerTargetMailbox" -ForegroundColor Yellow
        }
    }
    Catch {
        $DisplayName = Get-SecretaryDisplayName -SecretaryDelegate $SecretaryDelegate
        Write-Host " Failed to check Full Access: $($_.Exception.Message)" -ForegroundColor Red
        $OperationResults.Add([PSCustomObject]@{
            Secretary = $DisplayName
            Mailbox   = $FeeEarnerTargetMailbox
            Folder    = "N/A"
            Action    = "Check Full Access"
            Status    = "Failed"
            Error     = $_.Exception.Message
        })
    }
}

# Helper function - Check Folder Permissions
function Invoke-CheckFolderPermissions {
    param(
        [string]$SecretaryDelegate,
        [string]$FeeEarnerTargetMailbox,
        [System.Collections.Generic.List[object]]$OperationResults
    )

    Write-Host "`nChecking Folder Permissions on $FeeEarnerTargetMailbox..." -ForegroundColor Cyan

    # Resolve display name if a specific delegate was provided
    $DelegateDisplayName = $null
    if ($SecretaryDelegate) {
        Try {
            $DelegateDisplayName = (Get-Recipient -Identity $SecretaryDelegate -ErrorAction Stop).DisplayName
        }
        Catch {
            Write-Host " Failed to resolve display name for $SecretaryDelegate - $($_.Exception.Message)" -ForegroundColor Red
            $OperationResults.Add([PSCustomObject]@{
                Secretary = $SecretaryDelegate
                Mailbox   = $FeeEarnerTargetMailbox
                Folder    = "N/A"
                Action    = "Check Folder Permission"
                Status    = "Failed"
                Error     = "Could not resolve delegate display name: $($_.Exception.Message)"
            })
            return
        }
    }

    Try {
        $AllFolders = Get-MailboxFolderStatistics -Identity $FeeEarnerTargetMailbox -ErrorAction Stop |
            Select-Object FolderPath, FolderId

        $FoundAny = $false

        foreach ($Folder in $AllFolders) {
            $FolderIdentity = $FeeEarnerTargetMailbox + ":" + $Folder.FolderId
            Try {
                if ($SecretaryDelegate) {
                    $FolderPerms = Get-MailboxFolderPermission `
                        -Identity    $FolderIdentity `
                        -User        $DelegateDisplayName `
                        -ErrorAction Stop
                }
                else {
                    $FolderPerms = Get-MailboxFolderPermission `
                        -Identity    $FolderIdentity `
                        -ErrorAction Stop |
                        Where-Object {
                            $_.User -notin @("Default", "Anonymous")
                        }
                }

                foreach ($Perm in $FolderPerms) {
                    if ($Perm.AccessRights -notcontains "None") {
                        $FoundAny   = $true
                        $RightsText = $Perm.AccessRights -join ", "
                        Write-Host " $($Perm.User) - $($Folder.FolderPath) : $RightsText" -ForegroundColor Green
                        $OperationResults.Add([PSCustomObject]@{
                            Secretary = $Perm.User
                            Mailbox   = $FeeEarnerTargetMailbox
                            Folder    = $Folder.FolderPath
                            Action    = "Check Folder Permission"
                            Status    = $RightsText
                            Error     = ""
                        })
                    }
                }
            }
            Catch {
                if ($_.Exception.Message -like "*No existing permission*" -or
                    $_.Exception.Message -like "*not found*" -or
					$_.Exception.Message -like "*Calendar sharing permissions cannot be granted*" -or
					$_.Exception.Message -like "*Specified method is not supported*") {
                    # No permission on this folder - expected, skip silently
                }
                else {
                    $DisplayName = Get-SecretaryDisplayName -SecretaryDelegate $SecretaryDelegate
                    Write-Host "  [!] Failed to check: $($Folder.FolderPath) - $($_.Exception.Message)" -ForegroundColor Red
                    $OperationResults.Add([PSCustomObject]@{
                        Secretary = $DisplayName
                        Mailbox   = $FeeEarnerTargetMailbox
                        Folder    = $Folder.FolderPath
                        Action    = "Check Folder Permission"
                        Status    = "Failed"
                        Error     = $_.Exception.Message
                    })
                }
            }
        }

        if (-not $FoundAny) {
            Write-Host "  [-] No folder permissions found on $FeeEarnerTargetMailbox" -ForegroundColor Yellow
        }
    }
    Catch {
        $DisplayName = Get-SecretaryDisplayName -SecretaryDelegate $SecretaryDelegate
        Write-Host "  [!] Failed to retrieve folders: $($_.Exception.Message)" -ForegroundColor Red
        $OperationResults.Add([PSCustomObject]@{
            Secretary = $DisplayName
            Mailbox   = $FeeEarnerTargetMailbox
            Folder    = "N/A"
            Action    = "Check Folder Permission"
            Status    = "Failed"
            Error     = $_.Exception.Message
        })
    }
}

# Helper function - Check Private Items Access
function Invoke-CheckPrivateItems {
    param(
        [string]$SecretaryDelegate,
        [string]$FeeEarnerTargetMailbox,
        [System.Collections.Generic.List[object]]$OperationResults
    )

    Write-Host "`nChecking Private Items Access on $FeeEarnerTargetMailbox..." -ForegroundColor Cyan

    Try {
        $CalendarIdentity = $FeeEarnerTargetMailbox + ":\Calendar"

        if ($SecretaryDelegate) {
            $CalendarPerms = Get-MailboxFolderPermission `
                -Identity    $CalendarIdentity `
                -User        $SecretaryDelegate `
                -ErrorAction Stop
        }
        else {
            $CalendarPerms = Get-MailboxFolderPermission `
                -Identity    $CalendarIdentity `
                -ErrorAction Stop |
                Where-Object {
                    $_.User -notin @("Default", "Anonymous")
                }
        }

        $FoundAny = $false

        foreach ($Perm in $CalendarPerms) {
            $FoundAny = $true
            if ($Perm.SharingPermissionFlags -like "*CanViewPrivateItems*") {
                Write-Host " $($Perm.User) can view private items on $FeeEarnerTargetMailbox" -ForegroundColor Green
                $OperationResults.Add([PSCustomObject]@{
                    Secretary = $Perm.User
                    Mailbox   = $FeeEarnerTargetMailbox
                    Folder    = "\Calendar"
                    Action    = "Check Private Items"
                    Status    = "Can View Private Items"
                    Error     = ""
                })
            }
            else {
                Write-Host " $($Perm.User) cannot view private items on $FeeEarnerTargetMailbox" -ForegroundColor Yellow
                $OperationResults.Add([PSCustomObject]@{
                    Secretary = $Perm.User
                    Mailbox   = $FeeEarnerTargetMailbox
                    Folder    = "\Calendar"
                    Action    = "Check Private Items"
                    Status    = "Cannot View Private Items"
                    Error     = ""
                })
            }
        }

        if (-not $FoundAny) {
            Write-Host " No private items access entries found on $FeeEarnerTargetMailbox" -ForegroundColor Yellow
        }
    }
    Catch {
        $DisplayName = Get-SecretaryDisplayName -SecretaryDelegate $SecretaryDelegate
        Write-Host " Failed to check Private Items: $($_.Exception.Message)" -ForegroundColor Red
        $OperationResults.Add([PSCustomObject]@{
            Secretary = $DisplayName
            Mailbox   = $FeeEarnerTargetMailbox
            Folder    = "\Calendar"
            Action    = "Check Private Items"
            Status    = "Failed"
            Error     = $_.Exception.Message
        })
    }
}

# Function - Process a single check operation
function Invoke-CheckOperation {
    param(
        [string]$SecretaryDelegate,
        [string]$FeeEarnerTargetMailbox,
        [string]$Direction,
        [int]$QueueNumber,
        [ref]$Results
    )

    $OperationResults = [System.Collections.Generic.List[object]]::new()

    # Normalise secretary input
    if ($SecretaryDelegate -eq "" -or $SecretaryDelegate -like "none") {
        $SecretaryDelegate = $null
    }

    switch ($Direction) {
        "1" {
            Invoke-CheckFullAccess `
                -SecretaryDelegate      $SecretaryDelegate `
                -FeeEarnerTargetMailbox $FeeEarnerTargetMailbox `
                -OperationResults       $OperationResults
        }
        "2" {
            Invoke-CheckFolderPermissions `
                -SecretaryDelegate      $SecretaryDelegate `
                -FeeEarnerTargetMailbox $FeeEarnerTargetMailbox `
                -OperationResults       $OperationResults
        }
        "3" {
            Invoke-CheckPrivateItems `
                -SecretaryDelegate      $SecretaryDelegate `
                -FeeEarnerTargetMailbox $FeeEarnerTargetMailbox `
                -OperationResults       $OperationResults
        }
        "4" {
            Invoke-CheckFullAccess `
                -SecretaryDelegate      $SecretaryDelegate `
                -FeeEarnerTargetMailbox $FeeEarnerTargetMailbox `
                -OperationResults       $OperationResults
            Invoke-CheckFolderPermissions `
                -SecretaryDelegate      $SecretaryDelegate `
                -FeeEarnerTargetMailbox $FeeEarnerTargetMailbox `
                -OperationResults       $OperationResults
        }
        "5" {
            Invoke-CheckFullAccess `
                -SecretaryDelegate      $SecretaryDelegate `
                -FeeEarnerTargetMailbox $FeeEarnerTargetMailbox `
                -OperationResults       $OperationResults
            Invoke-CheckPrivateItems `
                -SecretaryDelegate      $SecretaryDelegate `
                -FeeEarnerTargetMailbox $FeeEarnerTargetMailbox `
                -OperationResults       $OperationResults
        }
        "6" {
            Invoke-CheckFolderPermissions `
                -SecretaryDelegate      $SecretaryDelegate `
                -FeeEarnerTargetMailbox $FeeEarnerTargetMailbox `
                -OperationResults       $OperationResults
            Invoke-CheckPrivateItems `
                -SecretaryDelegate      $SecretaryDelegate `
                -FeeEarnerTargetMailbox $FeeEarnerTargetMailbox `
                -OperationResults       $OperationResults
        }
        "7" {
            Invoke-CheckFullAccess `
                -SecretaryDelegate      $SecretaryDelegate `
                -FeeEarnerTargetMailbox $FeeEarnerTargetMailbox `
                -OperationResults       $OperationResults
            Invoke-CheckFolderPermissions `
                -SecretaryDelegate      $SecretaryDelegate `
                -FeeEarnerTargetMailbox $FeeEarnerTargetMailbox `
                -OperationResults       $OperationResults
            Invoke-CheckPrivateItems `
                -SecretaryDelegate      $SecretaryDelegate `
                -FeeEarnerTargetMailbox $FeeEarnerTargetMailbox `
                -OperationResults       $OperationResults
        }
    }

    # Per-operation summary printed immediately
    Write-Host ""
    Write-Host "--------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "Summary for this operation:"                        -ForegroundColor DarkCyan
    Write-Host "--------------------------------------------------" -ForegroundColor DarkCyan
    $OperationResults | Format-Table Secretary, Folder, Action, Status, Error -AutoSize

    # Tag each result with the queue number for later grouping
    foreach ($Row in $OperationResults) {
        $Row | Add-Member -NotePropertyName QueueNumber -NotePropertyValue $QueueNumber -Force
    }

    $Results.Value += $OperationResults
}

# Master Results collection across all operations
$Results = @()

# Choose input mode
Write-Host "`n==========================" -ForegroundColor White
Write-Host "Mailbox Delegation Checker"   -ForegroundColor White
Write-Host "============================" -ForegroundColor White
Write-Host "`nSelect input mode:"         -ForegroundColor Cyan
Write-Host "1 - Manual entry (loop until you choose to exit)"  -ForegroundColor Yellow
Write-Host "2 - CSV import (bulk process from $CsvInputPath)"  -ForegroundColor Yellow
$InputMode = Read-Host "`nEnter 1 or 2"

if ($InputMode -notin @("1", "2")) {
    Write-Host "Invalid selection. Please enter 1 or 2." -ForegroundColor Red
    Exit
}

# Manual Mode - Collect all entries first, then process in bulk
if ($InputMode -eq "1") {
    $PendingOperations = [System.Collections.Generic.List[object]]::new()
    $Continue          = $true
    $EntryNumber       = 0

    Write-Host "`n==================================================" -ForegroundColor Cyan
    Write-Host "Enter checks to queue. Processing begins after you choose to stop adding more." -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan

    while ($Continue) {
        $EntryNumber++
        Write-OperationSeparator -Title "Queue Entry #$EntryNumber"

        $FeeEarnerTargetMailbox = (Read-Host "Enter fee earner/mailbox email address").Trim()
        $SecretaryDelegate      = (Read-Host "Enter secretary/delegate email address (or 'none' to check all)").Trim()

        Write-Host "`nSelect check:"                                           -ForegroundColor Cyan
        Write-Host "1 - Full Mailbox Access only"                             -ForegroundColor Yellow
        Write-Host "2 - Folder Permissions only"                              -ForegroundColor Yellow
        Write-Host "3 - Private Items only"                                   -ForegroundColor Yellow
        Write-Host "4 - Full Mailbox Access + Folder Permissions"             -ForegroundColor Yellow
        Write-Host "5 - Full Mailbox Access + Private Items"                  -ForegroundColor Yellow
        Write-Host "6 - Folder Permissions + Private Items"                   -ForegroundColor Yellow
        Write-Host "7 - All (Full Mailbox Access + Folders + Private Items)"  -ForegroundColor Yellow
        $Direction = Read-Host "`nEnter 1, 2, 3, 4, 5, 6 or 7"

        if ($Direction -notin @("1", "2", "3", "4", "5", "6", "7")) {
            Write-Host "Invalid selection." -ForegroundColor Red
            $EntryNumber--
            continue
        }

        $PendingOperations.Add([PSCustomObject]@{
            SecretaryDelegate      = $SecretaryDelegate
            FeeEarnerTargetMailbox = $FeeEarnerTargetMailbox
            Direction              = $Direction
        })

        if ($SecretaryDelegate -eq "" -or $SecretaryDelegate -like "none") {
            $DisplaySecretary = "All"
        }
        else {
            $DisplaySecretary = $SecretaryDelegate
        }

        Write-Host "`nQueued entry $EntryNumber :" -ForegroundColor Green
        Write-Host "  Fee Earner: $FeeEarnerTargetMailbox" -ForegroundColor Gray
        Write-Host "  Secretary : $DisplaySecretary"       -ForegroundColor Gray
        Write-Host "  Direction : $Direction"              -ForegroundColor Gray
        Write-Host ""

        $Another = Read-Host "Do you want to add another entry to the queue? (yes/no)"
        if ($Another -notlike "yes") {
            $Continue = $false
        }
    }

    # Show queue summary and confirm before processing
    if ($PendingOperations.Count -eq 0) {
        Write-Host "`nNo entries queued. Exiting." -ForegroundColor Yellow
        Exit
    }

    Write-OperationSeparator -Title "QUEUE READY"
    Write-Host "The following $($PendingOperations.Count) checks will be processed:" -ForegroundColor Cyan
    Write-Host ""
    $PendingOperations | Format-Table SecretaryDelegate, FeeEarnerTargetMailbox, Direction -AutoSize

    $Confirm = Read-Host "Proceed with all $($PendingOperations.Count) checks? (yes/no)"
    if ($Confirm -notlike "yes") {
        Write-Host "Operation cancelled - nothing processed." -ForegroundColor Yellow
        Exit
    }

    $OpNumber = 0
    foreach ($Op in $PendingOperations) {
        $OpNumber++
        Write-OperationSeparator -Title "Processing $OpNumber of $($PendingOperations.Count)"

        if ($Op.SecretaryDelegate -eq "" -or $Op.SecretaryDelegate -like "none") {
            $DisplaySecretary = "All"
        }
        else {
            $DisplaySecretary = $Op.SecretaryDelegate
        }

        Write-Host "Fee Earner: $($Op.FeeEarnerTargetMailbox)" -ForegroundColor White
        Write-Host "Secretary : $DisplaySecretary"             -ForegroundColor White
        Write-Host "Direction : $($Op.Direction)"              -ForegroundColor White
        Write-Host ""

        Invoke-CheckOperation `
            -SecretaryDelegate      $Op.SecretaryDelegate `
            -FeeEarnerTargetMailbox $Op.FeeEarnerTargetMailbox `
            -Direction              $Op.Direction `
            -QueueNumber            $OpNumber `
            -Results                ([ref]$Results)
    }
}

# CSV Mode - Bulk process from hardcoded path
# Expected CSV columns: SecretaryDelegate, FeeEarnerTargetMailbox, Direction
# SecretaryDelegate can be blank or 'none' to check all permissions
# Direction must be 1 through 7
if ($InputMode -eq "2") {
    if (-not (Test-Path $CsvInputPath)) {
        Write-Host "CSV file not found at hardcoded path: $CsvInputPath" -ForegroundColor Red
        Exit
    }

    Try {
        $CsvEntries = Import-Csv -Path $CsvInputPath -ErrorAction Stop
    }
    Catch {
        Write-Host "Failed to import CSV: $($_.Exception.Message)" -ForegroundColor Red
        Exit
    }

    $RequiredCols = @("SecretaryDelegate", "FeeEarnerTargetMailbox", "Direction")
    $CsvCols      = $CsvEntries[0].PSObject.Properties.Name
    $MissingCols  = $RequiredCols | Where-Object { $_ -notin $CsvCols }

    if ($MissingCols) {
        Write-Host "CSV is missing required columns: $($MissingCols -join ', ')" -ForegroundColor Red
        Write-Host "Required columns are: SecretaryDelegate, FeeEarnerTargetMailbox, Direction" -ForegroundColor Yellow
        Exit
    }

    Write-Host "`nFound $($CsvEntries.Count) entries in $CsvInputPath" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor White
    $CsvEntries | Format-Table SecretaryDelegate, FeeEarnerTargetMailbox, Direction -AutoSize
    Write-Host "==================================================" -ForegroundColor White

    $Confirm = Read-Host "`nProcess all $($CsvEntries.Count) entries? (yes/no)"
    if ($Confirm -notlike "yes") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        Exit
    }

    $EntryNumber = 0
    foreach ($Entry in $CsvEntries) {
        $EntryNumber++
        $EntrySecretary = $Entry.SecretaryDelegate.Trim()
        $EntryMailbox   = $Entry.FeeEarnerTargetMailbox.Trim()
        $EntryDirection = $Entry.Direction.Trim()

        Write-OperationSeparator -Title "Entry $EntryNumber of $($CsvEntries.Count)"

        if ($EntrySecretary -eq "" -or $EntrySecretary -like "none") {
            $DisplaySecretary = "All"
        }
        else {
            $DisplaySecretary = $EntrySecretary
        }

        Write-Host "Fee Earner: $EntryMailbox"     -ForegroundColor White
        Write-Host "Secretary : $DisplaySecretary" -ForegroundColor White
        Write-Host "Direction : $EntryDirection"   -ForegroundColor White
        Write-Host ""

        if ($EntryDirection -notin @("1", "2", "3", "4", "5", "6", "7")) {
            Write-Host "Skipping - invalid Direction value: $EntryDirection" -ForegroundColor Red
            $Results += [PSCustomObject]@{
                Secretary   = $DisplaySecretary
                Mailbox     = $EntryMailbox
                Folder      = "N/A"
                Action      = "Skipped"
                Status      = "Failed"
                Error       = "Invalid Direction value: $EntryDirection"
                QueueNumber = $EntryNumber
            }
            continue
        }

        Invoke-CheckOperation `
            -SecretaryDelegate      $EntrySecretary `
            -FeeEarnerTargetMailbox $EntryMailbox `
            -Direction              $EntryDirection `
            -QueueNumber            $EntryNumber `
            -Results                ([ref]$Results)
    }
}

# Final Summary - grouped by queue entry, then by action, then by secretary
Write-OperationSeparator -Title "FINAL SUMMARY"

$SpacedResults = [System.Collections.Generic.List[object]]::new()

$ActionOrder = @(
    "Check Full Access",
    "Check Folder Permission",
    "Check Private Items"
)

# Group all results by queue entry first
$QueueGroups = $Results | Group-Object QueueNumber | Sort-Object { [int]$_.Name }

foreach ($QueueGroup in $QueueGroups) {
    # Header row for this queue entry
    $SpacedResults.Add([PSCustomObject]@{
        Secretary = "########## Queue Entry $($QueueGroup.Name) ##########"
        Mailbox   = ""
        Folder    = ""
        Action    = ""
        Status    = ""
        Error     = ""
    })

    foreach ($ActionType in $ActionOrder) {
        $ActionResults = $QueueGroup.Group | Where-Object { $_.Action -eq $ActionType }

        if (-not $ActionResults) {
            continue
        }

        $SpacedResults.Add([PSCustomObject]@{
            Secretary = "--- $ActionType ---"
            Mailbox   = ""
            Folder    = ""
            Action    = ""
            Status    = ""
            Error     = ""
        })

        foreach ($Row in ($ActionResults | Sort-Object { [string]$_.Secretary })) {
            $SpacedResults.Add([PSCustomObject]@{
                Secretary = $Row.Secretary
                Mailbox   = $Row.Mailbox
                Folder    = $Row.Folder
                Action    = $Row.Action
                Status    = $Row.Status
                Error     = $Row.Error
            })
        }
    }

    # Catch any results with an Action not in the predefined list
    $OtherResults = $QueueGroup.Group | Where-Object { $_.Action -notin $ActionOrder }
    if ($OtherResults) {
        $SpacedResults.Add([PSCustomObject]@{
            Secretary = "--- Other ---"
            Mailbox   = ""
            Folder    = ""
            Action    = ""
            Status    = ""
            Error     = ""
        })
        foreach ($Row in ($OtherResults | Sort-Object { [string]$_.Secretary })) {
            $SpacedResults.Add([PSCustomObject]@{
                Secretary = $Row.Secretary
                Mailbox   = $Row.Mailbox
                Folder    = $Row.Folder
                Action    = $Row.Action
                Status    = $Row.Status
                Error     = $Row.Error
            })
        }
    }

    # Blank row between queue entries for spacing
    $SpacedResults.Add([PSCustomObject]@{
        Secretary = ""
        Mailbox   = ""
        Folder    = ""
        Action    = ""
        Status    = ""
        Error     = ""
    })
}

$SpacedResults | Format-Table Secretary, Mailbox, Folder, Action, Status, Error -AutoSize

# Export results to CSV
$Timestamp   = Get-Date -Format "dd_MM_yyyy-HH_mm_ss"
$ResultsPath = Join-Path $PSScriptRoot "DelegationCheck-$Timestamp.csv"
$SpacedResults | Export-Csv -Path $ResultsPath -NoTypeInformation
Write-Host "Results exported to $ResultsPath" -ForegroundColor Green