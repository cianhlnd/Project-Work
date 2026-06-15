[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$Csv,

    [string]$LogFolder = "C:\Rotation_Logs"
)

# Load config from JSON file in the same directory as the script
$configPath = Join-Path $PSScriptRoot "RotationConfig.json"

if (-not (Test-Path $configPath)) {
    throw "Config file not found: $configPath"
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json

# Convert JSON objects to proper PowerShell hashtables
# AD config
$RotationGroups     = [string[]]$config.RotationGroups

$DepartmentGroups   = @{}
$config.DepartmentGroups.PSObject.Properties | ForEach-Object {
    $DepartmentGroups[$_.Name] = [string[]]$_.Value
}

$DepartmentNameMap  = @{}
$config.DepartmentNameMap.PSObject.Properties | ForEach-Object {
    $DepartmentNameMap[$_.Name] = $_.Value
}

$DepartmentOfficeMap = @{}
$config.DepartmentOfficeMap.PSObject.Properties | ForEach-Object {
    $DepartmentOfficeMap[$_.Name] = $_.Value
}

$DepartmentAliases  = @{}
$config.DepartmentAliases.PSObject.Properties | ForEach-Object {
    $DepartmentAliases[$_.Name] = $_.Value
}

# Shared Mailbox config
$SharedMailbox = $config.SharedMailbox.Identity
$SharedMailboxDepartments = [string[]]$config.SharedMailbox.Departments

# Functions

function Ensure-LogFolder {
    param([string]$Path)

    # Create the log folder if it does not already exist
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

function Resolve-AdUser {
    param([string]$Identity)

    try {
        # Try resolving by User Principal Name (Email)
        $user = Get-ADUser -Filter { UserPrincipalName -eq $Identity } -Properties MemberOf, Department, physicalDeliveryOfficeName -ErrorAction Stop

        if ($user) {
            return $user
        }

        # Fallback to SamAccountName (AD username)
        return Get-ADUser -Identity $Identity -Properties MemberOf, Department, physicalDeliveryOfficeName -ErrorAction Stop
    }
    catch {
        # Standardised error if user cannot be found by either method
        throw "User not found: $Identity"
    }
}

function Resolve-DepartmentName {
    param([string]$DepartmentValue)

    # Handle missing/blank department values early
    if ([string]::IsNullOrWhiteSpace($DepartmentValue)) {
        return "__MISSING__"
    }

    # Normalise input (trim + lowercase for comparisons)
    $cleanValue = $DepartmentValue.Trim()
    $cleanLower = $cleanValue.ToLower()

    # Check alias mapping first (e.g. "funds" - "Asset Management")
    if ($DepartmentAliases.ContainsKey($cleanLower)) {
        return $DepartmentAliases[$cleanLower]
    }

    # Then check direct match against canonical department keys (case-insensitive)
    foreach ($key in $DepartmentGroups.Keys) {
        if ($key.ToLower() -eq $cleanLower) {
            return $key
        }
    }

    # Return original value so validation can catch unmapped departments later
    return $cleanValue
}

function Set-RotationGroups {
    param(
        [Microsoft.ActiveDirectory.Management.ADUser]$User,
        [string]$Department
    )

    # Track changes for reporting
    $result = @{
        Removed       = 0
        Added         = 0
        Errors        = 0
        RemovedGroups = @()
        AddedGroups   = @()
    }

    # Validate department exists in mapping before proceeding
    if (-not $DepartmentGroups.ContainsKey($Department)) {
        return "Error: Unknown department '$Department'"
    }

    try {
        # Snapshot current group membership (names only)
        $currentGroups = Get-ADPrincipalGroupMembership -Identity $User |
                         Select-Object -ExpandProperty Name

        # Remove user from all rotation groups
        foreach ($group in $RotationGroups) {
            if ($currentGroups -contains $group) {
                if ($PSCmdlet.ShouldProcess($User.SamAccountName, "Remove from $group")) {
                    Remove-ADGroupMember -Identity $group -Members $User -Confirm:$false
                }
                $result.Removed++
                $result.RemovedGroups += $group
            }
        }

        # Simulate post-removal state in-memory (avoids AD replication delay issues)
        $effectiveGroups = $currentGroups | Where-Object { $result.RemovedGroups -notcontains $_ }

        # Add only the required groups for the target department
        foreach ($group in $DepartmentGroups[$Department]) {
            if ($effectiveGroups -notcontains $group) {
                if ($PSCmdlet.ShouldProcess($User.SamAccountName, "Add to $group")) {
                    Add-ADGroupMember -Identity $group -Members $User
                }
                $result.Added++
                $result.AddedGroups += $group
            }
        }

        return $result
    }
    catch {
        return "Error: $($_.Exception.Message)"
    }
}

function Set-MailboxPermissions {
    param(
        [string]$UserUPN,
        [string]$Department
    )
    $result = @{
        Action = $null
        Errors = $null
    }
    $shouldHaveAccess = $SharedMailboxDepartments -contains $Department
    try {
        if ($shouldHaveAccess) {
            if ($PSCmdlet.ShouldProcess($UserUPN, "Grant FullAccess on $SharedMailbox")) {
                Add-MailboxPermission -Identity $SharedMailbox -User $UserUPN -AccessRights FullAccess -AutoMapping $false -ErrorAction Stop | Out-Null
            }
            if ($PSCmdlet.ShouldProcess($UserUPN, "Grant SendAs on $SharedMailbox")) {
                Add-RecipientPermission -Identity $SharedMailbox -Trustee $UserUPN -AccessRights SendAs -Confirm:$false -ErrorAction Stop | Out-Null
            }
            $result.Action = "Granted"
        }
        else {
            # Check if user actually has Full Access before attempting removal
            $hasFullAccess = Get-MailboxPermission -Identity $SharedMailbox -User $UserUPN -ErrorAction SilentlyContinue |
                             Where-Object { $_.AccessRights -contains "FullAccess" }

            # Check if user actually has Send As before attempting removal
            $hasSendAs = Get-RecipientPermission -Identity $SharedMailbox -Trustee $UserUPN -ErrorAction SilentlyContinue |
                         Where-Object { $_.AccessRights -contains "SendAs" }

            if ($hasFullAccess) {
                try {
                    if ($PSCmdlet.ShouldProcess($UserUPN, "Remove FullAccess on $SharedMailbox")) {
                        Remove-MailboxPermission -Identity $SharedMailbox -User $UserUPN -AccessRights FullAccess -Confirm:$false -ErrorAction Stop | Out-Null
                    }
                }
                catch {
                    # Permission could not be removed
					$result.Errors = "Failed to remove FullAccess: $($_.Exception.Message)"
                }
            }

            if ($hasSendAs) {
                try {
                    if ($PSCmdlet.ShouldProcess($UserUPN, "Remove SendAs on $SharedMailbox")) {
                        Remove-RecipientPermission -Identity $SharedMailbox -Trustee $UserUPN -AccessRights SendAs -Confirm:$false -ErrorAction Stop | Out-Null
                    }
                }
                catch {
                    # Permission could not be removed
					$result.Errors = "Failed to remove SendAs: $($_.Exception.Message)"
                }
            }

            if ($hasFullAccess -or $hasSendAs) {
                $result.Action = "Removed"
            }
            else {
                $result.Action = "No Mailbox Access Found"
            }
        }
    }
    catch {
        $result.Action = "Failed"
        $result.Errors = $_.Exception.Message
    }
    return $result
}

# Main

# Import-Module ActiveDirectory -ErrorAction Stop

# Ensure logging directory exists before writing logs
Ensure-LogFolder -Path $LogFolder

# Generate timestamped log + report file paths
$timestamp = Get-Date -Format "ddMMyyyy_HHmmss"
$logPath   = Join-Path $LogFolder "Rotation_$timestamp.log"
$csvPath   = Join-Path $LogFolder "Rotation_Report_$timestamp.csv"

# Attempt to start transcript logging (captures full console output)
$transcribing = $false
try {
    Start-Transcript -Path $logPath -Force | Out-Null
    $transcribing = $true
}
catch {
    Write-Warning "Transcript could not be started: $($_.Exception.Message)"
}

$exchangeConnected = $false
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    
    # Only connect if not already connected
    $existingSession = Get-ConnectionInformation -ErrorAction SilentlyContinue
    if (-not $existingSession) {
        Connect-ExchangeOnline -ShowProgress $false -ErrorAction Stop
    }
    
    $exchangeConnected = $true
    Write-Host "Exchange Online connected." -ForegroundColor Cyan
}
catch {
    Write-Warning "Exchange Online connection failed - mailbox permission steps will be skipped. Error: $($_.Exception.Message)"
}

# Import CSV and discard rows where both UserID and Department are empty
$rows = Import-Csv $Csv | Where-Object {
    -not (
        [string]::IsNullOrWhiteSpace($_.UserID) -and
        [string]::IsNullOrWhiteSpace($_.Department)
    )
}

# Fail fast if no usable data
if (-not $rows -or $rows.Count -eq 0) {
    throw "CSV has no data."
}

# Normalise input data (trim + map departments)
$rows = $rows | ForEach-Object {
    $userId = if ([string]::IsNullOrWhiteSpace($_.UserID)) {
        "__MISSING__"
    } else {
        $_.UserID.Trim()
    }

    $dept = Resolve-DepartmentName $_.Department

    [pscustomobject]@{
        UserID = $userId
        Department = $dept
    }
}

$report = @()

# Process each row independently
foreach ($row in $rows) {

    # Build result object for reporting
    $result = [ordered]@{
        InputIdentity = $row.UserID
        Found = $false
        Department = $row.Department
        OfficeSet = $null
        DepartmentSet = $null
        GroupsRemoved = 0
        GroupsAdded = 0
        RemovedGroups = $null
        AddedGroups = $null
		MailboxAction = $null
        MailboxErrors = $null
        Status = $null
        Errors = $null
    }

    try {
        # Resolve user from AD
        $user = Resolve-AdUser $row.UserID
        $result.Found = $true

        # Validate department mappings before making any changes
        if ([string]::IsNullOrWhiteSpace($row.Department)) {
            throw "Department is blank after normalization."
        }

        if (-not $DepartmentGroups.ContainsKey($row.Department)) {
            throw "Missing group mapping for department: '$($row.Department)'"
        }
        if (-not $DepartmentOfficeMap.ContainsKey($row.Department)) {
            throw "Missing office mapping for department: '$($row.Department)'"
        }
        if (-not $DepartmentNameMap.ContainsKey($row.Department)) {
            throw "Missing AD department name mapping for department: '$($row.Department)'"
        }

        # Resolve target AD attribute values
        $adDepartment = $DepartmentNameMap[$row.Department]
        $officeValue  = $DepartmentOfficeMap[$row.Department]

        # Get current group memberships
        $currentGroups = Get-ADPrincipalGroupMembership -Identity $user |
                         Select-Object -ExpandProperty Name

        $targetGroups = $DepartmentGroups[$row.Department]

        # Only consider rotation-related groups
        $currentRotationGroups = $currentGroups | Where-Object { $RotationGroups -contains $_ }

        # Compare current vs target groups (order-independent comparison)
        $hasCorrectGroups =
            (@($currentRotationGroups | Sort-Object) -join '|') -eq
            (@($targetGroups | Sort-Object) -join '|')

        # Check if AD attributes already match desired state
        $sameDepartment = $user.Department -eq $adDepartment
        $sameOffice     = $user.physicalDeliveryOfficeName -eq $officeValue

        # Skip user if everything is already correct
        if ($sameDepartment -and $sameOffice -and $hasCorrectGroups) {
            $result.Status        = "Skipped (Already Correct)"
            $result.DepartmentSet = $user.Department
            $result.OfficeSet     = $user.physicalDeliveryOfficeName
        }
        else {
            # Update group memberships
            $grp = Set-RotationGroups -User $user -Department $row.Department

            if ($grp -is [string]) {
                # Function returned an error string instead of result object
                $result.Status = "Failed"
                $result.Errors = $grp
            }
            else {
                # Capture group changes
                $result.GroupsRemoved = $grp.Removed
                $result.GroupsAdded   = $grp.Added
                $result.RemovedGroups = $grp.RemovedGroups -join "; "
                $result.AddedGroups   = $grp.AddedGroups   -join "; "

                # Update AD attributes (department + office)
                if ($PSCmdlet.ShouldProcess($user.SamAccountName, "Update Department/Office")) {
                    Set-ADUser -Identity $user -Department $adDepartment -Office $officeValue
                }

                $result.Status        = "Updated"
                $result.DepartmentSet = $adDepartment
                $result.OfficeSet     = $officeValue
            }
        }
		if ($exchangeConnected) {
            $mbx = Set-MailboxPermissions -UserUPN $user.UserPrincipalName -Department $row.Department
            $result.MailboxAction = $mbx.Action
            $result.MailboxErrors = $mbx.Errors
        }
        else {
            $result.MailboxAction = "Skipped (No Exchange Connection)"
        }
    }
    catch {
        # Catch per-user errors so processing continues for others
        $result.Status = "Error"
        $result.Errors = $_.Exception.Message
    }

    # Colour-coded console output for visibility
    $colour = switch ($result.Status) {
        "Updated"                    {"Green"}
        "Skipped (Already Correct)"  {"Yellow"}
        "Failed"                     {"Red"}
        "Error"                      {"Red"}
        default                      {"Cyan"}
    }

    Write-Host "[$($row.UserID)] $($result.Status) | Removed: $($result.RemovedGroups) | Added: $($result.AddedGroups)" -ForegroundColor $colour

    # Add to report collection
    $report += [pscustomobject]$result
}

$report | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

if ($transcribing) {
    try { Stop-Transcript | Out-Null } catch {}
}

Write-Host "Log: $logPath"
Write-Host "Report: $csvPath"
Write-Host "`nDone." -ForegroundColor Cyan