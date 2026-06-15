## Connect to Exchange Online if not already connected
$ExistingConnection = Get-ConnectionInformation -ErrorAction SilentlyContinue |
    Where-Object { $_.State -eq "Connected" -and $_.Name -like "ExchangeOnline*" }

if ($ExistingConnection) {
    Write-Host "Already connected to Exchange Online" -ForegroundColor Green
}
else {
    Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
    Connect-ExchangeOnline
}

# CSV input path - resolved relative to this script's own folder
# Expected columns: SecretaryDelegate, FeeEarnerTargetMailbox, Direction
$CsvInputPath = Join-Path $PSScriptRoot "MigrationInput.csv"

# Folders to not recurse into for subfolders, Top level permissions will still be set on these
$NoRecurseFolders = @(
    "Calendar",
    "Contacts",
    "Tasks",
    "Drafts",
    "Outbox"
)

# System/hidden folders to skip entirely
$SkipFolders = @(
    "Recoverable Items",
    "Deletions",
    "Purges",
    "Versions",
    "SubstrateHolds",
    "DiscoveryHolds",
    "Audits",
    "Calendar Logging",
    "Yammer Root",
    "Files",
    "Sync Issues",
    "Conflicts",
    "Local Failures",
    "Server Failures",
    "Journal",
    "PersonMetadata",
    "tessian-hidden",
    "Social Activity Notifications",
    "Conversation Action Settings",
    "Top of Information Store",
    "ExternalContacts",
    "EventCheckPoints",
    "Junk Email",
    "Quick Step Settings",
    "Conversation History",
    "News Feed",
    "RSS Subscriptions",
    "MeContact",
    "Suggested Contacts",
    "Bulk mail",
    "Notes",
    "Infected",
    "WCSE_FolderMappings",
    "WCSE_SFMailboxSync"
)

# Folders to skip during Direction 2 folder permission removal
# These keep their existing permissions so Outlook delegatesettings (Calendar in particular) are not wiped when reverting to Full Mailbox Access
$PreservePermsOnRevert = @(
    "Calendar"
)

# Helper function - Print a visual separator between operations
function Write-OperationSeparator {
    param([string]$Title)

    Write-Host ""
    Write-Host ""
    Write-Host "##################################################" -ForegroundColor Magenta
    Write-Host "##                                              ##" -ForegroundColor Magenta
    if ($Title) {
        $Padding = [Math]::Max(0, (46 - $Title.Length) / 2)
        $PadLeft  = " " * [Math]::Floor($Padding)
        $PadRight = " " * [Math]::Ceiling($Padding)
        Write-Host ("##" + $PadLeft + $Title + $PadRight + "##") -ForegroundColor Magenta
    }
    Write-Host "##                                              ##" -ForegroundColor Magenta
    Write-Host "##################################################" -ForegroundColor Magenta
    Write-Host ""
}

