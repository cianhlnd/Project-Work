<#

Runs automatically in the LeaverAutomation batch file

Example
  C:\FileServersLeaverScript.ps1 -Csv C:\leavers.csv
  # leavers.csv columns: samAccountName (or SamAccountName), optional LeaverType

Notes
  Needs permissions to move delete FSLogix and ODFC files and move the documents to the correct locations
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
	# Provide users directly and enter in powershell command: -Users jbloggs
    [Parameter(ParameterSetName="Users", Mandatory)]
    [string[]]$Users,

	# Provide a text file with one username per line
    [Parameter(ParameterSetName="UserFile", Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string]$UserFile,#>

	# Provide a CSV with UserID/Username column
    [Parameter(ParameterSetName="Csv", Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string]$Csv,

	# Where to write logs/reports
    [string]$LogFolder = "C:\Logs\Files-Script-Logs",
	
	# Max Users safety guard paramter
	[ValidateRange(1, 500)]
	[int]$MaxUsers = 25,

	[switch]$OverrideMaxUsers
)

# Roots for vdifiles locations
$FsLogix2019ProfileRoot = "C:\MS2019_Profiles"
$Odfc2019Root    		= "C:\MS2019_O365"
$ITProfile2019Root    	= "C:\MS2019_Profiles_IT"
$ITOdfc2019Root    	    = "C:\MS2019_O365_IT"
$FsLogix2025ProfileRoot = "C:\MS2025_Profiles"
$Odfc2025Root    		= "C:\MS2025_O365"
$ITProfile2025Root    	= "C:\MS2025_Profiles_IT"
$ITOdfc2025Root    	    = "C:\MS2025_O365_IT"

# Roots for gcsafs
$FavouritesRoot = "C:\my_favorites"
$DownloadsRoot = "C:\my_downloads"
$DocumentsRoot = "C:\my_documents"


$DocumentsFolderName = "Documents"
$BindersFolderName   = "My Binders"

# Roots for svrnas
$DocumentsArchiveRoot = "C:\ArchiveLeavers"
$BindersArchiveRoot   = "C:\ArchiveLeavers\My Binders Archive"
$DownloadsTargetFolderName = ""

# 
function Ensure-LogFolder {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

# Input block
function Get-InputUsers {
    switch ($PSCmdlet.ParameterSetName) {
        "Users"    { $Users }
        "UserFile" { Get-Content $UserFile }
        "Csv" {
            $rows = Import-Csv $Csv
            $col = @("Username","username","UserID") |
                Where-Object { $_ -in $rows[0].PSObject.Properties.Name } |
                Select-Object -First 1
            if (-not $col) { throw "CSV must contain Username column." }
            $rows.$col
        }
        default { throw "Unknown input type." }
    }
}

# Check for no Regex function
function Assert-SafeUsername {
    param([Parameter(Mandatory)][string]$Username)

    # Typical samAccountName-safe characters; blocks *, ?, slashes, and ..
    if ($Username -notmatch '^[A-Za-z0-9._-]+$') {
        throw "Unsafe username input: '$Username' (wildcards or path characters not allowed)"
    }
}

# Check to see if .vhdx file is locked out before deletion
function Test-FileLocked {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return $false }

    try {
        $fs = [System.IO.File]::Open($Path,'Open','ReadWrite','None')
        $fs.Close()
        return $false
    }
    catch {
        return $true
    }
}

function Test-FolderHasLockedVhdx {
	param([Parameter(Mandatory)][string]$FolderPath)

	if (-not (Test-Path -LiteralPath $FolderPath)) { return $false }

	$vhdxFiles = Get-ChildItem -LiteralPath $FolderPath -Filter *.vhd* -File -ErrorAction SilentlyContinue
	foreach ($f in $vhdxFiles) {
		if (Test-FileLocked $f.FullName) { return $true }
	}
	return $false
}

# Delete User folders
function Remove-UserFolder {
	param(
		[Parameter(Mandatory)][string]$UserFolderPath,
		[Parameter(Mandatory)][string]$Label
	)

	# Folder does not exist
	if (-not (Test-Path -LiteralPath $UserFolderPath)) {
		return "NotFound"
	}

	# Locked VHDX check
	if (Test-FolderHasLockedVhdx -FolderPath $UserFolderPath) {
		return "SkippedLocked: $UserFolderPath"
	}

	try {
		if ($PSCmdlet.ShouldProcess($UserFolderPath, "Delete $Label '$username' folder")) {

			Remove-Item -LiteralPath $UserFolderPath -Recurse -Force -ErrorAction Stop

			return "Deleted"
		}
		else {
			return "SkippedWhatIf"
		}
	}
	catch {
		return "Error: $($_.Exception.Message)"
	}
}

function Move-FolderRobocopy {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    if ($WhatIfPreference) {
        Write-Host "WhatIf: Would robocopy '$Source' to '$Destination'" -ForegroundColor DarkYellow
        return 0
    }

    # Convert UNC paths to long-path-aware format
    $longSource = $Source -replace '^\\\\', '\\?\UNC\'
    $longDest   = $Destination -replace '^\\\\', '\\?\UNC\'

    $roboArgs = @(
        $longSource,
        $longDest,
        '/E',
        '/MOVE',
        '/COPY:DAT',
        '/DCOPY:DAT',
        '/R:2',
        '/W:2',
        '/256',
        '/NP',
        "/LOG:$LogFolder\robocopy_debug.log"
    )

    & robocopy @roboArgs

    $exitCode = $LASTEXITCODE

    Write-Host "Robocopy exit code: $exitCode" -ForegroundColor DarkCyan

    return $exitCode
}

# Main

Ensure-LogFolder $LogFolder

$timestamp = Get-Date -Format "dd_MM_yyyy_HH_mm_ss"
$logPath = Join-Path $LogFolder "Leavers_FileServer_$timestamp.log"
$csvPath = Join-Path $LogFolder "Leavers_FileServer_Report_$timestamp.csv"

$transcribing = $false
try {
    Start-Transcript -Path $logPath -Force | Out-Null
    $transcribing = $true
}
catch {
    Write-Warning "Transcript could not be started: $($_.Exception.Message)"
}

$report = New-Object System.Collections.Generic.List[object]
$usersToProcess = Get-InputUsers | Where-Object { $_ -and $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }

if (-not $OverrideMaxUsers -and $usersToProcess.Count -gt $MaxUsers) {
    throw "Safety stop: $($usersToProcess.Count) users supplied. Maximum allowed is $MaxUsers. Use -OverrideMaxUsers to proceed."
}

Write-Host "Processing $($usersToProcess.Count) user(s)..." -ForegroundColor Cyan

foreach ($username in $usersToProcess) {
    # Safety guard against wildcards/path traversal
    Assert-SafeUsername -Username $username

    Write-Host "`nProcessing: $username" -ForegroundColor Yellow

    # CSV rows
    $row = [ordered]@{
        Username                = $username
        Odfc2019Deleted         = $null
        ITOdfc2019Deleted       = $null
        Odfc2025Deleted         = $null
        ITOdfc2025Deleted       = $null
        Profile2019Deleted      = $null
        ITProfile2019Deleted    = $null
        Profile2025Deleted      = $null
        ITProfile2025Deleted    = $null
        FavouritesDeleted       = $null
        DownloadsMoved          = $null
        BindersArchived         = $null
        DocumentsArchived       = $null
        DocumentsSourceRemoved  = $null
        Errors                  = $null
    }

    try {
        # FSLogix user folder paths
        $profile2019Folder    = Join-Path $FsLogix2019ProfileRoot $username
        $odfc2019Folder       = Join-Path $Odfc2019Root           $username
        $ITprofile2019Folder  = Join-Path $ITProfile2019Root      $username
        $ITodfc2019Folder     = Join-Path $ITOdfc2019Root         $username
        $profile2025Folder    = Join-Path $FsLogix2025ProfileRoot $username
        $odfc2025Folder       = Join-Path $Odfc2025Root           $username
        $ITprofile2025Folder  = Join-Path $ITProfile2025Root      $username
        $ITodfc2025Folder     = Join-Path $ITOdfc2025Root         $username

        # Redirected paths
        $favUserPath       = Join-Path $FavouritesRoot $username
        $downloadsUserPath = Join-Path $DownloadsRoot  $username
        $docsUserRoot      = Join-Path $DocumentsRoot  $username
        $docsFolderPath    = Join-Path $docsUserRoot   $DocumentsFolderName
        $bindersPath       = Join-Path $docsFolderPath $BindersFolderName

        # Helper scriptblock to append errors safely
        $appendError = {
            param($msg)
            $row.Errors = (@($row.Errors, $msg) -join " | ").Trim(" |")
        }

        # Delete 2019 FSLogix Profile folder
        Write-Host "Deleting 2019 FSLogix Profile folder..." -ForegroundColor DarkCyan
        $result = Remove-UserFolder $profile2019Folder "2019 FSLogix Profile"
        $row.Profile2019Deleted = $result
        if ($result -like "SkippedLocked:*" -or $result -like "Error:*") { & $appendError $result }

        # Delete 2019 IT FSLogix folder
        Write-Host "Deleting 2019 IT FSLogix Profile folder..." -ForegroundColor DarkCyan
        $result = Remove-UserFolder $ITprofile2019Folder "2019 IT FSLogix Profile"
        $row.ITProfile2019Deleted = $result
        if ($result -like "SkippedLocked:*" -or $result -like "Error:*") { & $appendError $result }

        # Delete 2019 ODFC folder
        Write-Host "Deleting 2019 ODFC folder..." -ForegroundColor DarkCyan
        $result = Remove-UserFolder $odfc2019Folder "2019 ODFC Profile"
        $row.Odfc2019Deleted = $result
        if ($result -like "SkippedLocked:*" -or $result -like "Error:*") { & $appendError $result }

        # Delete 2019 IT ODFC folder
        Write-Host "Deleting 2019 IT ODFC folder..." -ForegroundColor DarkCyan
        $result = Remove-UserFolder $ITodfc2019Folder "2019 IT ODFC Profile"
        $row.ITOdfc2019Deleted = $result
        if ($result -like "SkippedLocked:*" -or $result -like "Error:*") { & $appendError $result }

        # Delete 2025 FSLogix Profile folder
        Write-Host "Deleting 2025 FSLogix Profile folder..." -ForegroundColor DarkCyan
        $result = Remove-UserFolder $profile2025Folder "2025 FSLogix Profile"
        $row.Profile2025Deleted = $result
        if ($result -like "SkippedLocked:*" -or $result -like "Error:*") { & $appendError $result }

        # Delete 2025 IT FSLogix Profile folder
        Write-Host "Deleting 2025 IT FSLogix Profile folder..." -ForegroundColor DarkCyan
        $result = Remove-UserFolder $ITprofile2025Folder "2025 IT FSLogix Profile"
        $row.ITProfile2025Deleted = $result
        if ($result -like "SkippedLocked:*" -or $result -like "Error:*") { & $appendError $result }

        # Delete 2025 ODFC folder
        Write-Host "Deleting 2025 ODFC folder..." -ForegroundColor DarkCyan
        $result = Remove-UserFolder $odfc2025Folder "2025 ODFC Profile"
        $row.Odfc2025Deleted = $result
        if ($result -like "SkippedLocked:*" -or $result -like "Error:*") { & $appendError $result }

        # Delete 2025 IT ODFC folder
        Write-Host "Deleting 2025 IT ODFC folder..." -ForegroundColor DarkCyan
        $result = Remove-UserFolder $ITodfc2025Folder "2025 IT ODFC Profile"
        $row.ITOdfc2025Deleted = $result
        if ($result -like "SkippedLocked:*" -or $result -like "Error:*") { & $appendError $result }

        # Delete Favourites
        Write-Host "Deleting Favourites folder..." -ForegroundColor DarkCyan
        $result = Remove-UserFolder $favUserPath "Favourites Folder"
        $row.FavouritesDeleted = $result
        if ($result -like "SkippedLocked:*" -or $result -like "Error:*") { & $appendError $result }

        # Rename + Move My Binders
        if (Test-Path -LiteralPath $bindersPath) {
            Write-Host "Archiving Binders..." -ForegroundColor DarkCyan
            $renamedBindersPath   = Join-Path $docsFolderPath    $username
            $bindersArchiveTarget = Join-Path $BindersArchiveRoot $username

            if ($PSCmdlet.ShouldProcess($bindersPath, "Rename '$BindersFolderName' to '$username'")) {
                Rename-Item -LiteralPath $bindersPath -NewName $username -Force -ErrorAction Stop
            }

            if ($PSCmdlet.ShouldProcess($renamedBindersPath, "Move renamed binders to $bindersArchiveTarget")) {
                if (-not (Test-Path -LiteralPath $BindersArchiveRoot)) {
                    New-Item -ItemType Directory -Path $BindersArchiveRoot -Force | Out-Null
                }
                $roboResult = Move-FolderRobocopy -Source $renamedBindersPath -Destination $bindersArchiveTarget
                if ($roboResult -lt 8) {
                    $row.BindersArchived = "Archived"
                } else {
                    $row.BindersArchived = "Error: Robocopy exit code $roboResult"
                }
            } else {
                $row.BindersArchived = "SkippedWhatIf"
            }
        } else {
            $row.BindersArchived = "NotFound"
        }

        # Move Downloads folder into docs user root
        if (Test-Path -LiteralPath $downloadsUserPath) {
            Write-Host "Moving Downloads folder..." -ForegroundColor DarkCyan
            $targetName = $DownloadsTargetFolderName
            if ([string]::IsNullOrWhiteSpace($targetName)) { $targetName = $username }

            if (-not (Test-Path -LiteralPath $docsUserRoot)) {
                if ($PSCmdlet.ShouldProcess($docsUserRoot, "Create missing documents user root")) {
                    New-Item -ItemType Directory -Path $docsUserRoot -Force | Out-Null
                }
            }

            $downloadsTarget = Join-Path $docsUserRoot $targetName
            if ($PSCmdlet.ShouldProcess($downloadsUserPath, "Move downloads folder to $downloadsTarget")) {
                $roboResult = Move-FolderRobocopy -Source $downloadsUserPath -Destination $downloadsTarget
                if ($roboResult -lt 8) {
                    $row.DownloadsMoved = "Moved"
                } else {
                    $row.DownloadsMoved = "Error: Robocopy exit code $roboResult"
                }
            } else {
                $row.DownloadsMoved = "SkippedWhatIf"
            }
        } else {
            $row.DownloadsMoved = "NotFound"
        }

        # Move Documents user root to archive root
        if (Test-Path -LiteralPath $docsUserRoot) {
            Write-Host "Archiving Documents root..." -ForegroundColor DarkCyan
            $expectedPath = Join-Path $DocumentsArchiveRoot $username

            if ($PSCmdlet.ShouldProcess($docsUserRoot, "Move documents root to $expectedPath")) {
                $roboResult = Move-FolderRobocopy -Source $docsUserRoot -Destination $expectedPath

                if ($roboResult -lt 8) {
                    if (Test-Path -LiteralPath $expectedPath) {
                        $row.DocumentsArchived = "Archived"
                        try {
                            Remove-Item -LiteralPath $docsUserRoot -Recurse -Force -ErrorAction Stop
                            $row.DocumentsSourceRemoved = "Removed"
                        }
                        catch {
                            $row.DocumentsSourceRemoved = "PermissionDenied"
                            & $appendError "Documents archived successfully but source folder could not be removed"
                        }
                    }
                    else {
                        $row.DocumentsArchived = "ArchiveMissing"
                        & $appendError "Robocopy succeeded but archive path not found: $expectedPath"
                    }
                }
                else {
                    $row.DocumentsArchived = "RobocopyFailed($roboResult)"
                    & $appendError "Documents archive failed with robocopy exit code $roboResult"
                }
            }
            else {
                $row.DocumentsArchived = "SkippedWhatIf"
                $row.DocumentsSourceRemoved = "SkippedWhatIf"
            }
        }
        else {
            $row.DocumentsArchived = "NotFound"
            $row.DocumentsSourceRemoved = "NotFound"
        }
    }
    catch {
        $row.Errors = (@($row.Errors, $_.Exception.Message) -join " | ").Trim(" |")
    }

    Write-Host ("[{0}] Profile2019: {1} | Profile2025: {2} | Odfc2019: {3} | Odfc2025: {4} | Favourites: {5} | Binders: {6} | Downloads: {7} | Documents: {8}" -f `
        $username,
        $row.Profile2019Deleted,
        $row.Profile2025Deleted,
        $row.Odfc2019Deleted,
        $row.Odfc2025Deleted,
        $row.FavouritesDeleted,
        $row.BindersArchived,
        $row.DownloadsMoved,
        $row.DocumentsArchived) -ForegroundColor Cyan

    if ($row.Errors) {
        Write-Warning "[$username] Errors: $($row.Errors)"
    }

    $report.Add([pscustomobject]$row) | Out-Null
}

$report | Export-Csv $csvPath -NoTypeInformation -Encoding UTF8

if ($transcribing) {
    try { Stop-Transcript | Out-Null } catch {}
}

Write-Host "Log:  $logPath"
Write-Host "CSV:  $csvPath"
Write-Host "`nDone." -ForegroundColor Green