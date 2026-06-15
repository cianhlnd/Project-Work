#Requires -Modules ActiveDirectory

<#
Leaver processing for on-prem AD users. Run this script first.
  - Accepts samAccountName
  - Routes users to the Expired OU
  - Removes group memberships (with a safe allowlist)
  - Clears selected attributes
  - Hides from address lists (if attribute exists)
  - Writes a CSV report + transcript log

Runs automatically in the LeaverAutomation batch file

Example
  C:\ADLeaverScript.ps1 -Csv C:\LeaverInput.csv -WhatIf

Notes
  Run from a machine with RSAT AD module installed.
  Needs permissions to move objects, modify users, and update group membership.
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    # Provide users directly (samAccountName or UPN)
    [Parameter(ParameterSetName="Users", Mandatory=$true)]
    [string[]]$Users,

    # Provide a text file with one identity per line (samAccountName or UPN)
    [Parameter(ParameterSetName="UserFile", Mandatory=$true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$UserFile,

    # Provide a CSV with a column such as: UserID / Username
    [Parameter(ParameterSetName="Csv", Mandatory=$true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$Csv,

    # Where to write logs/reports
    [string]$LogFolder = "C:\Logs\AD-Script-Logs",
	
	[ValidateRange(1, 500)]
	[int]$MaxUsers = 25,

	[switch]$OverrideMaxUsers
)

# Leavers OU location map (keys are logical names used by script)
$OuMap = @{
    Expired = "OU=Expired,OU=Leavers,DC=company,DC=com"
}

# Key of the target OU in $OuMap
$ExpiredOU = "Expired"

# Group names to keep (everything else removed)
$KeepGroupsByName = @(
    "Domain Users",
    "MailboxLicence"
)

# Attributes to clear
$ClearAttributes = @(
	"description",                
	#"mail",                 	   
	"mobile",
	"facsimileTelephoneNumber",                
	"homePhone",                
	"ipPhone",                
	"pager",
	"telephoneNumber",
    "physicalDeliveryOfficeName", 
    "wWWHomePage",                 
    "title",                       
    "department",                  
    "company",                     
    "manager"                      
)

function Ensure-LogFolder {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

# Reject wildcards/patterns to avoid accidental broad matches
function Assert-ManualIdentitiesOnly {
    param([string[]]$Identities)

    foreach ($s in $Identities) {
        if (-not $s) { continue }
        $t = $s.Trim()

        # Block PowerShell wildcard characters
        if ($t.IndexOfAny(@('*','?','[',']')) -ge 0) {
            throw "Invalid identity '$t' - wildcard/pattern characters are not allowed. Enter explicit samAccountName or UPN only."
        }

        # Block whitespace
        if ($t -match '\s') {
            throw "Invalid identity '$t' - spaces are not allowed."
        }
    }
}

# Input function to take in leaver identities (samAccountName or UPN)
function Get-InputUsers {
    param()

    switch ($PSCmdlet.ParameterSetName) {
        "Users" {
            return $Users | Where-Object { $_ -and $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }
        }
        "UserFile" {
            return Get-Content -Path $UserFile | Where-Object { $_ -and $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }
        }
        "Csv" {
			$rows = Import-Csv -Path $Csv

			if (-not $rows -or $rows.Count -eq 0) {
				throw "CSV '$Csv' has no data rows."
			}

			$candidateCols = @("UserID","Username","username")
			$headerNames = $rows[0].PSObject.Properties.Name
			$col = $candidateCols | Where-Object { $_ -in $headerNames } | Select-Object -First 1

			if (-not $col) {
				throw "CSV must contain one of these columns: $($candidateCols -join ', ')."
			}

			# Return objects with identity + optional leaving date
			return $rows | Where-Object { $_.$col -and $_.$col.Trim() -ne "" } | ForEach-Object {
				[PSCustomObject]@{
					Identity     = $_.$col.Trim()
					LeavingDate  = if ($_.PSObject.Properties["LeavingDate"] -and $_."LeavingDate".Trim()) {
									   $_."LeavingDate".Trim()
								   } else { $null }
				}
			}
		}
        default { throw "Unknown input type." }
    }
}

# Resolve AD user reliably from samAccountName OR UPN
function Resolve-AdUser {
    param(
        [Parameter(Mandatory)]
        [string]$Identity
    )

    $id = $Identity.Trim()

    # If UPN/email, find the user by filter first
    if ($id -like "*@*") {
        $hit = Get-ADUser -Filter "UserPrincipalName -eq '$id'" -ErrorAction Stop
        if (-not $hit) { throw "User not found for UPN '$id'." }

        # Re-query by -Identity to get a fully populated object (like your original script)
        return Get-ADUser -Identity $hit.SamAccountName -Properties Title, MemberOf, Enabled, AccountExpirationDate -ErrorAction Stop
    }

    # samAccountName path (same as original style)
    return Get-ADUser -Identity $id -Properties Title, MemberOf, Enabled, AccountExpirationDate -ErrorAction Stop
}

function Expire-AdUser {
    param(
        [Microsoft.ActiveDirectory.Management.ADUser]$User,
        [string]$LeavingDate = $null
    )

    try {
        # Parse leaving date if provided, otherwise fall back to now
        if ($LeavingDate) {
            try {
                $expiryDate = [datetime]::Parse($LeavingDate)
            }
            catch {
                return "ExpireError: Could not parse LeavingDate '$LeavingDate' - use a standard date format e.g. 2025-07-31"
            }
        }
        else {
            $expiryDate = Get-Date
        }

        $u = Get-ADUser -Identity $User.SamAccountName -Properties accountExpires, AccountExpirationDate -ErrorAction Stop
        $raw = [Int64]$u.accountExpires
        $isNever = ($raw -eq 0 -or $raw -eq 9223372036854775807)

        if ($isNever) {
            if ($PSCmdlet.ShouldProcess("$($u.SamAccountName)", "Set account expiration to $expiryDate (was Never)")) {
                Set-ADUser -Identity $u -AccountExpirationDate $expiryDate -Confirm:$false -ErrorAction Stop
            }
            return "ExpirySetTo($expiryDate)"
        }

        return "AlreadyHasExpiry($($u.AccountExpirationDate))"
    }
    catch {
        return "ExpireError: $($_.Exception.Message)"
    }
}

function Disable-AdUser {
    param(
        [Microsoft.ActiveDirectory.Management.ADUser]$User
    )

    try {
        if ($User.Enabled -eq $false) {
            return "AlreadyDisabled"
        }

        if ($PSCmdlet.ShouldProcess("$($User.SamAccountName)", "Disable account")) {
            Disable-ADAccount -Identity $User -Confirm:$false -ErrorAction Stop
        }

        return "Disabled"
    }
    catch {
        return "DisableError: $($_.Exception.Message)"
    }
}

function Remove-UserFromGroups {
    param(
        [Microsoft.ActiveDirectory.Management.ADUser]$User,
        [string[]]$KeepGroupNames
    )
	
	

    $result = @{
        Removed = 0
        Kept    = 0
        Errors  = 0
		RemovedNames = [System.Collections.Generic.List[string]]::new()
		KeptNames    = [System.Collections.Generic.List[string]]::new()
    }

    # MemberOf is DNs
    $memberOf = @($User.MemberOf)

    foreach ($groupDn in ($memberOf | Sort-Object -Unique)) {
        try {
            $g = Get-ADGroup -Identity $groupDn -ErrorAction Stop
            if ($KeepGroupNames -contains $g.Name) {
                $result.Kept++
				$result.KeptNames.Add($g.Name)
                continue
            }

            if ($PSCmdlet.ShouldProcess("$($User.SamAccountName)", "Remove from group $($g.Name)")) {
                Remove-ADGroupMember -Identity $g -Members $User -Confirm:$false -ErrorAction Stop
            }
            $result.Removed++
			$result.RemovedNames.Add($g.Name)
        }
        catch {
            $result.Errors++
        }
    }

    return $result
}

function Move-UserToOu {
    param(
        [Microsoft.ActiveDirectory.Management.ADUser]$User,
        [string]$TargetOuDn
    )

    if (-not $TargetOuDn) { return "NoTargetOU" }

    try {
        if ($PSCmdlet.ShouldProcess("$($User.SamAccountName)", "Move to $TargetOuDn")) {
            Move-ADObject -Identity $User.DistinguishedName -TargetPath $TargetOuDn -Confirm:$false -ErrorAction Stop
        }
        return "Moved"
    }
    catch {
        return "MoveError: $($_.Exception.Message)"
    }
}

function Clear-UserAttributes {
    param(
        [Microsoft.ActiveDirectory.Management.ADUser]$User,
        [string[]]$AttributesToClear
    )

    if (-not $AttributesToClear -or $AttributesToClear.Count -eq 0) { return "NoClear" }

    try {
        if ($PSCmdlet.ShouldProcess("$($User.SamAccountName)", "Clear attributes: $($AttributesToClear -join ', ')")) {
            Set-ADUser -Identity $User -Clear $AttributesToClear -ErrorAction Stop
        }
        return "Cleared"
    }
    catch {
        return "ClearError: $($_.Exception.Message)"
    }
}

function HideFromAddressBook {
    param(
        [Microsoft.ActiveDirectory.Management.ADUser]$User
    )

    try {
        # Attempt a read to confirm attribute is available
        $u = Get-ADUser $User.SamAccountName -Properties msExchHideFromAddressLists -ErrorAction Stop

        if ($PSCmdlet.ShouldProcess("$($User.SamAccountName)", "Set msExchHideFromAddressLists=$true")) {
            Set-ADUser -Identity $u -Replace @{ msExchHideFromAddressLists = $true } -Confirm:$false -ErrorAction Stop
        }
        return "HiddenFromAddressBook"
    }
    catch {
        return "HideFromABSkippedOrError: $($_.Exception.Message)"
    }
}

# Main
Import-Module ActiveDirectory -ErrorAction Stop

Ensure-LogFolder -Path $LogFolder

$timestamp = Get-Date -Format "dd_MM_yyyy-HH_mm_sss"
$logPath   = Join-Path $LogFolder "Leavers_$timestamp.log"
$csvPath   = Join-Path $LogFolder "Leavers_Report_$timestamp.csv"

$transcribing = $false
try {
    Start-Transcript -Path $logPath -Force | Out-Null
    $transcribing = $true
}
catch {
    Write-Warning "Transcript could not be started: $($_.Exception.Message)"
}

$inputUsers = Get-InputUsers

# Normalise + clean + dedupe
$inputUsers = $inputUsers |
    Where-Object { $_.Identity } |
    Sort-Object Identity -Unique

# Reject wildcards/patterns
Assert-ManualIdentitiesOnly -Identities ($inputUsers | Select-Object -ExpandProperty Identity)

# Safety limit
if (-not $OverrideMaxUsers -and $inputUsers.Count -gt $MaxUsers) {
    throw "Safety stop: $($usersToProcess.Count) users supplied. Maximum allowed is $MaxUsers. Use -OverrideMaxUsers to proceed."
}

Write-Host "Processing $($inputUsers.Count) user(s)..." -ForegroundColor Cyan

$report = New-Object System.Collections.Generic.List[object]

foreach ($entry in $inputUsers) {
	$identity = $entry.Identity
	
    $row = [ordered]@{
        InputIdentity      = $identity
        SamAccountName     = $null
        UserPrincipalName  = $null
        Found              = $false
        Title              = $null
        TargetOu           = $null
        MoveResult         = $null
        GroupsRemoved      = 0
        GroupsKept         = 0
		GroupRemoveErrors  = 0
		GroupsRemovedNames = $null
		GroupsKeptNames    = $null
        ClearResult        = $null
        HideFromAB         = $null
        AccountDisabled    = $null
        AccountExpired     = $null
        Errors             = $null
    }

    try {
        $user = Resolve-AdUser -Identity $identity

        $row.Found = $true
        $row.SamAccountName = $user.SamAccountName
        $row.UserPrincipalName = $user.UserPrincipalName
        $row.Title = $user.Title

        $targetOu = $OuMap[$ExpiredOU]
        $row.TargetOu = $targetOu

        # Disable account
        $row.AccountDisabled = Disable-AdUser -User $user

        # Ensure account is expired
        $row.AccountExpired = Expire-AdUser -User $user -LeavingDate $entry.LeavingDate

        # Remove from AD groups
        $gr = Remove-UserFromGroups -User $user -KeepGroupNames $KeepGroupsByName
        $row.GroupsRemoved     = $gr.Removed
        $row.GroupsKept        = $gr.Kept
		$row.GroupsRemovedNames = $gr.RemovedNames -join "; "
		$row.GroupsKeptNames    = $gr.KeptNames -join "; "
        $row.GroupRemoveErrors = $gr.Errors

        # Clear attributes
        $row.ClearResult = Clear-UserAttributes -User $user -AttributesToClear $ClearAttributes

        # Hide from address book (best-effort)
        $row.HideFromAB = HideFromAddressBook -User $user

        # Move to OU
        $row.MoveResult = Move-UserToOu -User $user -TargetOuDn $targetOu
    }
    catch {
        $row.Errors = $_.Exception.Message
    }
	
	Write-Host "[$identity] Disabled: $($row.AccountDisabled) | Account Expired: $($row.AccountExpired) | OU Moved: $($row.MoveResult) | Groups Removed: $($row.GroupsRemoved) | Attributes Cleared: $($row.ClearResult)" -ForegroundColor Cyan
    if ($row.Errors) {
		Write-Warning "[$identity] Errors: $($row.Errors)"
	}
	$report.Add([pscustomobject]$row) | Out-Null
}

$report | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

if ($transcribing) {
    try { Stop-Transcript | Out-Null } catch {}
}

Write-Host "Log:  $logPath"
Write-Host "Report CSV: $csvPath"
Write-Host "`nDone." -ForegroundColor Green