# Helper function - Apply PublishingEditor to a single folder
# Uses FolderId to safely handle special characters in names
function Set-DelegatePublishingEditor {
    param(
        [string]$Mailbox,
        [string]$Delegate,
        [string]$FolderId,
        [string]$FolderDisplayPath,
        [System.Collections.Generic.List[object]]$ResultsList
    )
    $FolderIdentity = $Mailbox + ":" + $FolderId
    Try {
        Add-MailboxFolderPermission `
            -Identity     $FolderIdentity `
            -User         $Delegate `
            -AccessRights "PublishingEditor" `
            -ErrorAction  Stop
        Write-Host "  [+] Granted  PublishingEditor : $FolderDisplayPath" -ForegroundColor Green
        $ResultsList.Add([PSCustomObject]@{
            Secretary = $Delegate
            Mailbox   = $Mailbox
            Folder    = $FolderDisplayPath
            Action    = "Add PublishingEditor"
            Status    = "Success"
            Error     = ""
        })
    }
    Catch {
        $AddError = $_.Exception.Message
        Try {
            Set-MailboxFolderPermission `
                -Identity     $FolderIdentity `
                -User         $Delegate `
                -AccessRights "PublishingEditor" `
                -ErrorAction  Stop
            Write-Host "  [~] Updated  PublishingEditor : $FolderDisplayPath" -ForegroundColor Yellow
            $ResultsList.Add([PSCustomObject]@{
                Secretary = $Delegate
                Mailbox   = $Mailbox
                Folder    = $FolderDisplayPath
                Action    = "Update PublishingEditor"
                Status    = "Success"
                Error     = ""
            })
        }
        Catch {
            Write-Host "  [!] Failed   PublishingEditor : $FolderDisplayPath - $($_.Exception.Message)" -ForegroundColor Red
            $ResultsList.Add([PSCustomObject]@{
                Secretary = $Delegate
                Mailbox   = $Mailbox
                Folder    = $FolderDisplayPath
                Action    = "PublishingEditor"
                Status    = "Failed"
                Error     = "Add: $AddError | Set: $($_.Exception.Message)"
            })
        }
    }
}

# Function - Process a single delegation operation
# Returns its own per-operation results so they can be summarised individually as well as aggregated
function Invoke-DelegationOperation {
    param(
        [string]$SecretaryDelegate,
        [string]$FeeEarnerTargetMailbox,
        [string]$Direction,
        [ref]$Results
    )

    $OperationResults = [System.Collections.Generic.List[object]]::new()

    
    # Direction 1 - Migrate Full Mailbox Access to Folder Permissions
    if ($Direction -eq "1") {
        Write-Host "Migrating from Full Mailbox Access to Folder Permissions..." -ForegroundColor Cyan
        Try {
            $FullAccessPerm = Get-MailboxPermission -Identity $FeeEarnerTargetMailbox -ErrorAction Stop |
                Where-Object {
                    $_.User         -eq $SecretaryDelegate -and
                    $_.AccessRights -eq "FullAccess"       -and
                    $_.IsInherited  -eq $false
                }
            if ($FullAccessPerm) {
                Remove-MailboxPermission `
                    -Identity     $FeeEarnerTargetMailbox `
                    -User         $SecretaryDelegate `
                    -AccessRights FullAccess `
                    -Confirm:$false
                Write-Host "Removed Full Access" -ForegroundColor Yellow
                $OperationResults.Add([PSCustomObject]@{
                    Secretary = $SecretaryDelegate
                    Mailbox   = $FeeEarnerTargetMailbox
                    Folder    = "N/A"
                    Action    = "Remove Full Access"
                    Status    = "Success"
                    Error     = ""
                })
            } else {
                Write-Host "No Full Access found to remove - continuing to set folder permissions" -ForegroundColor Gray
            }
        }
        Catch {
            Write-Host "Failed to remove Full Access: $($_.Exception.Message)" -ForegroundColor Red
            $OperationResults.Add([PSCustomObject]@{
                Secretary = $SecretaryDelegate
                Mailbox   = $FeeEarnerTargetMailbox
                Folder    = "N/A"
                Action    = "Remove Full Access"
                Status    = "Failed"
                Error     = $_.Exception.Message
            })
        }
        Try {
            Set-MailboxFolderPermission `
                -Identity     ($FeeEarnerTargetMailbox + ":\") `
                -User         "Default" `
                -AccessRights "FolderVisible"
            Write-Host "FolderVisible set on root folder" -ForegroundColor Green
            $OperationResults.Add([PSCustomObject]@{
                Secretary = $SecretaryDelegate
                Mailbox   = $FeeEarnerTargetMailbox
                Folder    = "\"
                Action    = "Set FolderVisible"
                Status    = "Success"
                Error     = ""
            })
        }
        Catch {
            Write-Host "Failed to set FolderVisible on root: $($_.Exception.Message)" -ForegroundColor Red
            $OperationResults.Add([PSCustomObject]@{
                Secretary = $SecretaryDelegate
                Mailbox   = $FeeEarnerTargetMailbox
                Folder    = "\"
                Action    = "Set FolderVisible"
                Status    = "Failed"
                Error     = $_.Exception.Message
            })
        }
        Write-Host "`nRetrieving all mailbox folders..." -ForegroundColor Cyan
        $AllFolderStats = Get-MailboxFolderStatistics -Identity $FeeEarnerTargetMailbox
        $TopLevelFolderStats = $AllFolderStats | Where-Object {
            $_.FolderPath -match "^/[^/]+$"
        }
        Write-Host "Found $($TopLevelFolderStats.Count) top-level folders" -ForegroundColor Gray
        Write-Host "`nProcessing top-level folders..." -ForegroundColor Cyan
        foreach ($Folder in $TopLevelFolderStats) {
            if ($SkipFolders -contains $Folder.Name) {
                Write-Host "  [>] Skipping system folder  : $($Folder.Name)" -ForegroundColor DarkGray
                continue
            }
            Set-DelegatePublishingEditor `
                -Mailbox           $FeeEarnerTargetMailbox `
                -Delegate          $SecretaryDelegate `
                -FolderId          $Folder.FolderId `
                -FolderDisplayPath $Folder.FolderPath `
                -ResultsList       $OperationResults
        }
        foreach ($RootFolder in $TopLevelFolderStats) {
            if ($SkipFolders      -contains $RootFolder.Name) { continue }
            if ($NoRecurseFolders -contains $RootFolder.Name) { continue }
            Write-Host "`nProcessing subfolders under $($RootFolder.Name)..." -ForegroundColor Cyan
            $SubFolders = $AllFolderStats | Where-Object {
                $_.FolderPath -like "/$($RootFolder.Name)/*"
            }
            if (-not $SubFolders) {
                Write-Host "  No subfolders found under $($RootFolder.Name)" -ForegroundColor Gray
                continue
            }
            foreach ($SubFolder in $SubFolders) {
                Set-DelegatePublishingEditor `
                    -Mailbox           $FeeEarnerTargetMailbox `
                    -Delegate          $SecretaryDelegate `
                    -FolderId          $SubFolder.FolderId `
                    -FolderDisplayPath $SubFolder.FolderPath `
                    -ResultsList       $OperationResults
            }
        }
    }

    # Direction 2 - Revert to Full Mailbox Access
    if ($Direction -eq "2") {

    Write-Host "`nReinstating Full Mailbox Access..." -ForegroundColor Cyan
        Try {
            Add-MailboxPermission `
                -Identity     $FeeEarnerTargetMailbox `
                -User         $SecretaryDelegate `
                -AccessRights FullAccess `
                -AutoMapping  $true `
                -Confirm:$false
            Write-Host "Reinstated Full Access with AutoMapping" -ForegroundColor Green
            $OperationResults.Add([PSCustomObject]@{
                Secretary = $SecretaryDelegate
                Mailbox   = $FeeEarnerTargetMailbox
                Folder    = "N/A"
                Action    = "Reinstate Full Access"
                Status    = "Success"
                Error     = ""
            })
        }
        Catch {
            Write-Host "Failed to reinstate Full Access: $($_.Exception.Message)" -ForegroundColor Red
            $OperationResults.Add([PSCustomObject]@{
                Secretary = $SecretaryDelegate
                Mailbox   = $FeeEarnerTargetMailbox
                Folder    = "N/A"
                Action    = "Reinstate Full Access"
                Status    = "Failed"
                Error     = $_.Exception.Message
            })
        }
        Write-Host "Removing all folder permissions for $SecretaryDelegate..." -ForegroundColor Cyan
        $AllFolders = Get-MailboxFolderStatistics -Identity $FeeEarnerTargetMailbox |
            Select-Object FolderPath, FolderId
        foreach ($Folder in $AllFolders) {

			# Skip preserved folders so delegate-relevant permissions (e.g. Calendar) survive the revert
			$TopLevelName = ($Folder.FolderPath -split "/")[1]
			if ($PreservePermsOnRevert -contains $TopLevelName) {
				Write-Host "  [>] Preserving permissions on : $($Folder.FolderPath)" -ForegroundColor DarkGray
				continue
			}

			$FolderIdentity = $FeeEarnerTargetMailbox + ":" + $Folder.FolderId
			Try {
				Remove-MailboxFolderPermission `
					-Identity    $FolderIdentity `
					-User        $SecretaryDelegate `
					-Confirm:$false `
					-ErrorAction Stop
                Write-Host "  [-] Removed folder permission : $($Folder.FolderPath)" -ForegroundColor Yellow
                $OperationResults.Add([PSCustomObject]@{
                    Secretary = $SecretaryDelegate
                    Mailbox   = $FeeEarnerTargetMailbox
                    Folder    = $Folder.FolderPath
                    Action    = "Remove Folder Permission"
                    Status    = "Success"
                    Error     = ""
                })
            }
            Catch {
                if ($_.Exception.Message -like "*No existing permission*" -or
                    $_.Exception.Message -like "*not found*" -or
					$_.Exception.Message -like "*Calendar sharing permissions cannot be granted*" -or
					$_.Exception.Message -like "*Specified method is not supported*") {
                    # Expected - delegate never had permission on this folder, silently skip
                }
                else {
                    Write-Host "  [!] Failed to remove permission : $($Folder.FolderPath) - $($_.Exception.Message)" -ForegroundColor Red
                    $OperationResults.Add([PSCustomObject]@{
                        Secretary = $SecretaryDelegate
                        Mailbox   = $FeeEarnerTargetMailbox
                        Folder    = $Folder.FolderPath
                        Action    = "Remove Folder Permission"
                        Status    = "Failed"
                        Error     = $_.Exception.Message
                    })
                }
            }
        }
    }

    # Direction 3 - Remove Folder Permissions onl
    if ($Direction -eq "3") {
        Write-Host "Removing all folder permissions for $SecretaryDelegate..." -ForegroundColor Cyan
        $AllFolders = Get-MailboxFolderStatistics -Identity $FeeEarnerTargetMailbox |
            Select-Object FolderPath, FolderId
        foreach ($Folder in $AllFolders) {
            $FolderIdentity = $FeeEarnerTargetMailbox + ":" + $Folder.FolderId
            Try {
                Remove-MailboxFolderPermission `
                    -Identity    $FolderIdentity `
                    -User        $SecretaryDelegate `
                    -Confirm:$false `
                    -ErrorAction Stop
                Write-Host "  [-] Removed folder permission : $($Folder.FolderPath)" -ForegroundColor Yellow
                $OperationResults.Add([PSCustomObject]@{
                    Secretary = $SecretaryDelegate
                    Mailbox   = $FeeEarnerTargetMailbox
                    Folder    = $Folder.FolderPath
                    Action    = "Remove Folder Permission"
                    Status    = "Success"
                    Error     = ""
                })
            }
            Catch {
                if ($_.Exception.Message -like "*No existing permission*" -or
                    $_.Exception.Message -like "*not found*" -or
					$_.Exception.Message -like "*Calendar sharing permissions cannot be granted*" -or
					$_.Exception.Message -like "*Specified method is not supported*") {
                    # Expected - delegate never had permission on this folder, silently skip
                }
                else {
                    Write-Host "  [!] Failed to remove permission : $($Folder.FolderPath) - $($_.Exception.Message)" -ForegroundColor Red
                    $OperationResults.Add([PSCustomObject]@{
                        Secretary = $SecretaryDelegate
                        Mailbox   = $FeeEarnerTargetMailbox
                        Folder    = $Folder.FolderPath
                        Action    = "Remove Folder Permission"
                        Status    = "Failed"
                        Error     = $_.Exception.Message
                    })
                }
            }
        }
    }

    # Direction 4 - Remove Full Mailbox Access only
    if ($Direction -eq "4") {
        Write-Host "Removing Full Mailbox Access for $SecretaryDelegate..." -ForegroundColor Cyan
        Try {
            $FullAccessPerm = Get-MailboxPermission -Identity $FeeEarnerTargetMailbox -ErrorAction Stop |
                Where-Object {
                    $_.User         -eq $SecretaryDelegate -and
                    $_.AccessRights -eq "FullAccess"       -and
                    $_.IsInherited  -eq $false
                }
            if ($FullAccessPerm) {
                Remove-MailboxPermission `
                    -Identity     $FeeEarnerTargetMailbox `
                    -User         $SecretaryDelegate `
                    -AccessRights FullAccess `
                    -Confirm:$false
                Write-Host "Removed Full Access" -ForegroundColor Yellow
                $OperationResults.Add([PSCustomObject]@{
                    Secretary = $SecretaryDelegate
                    Mailbox   = $FeeEarnerTargetMailbox
                    Folder    = "N/A"
                    Action    = "Remove Full Access"
                    Status    = "Success"
                    Error     = ""
                })
            } else {
                Write-Host "No Full Access found to remove" -ForegroundColor Gray
            }
        }
        Catch {
            Write-Host "Failed to remove Full Access: $($_.Exception.Message)" -ForegroundColor Red
            $OperationResults.Add([PSCustomObject]@{
                Secretary = $SecretaryDelegate
                Mailbox   = $FeeEarnerTargetMailbox
                Folder    = "N/A"
                Action    = "Remove Full Access"
                Status    = "Failed"
                Error     = $_.Exception.Message
            })
        }
    }

    # Per-operation summary printed immediately
    Write-Host ""
    Write-Host "--------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "Summary for this operation:"                       -ForegroundColor DarkCyan
    Write-Host "--------------------------------------------------" -ForegroundColor DarkCyan
    $OperationResults | Format-Table Folder, Action, Status, Error -AutoSize

    # Append per-operation results to master results
    $Results.Value += $OperationResults
}

# Master Results collection across all operations
$Results = @()

# Choose input mode
Write-Host "`n==============================" -ForegroundColor White
Write-Host "Mailbox Delegation Manager"                          -ForegroundColor White
Write-Host "==============================" -ForegroundColor White

Write-Host "`nSelect input mode:" -ForegroundColor Cyan
Write-Host "1 - Manual entry (loop until you choose to exit)"    -ForegroundColor Yellow
Write-Host "2 - CSV import (bulk process from $CsvInputPath)"    -ForegroundColor Yellow

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

    Write-Host "`n=================================================================================" -ForegroundColor Cyan
    Write-Host "Enter operations to queue. Processing begins after you choose to stop adding more."   -ForegroundColor Cyan
    Write-Host "===================================================================================" -ForegroundColor Cyan

    while ($Continue) {
        $EntryNumber++
        Write-OperationSeparator -Title "Queue Entry #$EntryNumber"

        $SecretaryDelegate      = (Read-Host "Enter secretary/delegate email address").Trim()
        $FeeEarnerTargetMailbox = (Read-Host "Enter fee earner/mailbox email address").Trim()

        Write-Host "`nSelect action:" -ForegroundColor Cyan
        Write-Host "1 - Migrate from Full Mailbox Access to Folder Permissions" -ForegroundColor Yellow
        Write-Host "2 - Revert from Folder Permissions to Full Mailbox Access"  -ForegroundColor Yellow
        Write-Host "3 - Remove Folder Permissions only (no Full Mailbox Access added)" -ForegroundColor Yellow
        Write-Host "4 - Remove Full Mailbox Access only (no Folder Permissions added)" -ForegroundColor Yellow

        $Direction = Read-Host "`nEnter 1, 2, 3 or 4"

        if ($Direction -notin @("1", "2", "3", "4")) {
            Write-Host "Invalid selection. Please enter 1, 2, 3 or 4." -ForegroundColor Red
            continue
        }

        # Queue the operation rather than running it immediately
        $PendingOperations.Add([PSCustomObject]@{
            SecretaryDelegate      = $SecretaryDelegate
            FeeEarnerTargetMailbox = $FeeEarnerTargetMailbox
            Direction              = $Direction
        })

        Write-Host "`nQueued entry $EntryNumber :" -ForegroundColor Green
        Write-Host "  Secretary : $SecretaryDelegate"      -ForegroundColor Gray
        Write-Host "  Fee Earner: $FeeEarnerTargetMailbox" -ForegroundColor Gray
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
    Write-Host "The following $($PendingOperations.Count) operations will be processed:" -ForegroundColor Cyan
    Write-Host ""
    $PendingOperations | Format-Table SecretaryDelegate, FeeEarnerTargetMailbox, Direction -AutoSize

    $Confirm = Read-Host "Proceed with all $($PendingOperations.Count) operations? (yes/no)"
    if ($Confirm -notlike "yes") {
        Write-Host "Operation cancelled - nothing processed." -ForegroundColor Yellow
        Exit
    }

    # Process the queue
    $OpNumber = 0
    foreach ($Op in $PendingOperations) {
        $OpNumber++
        Write-OperationSeparator -Title "Processing $OpNumber of $($PendingOperations.Count)"
        Write-Host "Secretary : $($Op.SecretaryDelegate)"      -ForegroundColor White
        Write-Host "Fee Earner: $($Op.FeeEarnerTargetMailbox)" -ForegroundColor White
        Write-Host "Direction : $($Op.Direction)"              -ForegroundColor White
        Write-Host ""

        Invoke-DelegationOperation `
            -SecretaryDelegate      $Op.SecretaryDelegate `
            -FeeEarnerTargetMailbox $Op.FeeEarnerTargetMailbox `
            -Direction              $Op.Direction `
            -Results                ([ref]$Results)
    }
}

# CSV Mode - Bulk process from hardcoded path
# Expected CSV columns: SecretaryDelegate, FeeEarnerTargetMailbox, Direction
# Direction must be 1, 2, 3, or 4
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

    # Validate columns
    $RequiredCols = @("SecretaryDelegate", "FeeEarnerTargetMailbox", "Direction")
    $CsvCols = $CsvEntries[0].PSObject.Properties.Name
    $MissingCols = $RequiredCols | Where-Object { $_ -notin $CsvCols }
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
        Write-Host "Secretary : $EntrySecretary"   -ForegroundColor White
        Write-Host "Fee Earner: $EntryMailbox"     -ForegroundColor White
        Write-Host "Direction : $EntryDirection"   -ForegroundColor White
        Write-Host ""

        if ($EntryDirection -notin @("1", "2", "3", "4")) {
            Write-Host "Skipping - invalid Direction value: $EntryDirection" -ForegroundColor Red
            $Results += [PSCustomObject]@{
                Secretary = $EntrySecretary
                Mailbox   = $EntryMailbox
                Folder    = "N/A"
                Action    = "Skipped"
                Status    = "Failed"
                Error     = "Invalid Direction value: $EntryDirection"
            }
            continue
        }

        Invoke-DelegationOperation `
            -SecretaryDelegate      $EntrySecretary `
            -FeeEarnerTargetMailbox $EntryMailbox `
            -Direction              $EntryDirection `
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
            $SpacedResults.Add($Row)
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
            $SpacedResults.Add($Row)
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
$ResultsPath = Join-Path $PSScriptRoot "IndividualMigrationScript-$Timestamp.csv"
$SpacedResults | Export-Csv -Path $ResultsPath -NoTypeInformation
Write-Host "Results exported to $ResultsPath" -ForegroundColor Green