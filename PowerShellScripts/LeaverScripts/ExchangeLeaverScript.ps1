<#
Post-AD leaver stage (EXO-only):
 - Converts mailbox to shared in Exchange Online
 - Sets Out of Office using leaver template (internal + external)
 - Sets mail forwarding (DeliverToMailboxAndForward) to per-row ForwardToSmtp
 - Removes licensing groups (e.g. MailboxLicence) after shared is confirmed
 - Transcript + CSV report per run
 
 Runs automatically in the LeaverAutomation batch file

CSV FORMAT (recommended):
  UserId,LeavingDate,ForwardToSmtp,ForwardToDisplayName
  jbloggs,01/03/2026,joe.bloggs@company.com,Joe Bloggs
  
Notes
  Requirements:
  - RSAT AD module (ActiveDirectory) for resolving user + removing licensing groups
  - ExchangeOnlineManagement module for Connect-ExchangeOnline / Get-Mailbox / Set-Mailbox / Get-Recipient
  - If you want to keep your Exchange session running run the script with -KeepExchangeSession at the end
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    Provide users directly: -Users jbloggs,asmith (samAccountName or UPN)
    [Parameter(ParameterSetName="Users", Mandatory=$true)]
    [string[]]$Users,

    # Provide a text file with one user id per line (samAccountName or UPN)
    [Parameter(ParameterSetName="UserFile", Mandatory=$true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$UserFile, 

    # Provide a CSV with UserId column and then the other necessary ones
    [Parameter(ParameterSetName="Csv", Mandatory=$true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$Csv,

    # Logs location
    [string]$LogFolder = "C:\Logs\Exchange-Script-Logs",

    # Licensing groups to remove after mailbox is confirmed Shared
    [string[]]$LicenseGroupsToRemove = @(
        "MailboxLicence"
    ),

    [switch]$SkipDisabledCheck,

    # If you want to test conversion without changing licensing groups
    [switch]$SkipLicenseGroupRemoval,

    # Safety: maximum number of users allowed per run
    [ValidateRange(1, 500)]
    [int]$MaxUsers = 25,

    # Explicit override required to exceed MaxUsers
    [switch]$OverrideMaxUsers,

    # How long to wait for Exchange to reflect SharedMailbox after conversion
    [ValidateRange(10, 600)]
    [int]$SharedMailboxConfirmTimeoutSeconds = 15,

    # Enable/disable these features
    [switch]$ConfigureOOO = $true,

    # If blank for a user, forwarding is skipped
    [string]$DefaultForwardToSmtp,

    # Optional name override if you don't want to rely on Get-Recipient DisplayName
    [string]$DefaultOOOToDisplayName,

    # Default leaving date (used if CSV LeavingDate missing/blank)
    [datetime]$DefaultLeavingDate = (Get-Date),

      # External audience scope (tenant supports: None, Known, All)
    [ValidateSet("All","Known","None")]
    [string]$OOOExternalAudience = "All",

    # AutoReply state (leavers usually Enabled)
    [ValidateSet("Enabled","Disabled","Scheduled")]
    [string]$OOOState = "Enabled",

    # If true, keep a copy in the mailbox as well
    [switch]$DeliverToMailboxAndForward = $true,

    # Safety: block external forwarding unless explicitly allowed
    # [switch]$AllowExternalForwarding,
	
	[switch]$KeepExchangeSession
)

function Ensure-LogFolder {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

function Get-InputUsers {
    switch ($PSCmdlet.ParameterSetName) {
        "Users" {
            return $Users | Where-Object { $_ -and $_.Trim() -ne "" } | ForEach-Object {
                [pscustomobject]@{
                    UserId              = $_.Trim()
                    LeavingDate         = $null
                    ForwardToSmtp       = $null
                    OOODisplayName= $null
                }
            }
        }
        "UserFile" {
            return Get-Content -Path $UserFile | Where-Object { $_ -and $_.Trim() -ne "" } | ForEach-Object {
                [pscustomobject]@{
                    UserId              = $_.Trim()
                    LeavingDate         = $null
                    ForwardToSmtp       = $null
                    OOODisplayName= $null
                }
            }
        }
        "Csv" {
            $rows = Import-Csv -Path $Csv
            if (-not $rows -or $rows.Count -eq 0) { throw "CSV appears to be empty." }

            # Prefer UserId; fallback to samAccountName/UPN if needed
            $idCol = @("UserId","Username","userid","username","Identity","samAccountName","SamAccountName","UPN","UserPrincipalName") |
                Where-Object { $_ -in $rows[0].PSObject.Properties.Name } |
                Select-Object -First 1

            if (-not $idCol) {
                throw "CSV must contain one of: UserId, samAccountName, or UPN/UserPrincipalName."
            }

            $dateCol = @("LeavingDate","leaveDate","LeaverDate","LastWorkingDay") |
                Where-Object { $_ -in $rows[0].PSObject.Properties.Name } |
                Select-Object -First 1

            $fwdCol  = @("ForwardToSmtp","ForwardTo","ForwardingAddress","ForwardToEmail") |
                Where-Object { $_ -in $rows[0].PSObject.Properties.Name } |
                Select-Object -First 1

            $nameCol = @("ForwardToDisplayName","ForwardName","ContactName","OOODisplayName") |
                Where-Object { $_ -in $rows[0].PSObject.Properties.Name } |
                Select-Object -First 1

            return $rows | ForEach-Object {
                $id = $_.$idCol
                if (-not $id -or -not $id.Trim()) { return }

                [pscustomobject]@{
                    UserId              = $id.Trim()
                    LeavingDate         = if ($dateCol) { $_.$dateCol } else { $null }
                    ForwardToSmtp       = if ($fwdCol)  { $_.$fwdCol }  else { $null }
                    ForwardToDisplayName= if ($nameCol) { $_.$nameCol } else { $null }
                }
            }
        }
        default { throw "Unknown input type." }
    }
}

function Resolve-UserForMailbox {
    param([string]$UserId)

    $id = $UserId.Trim()
    if (-not $id) { throw "UserId is blank." }

    # Escape single quotes for AD filter strings
    $idEsc = $id.Replace("'", "''")

    if ($id -match '@') {
        # AD filter language does NOT support PowerShell concatenation inside -Filter {}
        $filter = @"
UserPrincipalName -eq '$idEsc' -or
mail -eq '$idEsc' -or
proxyAddresses -eq 'SMTP:$idEsc' -or
proxyAddresses -eq 'smtp:$idEsc'
"@

        $u = Get-ADUser -Filter $filter -Properties Enabled, UserPrincipalName, mail, proxyAddresses -ErrorAction Stop |
            Select-Object -First 1

        if (-not $u) { throw "No AD user found matching UPN/mail/proxyAddresses '$id'." }
    }
    else {
        $u = Get-ADUser -Identity $id -Properties Enabled, UserPrincipalName, mail, proxyAddresses -ErrorAction Stop
    }

    $primarySmtp = $null
    if ($u.proxyAddresses) {
        $p = $u.proxyAddresses | Where-Object { $_ -cmatch '^SMTP:' } | Select-Object -First 1
        if ($p) { $primarySmtp = $p.Substring(5) }
    }

    [pscustomobject]@{
        InputId            = $id
        SamAccountName     = $u.SamAccountName
        UserPrincipalName  = $u.UserPrincipalName
        Mail               = $u.mail
        PrimarySmtpAddress = $primarySmtp
        AdUser             = $u
    }
}

function Get-ExchangeIdentity {
    param($Resolved)

    foreach ($id in @($Resolved.PrimarySmtpAddress, $Resolved.Mail, $Resolved.UserPrincipalName, $Resolved.SamAccountName)) {
        if ($id -and $id.Trim()) { return $id.Trim() }
    }
    return $Resolved.SamAccountName
}

function Connect-ExchangeOnlineSafe {

    if (-not (Get-Command Connect-ExchangeOnline -ErrorAction SilentlyContinue)) {
        return "EXOConnectSkipped: ExchangeOnlineManagement module not found."
    }

    try {
        $conn = Get-ConnectionInformation -ErrorAction Stop

        if ($conn -and $conn.State -eq "Connected") {
            return "EXOAlreadyConnected"
        }
        else {
            throw "Not connected"
        }
    }
    catch {
        try {
            Connect-ExchangeOnline -ShowBanner:$false | Out-Null
            return "EXOConnected"
        }
        catch {
            return "EXOConnectError: $($_.Exception.Message)"
        }
    }
}

function Disconnect-ExchangeOnlineSafe {
    if (Get-Command Disconnect-ExchangeOnline -ErrorAction SilentlyContinue) {
        try { Disconnect-ExchangeOnline -Confirm:$false | Out-Null } catch {}
    }
}

function Ensure-SharedMailboxEXO {
    param(
        [Parameter(Mandatory=$true)] $Resolved,
        [Parameter(Mandatory=$true)] [int] $ConfirmTimeoutSeconds
    )

    $identity = Get-ExchangeIdentity -Resolved $Resolved

    $out = [ordered]@{
        ExchangeIdentity = $identity
        MailboxFound     = $false
        MailboxType      = $null
        ConversionResult = $null
        Message          = $null
    }

    try {
        $mbx = Get-Mailbox -Identity $identity -ErrorAction Stop
        $out.MailboxFound = $true
        $out.MailboxType  = $mbx.RecipientTypeDetails

        if ($mbx.RecipientTypeDetails -eq "SharedMailbox") {
            $out.ConversionResult = "AlreadyShared"
            return [pscustomobject]$out
        }

        if ($PSCmdlet.ShouldProcess($identity, "Convert mailbox to Shared (EXO)")) {
            Set-Mailbox -Identity $identity -Type Shared -ErrorAction Stop
        }

        # After conversion, RecipientTypeDetails can lag. Retry until it shows SharedMailbox.
        $interval  = 2
        $elapsed   = 0
        $finalType = $null

        do {
			Write-Host "[$($resolved.SamAccountName)] Waiting for SharedMailbox confirmation... ($elapsed/$ConfirmTimeoutSeconds seconds)" -ForegroundColor DarkGray
			Start-Sleep -Seconds $interval
			$elapsed += $interval

			$mbx2 = Get-Mailbox -Identity $identity -ErrorAction Stop
			$finalType = $mbx2.RecipientTypeDetails

		} while ($finalType -ne "SharedMailbox" -and $elapsed -lt $ConfirmTimeoutSeconds)

        $out.MailboxType = $finalType
        $out.ConversionResult = if ($finalType -eq "SharedMailbox") { "ConvertedToShared" } else { "ConvertedPendingConfirmation" }

        return [pscustomobject]$out
    }
    catch {
        $out.Message = $_.Exception.Message
        if (-not $out.ConversionResult) { $out.ConversionResult = "Error" }
        return [pscustomobject]$out
    }
}

function Ensure-RemovedFromLicenseGroups {
    param(
        [Parameter(Mandatory=$true)] $Resolved,
        [Parameter(Mandatory=$true)] [string[]] $GroupNames
    )
	 # Guard against empty list
    if (-not $GroupNames -or $GroupNames.Count -eq 0) {
        return @([pscustomobject]@{
            GroupName     = "None"
            WasMember     = $false
            RemovalResult = "SkippedNoGroupsDefined"
            Message       = $null
        })
	}
		
    $results = New-Object System.Collections.Generic.List[object]

    # Fast + reliable membership list for the user
    $userGroups = @()
    try {
        $userGroups = Get-ADPrincipalGroupMembership -Identity $Resolved.AdUser -ErrorAction Stop |
            Select-Object -ExpandProperty Name
    }
    catch {
        # Fallback: translate MemberOf DNs to Names
        $fresh = Get-ADUser -Identity $Resolved.SamAccountName -Properties MemberOf -ErrorAction Stop
        $userGroups = @($fresh.MemberOf | ForEach-Object {
            try { (Get-ADGroup -Identity $_ -ErrorAction Stop).Name } catch { $null }
        }) | Where-Object { $_ }
    }

    foreach ($gName in $GroupNames) {

        $out = [ordered]@{
            GroupName     = $gName
            WasMember     = $false
            RemovalResult = $null
            Message       = $null
        }

        try {
            $out.WasMember = $userGroups -contains $gName

            if (-not $out.WasMember) {
                $out.RemovalResult = "AlreadyNotMember"
            }
            else {
                $group = Get-ADGroup -Identity $gName -ErrorAction Stop

                if ($PSCmdlet.ShouldProcess($Resolved.SamAccountName, "Remove from licensing group '$gName'")) {
                    Remove-ADGroupMember -Identity $group -Members $Resolved.AdUser -Confirm:$false -ErrorAction Stop
                }

                $out.RemovalResult = "Removed"
            }
        }
        catch {
            $out.RemovalResult = "Error"
            $out.Message = $_.Exception.Message
        }

        $results.Add([pscustomobject]$out) | Out-Null
    }

    return $results
}

# OOO + forwarding helpers

function Resolve-ForwardContactName {
    param([string]$ForwardToSmtp, [string]$OverrideName)

    if ($OverrideName -and $OverrideName.Trim()) { return $OverrideName.Trim() }

    try {
        $r = Get-Recipient -Identity $ForwardToSmtp -ErrorAction Stop
        if ($r.DisplayName) { return $r.DisplayName }
    } catch {}

    return $ForwardToSmtp
}

function New-LeaverOOOMessage {
    param(
        [Parameter(Mandatory=$true)][datetime]$LeavingDate,
        [Parameter(Mandatory=$true)][string]$ContactName,
        [Parameter(Mandatory=$true)][string]$ContactEmail
    )

    $dateText = $LeavingDate.ToString("dd/MM/yyyy")

    return ("Thank you for your email. As of {0}, I am no longer working for Company. " +
            "Your email has automatically been sent to {1}. If you wish to follow up with {1} directly, " +
            "their email address is {2}") -f $dateText, $ContactName, $ContactEmail
}

function Ensure-MailboxAutoReply {
    param(
        [Parameter(Mandatory=$true)] $Resolved,
        [Parameter(Mandatory=$true)] [string] $InternalMessage,
        [Parameter(Mandatory=$true)] [string] $ExternalMessage,
        [Parameter(Mandatory=$true)] [string] $State,
        [Parameter(Mandatory=$true)] [string] $ExternalAudience,
        [switch]$SkipIfAlreadyEnabled
    )

    $identity = Get-ExchangeIdentity -Resolved $Resolved

    $out = [ordered]@{
        ExchangeIdentity   = $identity
        OOOCurrentState    = $null
        OOOResult          = $null
        OOOMessage         = $null
    }

    try {
        # Ensure mailbox exists
        $null = Get-Mailbox -Identity $identity -ErrorAction Stop

        $cfg = Get-MailboxAutoReplyConfiguration -Identity $identity -ErrorAction Stop
        $out.OOOCurrentState = $cfg.AutoReplyState

        $alreadyOn = $cfg.AutoReplyState -in @("Enabled","Scheduled")

        if ($SkipIfAlreadyEnabled -and $alreadyOn) {
            $out.OOOResult  = "SkippedAlreadyEnabled"
            # Store existing INTERNAL message only (flatten whitespace for CSV)
            $out.OOOMessage = ($cfg.InternalMessage -replace '\s+',' ').Trim()
            return [pscustomobject]$out
        }

        if ($PSCmdlet.ShouldProcess($identity, "Configure OOO (AutoReplyState=$State, ExternalAudience=$ExternalAudience)")) {
            Set-MailboxAutoReplyConfiguration -Identity $identity `
                -AutoReplyState $State `
                -InternalMessage $InternalMessage `
                -ExternalMessage $ExternalMessage `
                -ExternalAudience $ExternalAudience `
                -ErrorAction Stop
        }

        $out.OOOResult = "Set"
        return [pscustomobject]$out
    }
    catch {
        $out.OOOResult  = "Error"
        $out.OOOMessage = $_.Exception.Message
        return [pscustomobject]$out
    }
}

function Ensure-MailForwardingInternal {
    param(
        [Parameter(Mandatory=$true)] $Resolved,
        [Parameter(Mandatory=$true)] [string] $ForwardToSmtp,
        [Parameter(Mandatory=$true)] [bool] $DeliverToMailboxAndForward
    )

    $identity = Get-ExchangeIdentity -Resolved $Resolved

    $out = [ordered]@{
        ExchangeIdentity      = $identity
        ForwardTo             = $ForwardToSmtp
        ForwardingResult      = $null
        ForwardingMessage     = $null
    }

    try {
        # Ensure mailbox exists
        $null = Get-Mailbox -Identity $identity -ErrorAction Stop

        # Resolve the forwarding target to an INTERNAL recipient object
        $target = Get-Recipient -Identity $ForwardToSmtp -ErrorAction Stop

        if ($PSCmdlet.ShouldProcess($identity, "Set INTERNAL forwarding to '$($target.PrimarySmtpAddress)' (DeliverToMailboxAndForward=$DeliverToMailboxAndForward)")) {

            # Clear SMTP forwarding (external-style) and set internal ForwardingAddress
            Set-Mailbox -Identity $identity `
                -ForwardingSmtpAddress $null `
                -ForwardingAddress $target.Identity `
                -DeliverToMailboxAndForward $DeliverToMailboxAndForward `
                -ErrorAction Stop
        }

        $out.ForwardingResult = "SetInternal"
        return [pscustomobject]$out
    }
    catch {
        $out.ForwardingResult  = "Error"
        $out.ForwardingMessage = $_.Exception.Message
        return [pscustomobject]$out
    }
}

# Main

Import-Module ActiveDirectory -ErrorAction Stop

Ensure-LogFolder -Path $LogFolder

$timestamp = Get-Date -Format "ddMMyyyy_HHmmss"
$logPath   = Join-Path $LogFolder "LeaverMailbox_$timestamp.log"
$csvPath   = Join-Path $LogFolder "LeaverMailbox_Report_$timestamp.csv"

$transcribing = $false
try {
    Start-Transcript -Path $logPath -Force | Out-Null
    $transcribing = $true
}
catch {
    Write-Warning "Transcript could not be started: $($_.Exception.Message)"
}

$exoStatus = Connect-ExchangeOnlineSafe
Write-Host "Exchange Online: $exoStatus" -ForegroundColor DarkCyan
if ($exoStatus -like "EXOConnectSkipped*") {
    throw "Exchange Online cmdlets not found. Install ExchangeOnlineManagement or run on a machine that has it."
}
if ($exoStatus -like "EXOConnectError*") {
    throw "Exchange Online connection failed. Cannot continue."
}

$inputUsers = @(Get-InputUsers)

# Safety guard: limit number of users processed per run
if (-not $OverrideMaxUsers -and $inputUsers.Count -gt $MaxUsers) {

    $message = "Refusing to process $($inputUsers.Count) users. Maximum allowed per run is $MaxUsers. Use -OverrideMaxUsers to proceed."

    Write-Error $message

    if ($transcribing) {
        try { Stop-Transcript | Out-Null } catch {}
    }

    throw $message
}

Write-Host "Processing $($inputUsers.Count) user(s)..." -ForegroundColor Cyan

$report = New-Object System.Collections.Generic.List[object]

foreach ($item in $inputUsers) {

    $userId = $item.UserId

    # CSV file rows
    $row = [ordered]@{
        UserId               = $userId
        Username             = $null
        FoundInAD            = $false
        UPN                  = $null
        PrimarySmtpAddress   = $null
        ExchangeIdentity     = $null
        LeavingDate          = $null
        ForwardToSmtp        = $null
        ForwardToDisplayName = $null
        OOOAction            = $null
        OOOMessage           = $null
        ForwardingAction     = $null
        ForwardingMessage    = $null
        MailboxFound         = $null
        MailboxType          = $null
        ConversionResult     = $null
        ExchangeMessage      = $null
        LicenseGroups        = ($LicenseGroupsToRemove -join "; ")
        LicenseGroupAction   = $null
        LicenseGroupMessage  = $null
        Errors               = $null
    }

    try {
        $resolved = Resolve-UserForMailbox -UserId $userId
        $row.FoundInAD          = $true
        $row.Username           = $resolved.SamAccountName
        $row.UPN                = $resolved.UserPrincipalName
        $row.PrimarySmtpAddress = $resolved.PrimarySmtpAddress

        # Safety gate: refuse to process enabled accounts unless explicitly overridden
        if (-not $SkipDisabledCheck -and $resolved.AdUser.Enabled -eq $true) {

            $row.ExchangeIdentity     = Get-ExchangeIdentity -Resolved $resolved
            $row.ConversionResult     = "SkippedAccountEnabled"
            $row.ExchangeMessage      = "Account is enabled. Run AD leaver script first, or override with -SkipDisabledCheck."
            $row.LicenseGroupAction   = "SkippedAccountEnabled"
            $row.LicenseGroupMessage  = "No mailbox conversion or licensing changes performed."
            $row.OOOAction            = "SkippedAccountEnabled"
            $row.ForwardingAction     = "SkippedAccountEnabled"

            Write-Warning "[$userId] Skipped: AD account is ENABLED. No changes will be made."
            $report.Add([pscustomobject]$row) | Out-Null
            continue
        }

        # Per-user effective inputs (CSV overrides defaults)
        $effectiveLeavingDate = $DefaultLeavingDate
        if ($item.LeavingDate -and $item.LeavingDate.ToString().Trim()) {
            $effectiveLeavingDate = [datetime]::Parse($item.LeavingDate.ToString())
        }

        $effectiveForwardToSmtp = $DefaultForwardToSmtp
        if ($item.ForwardToSmtp -and $item.ForwardToSmtp.Trim()) {
            $effectiveForwardToSmtp = $item.ForwardToSmtp.Trim()
        }

        $effectiveForwardName = $DefaultOOOToDisplayName
        if ($item.ForwardToDisplayName -and $item.ForwardToDisplayName.Trim()) {
            $effectiveForwardName = $item.ForwardToDisplayName.Trim()
        }

        $row.LeavingDate          = $effectiveLeavingDate.ToString("yyyy-MM-dd")
        $row.ForwardToSmtp        = $effectiveForwardToSmtp
        $row.ForwardToDisplayName = $effectiveForwardName

        # Safety: block external forwarding unless explicitly allowed
        <#if ($effectiveForwardToSmtp) {
            # Change this to match your real domain(s)
            if ($effectiveForwardToSmtp -notlike "*@company.com") {
                throw "Refusing to set external forwarding address: $effectiveForwardToSmtp (use -AllowExternalForwarding to override)"
            }
        }#>

        # Function that sets up forwarding
        if ($effectiveForwardToSmtp -and $effectiveForwardToSmtp.Trim()) {
            $fwd = Ensure-MailForwardingInternal -Resolved $resolved `
				-ForwardToSmtp $effectiveForwardToSmtp `
				-DeliverToMailboxAndForward ([bool]$DeliverToMailboxAndForward)

            $row.ForwardingAction  = $fwd.ForwardingResult
            $row.ForwardingMessage = $fwd.ForwardingMessage
        }
        else {
            $row.ForwardingAction = "SkippedNoForwardAddress"
        }

        # Function to configure OOO 
        if ($ConfigureOOO) {

            if ($effectiveForwardToSmtp -and $effectiveForwardToSmtp.Trim()) {
                $contactName = Resolve-ForwardContactName -ForwardToSmtp $effectiveForwardToSmtp -OverrideName $effectiveForwardName
                $oooText = New-LeaverOOOMessage -LeavingDate $effectiveLeavingDate -ContactName $contactName -ContactEmail $effectiveForwardToSmtp
            }
            else {
                # If no forwarding address, use a simpler message
                $oooText = "Thank you for your email. As of {0}, I am no longer working for Company." -f $effectiveLeavingDate.ToString("dd/MM/yyyy")
            }

            $ooo = Ensure-MailboxAutoReply -Resolved $resolved `
				-InternalMessage $oooText `
				-ExternalMessage $oooText `
				-State $OOOState `
				-ExternalAudience $OOOExternalAudience `
				-SkipIfAlreadyEnabled

            $row.OOOAction  = $ooo.OOOResult
            $row.OOOMessage = $ooo.OOOMessage
        }
        else {
            $row.OOOAction = "SkippedBySwitch"
        }

        # 1) Convert mailbox to Shared (EXO) + verify with retry
        $mbxResult = Ensure-SharedMailboxEXO -Resolved $resolved -ConfirmTimeoutSeconds $SharedMailboxConfirmTimeoutSeconds
        $row.ExchangeIdentity = $mbxResult.ExchangeIdentity
        $row.MailboxFound     = $mbxResult.MailboxFound
        $row.MailboxType      = $mbxResult.MailboxType
        $row.ConversionResult = $mbxResult.ConversionResult
        $row.ExchangeMessage  = $mbxResult.Message

        # 2) Remove licensing groups ONLY if mailbox is confirmed Shared (or already shared)
        if ($SkipLicenseGroupRemoval) {
            $row.LicenseGroupAction = "SkippedBySwitch"
        }
        elseif ($mbxResult.ConversionResult -in @("ConvertedToShared","AlreadyShared")) {

            $lgResults = Ensure-RemovedFromLicenseGroups -Resolved $resolved -GroupNames $LicenseGroupsToRemove

            $row.LicenseGroupAction  = ($lgResults | ForEach-Object { "$($_.GroupName)=$($_.RemovalResult)" }) -join "; "
            $row.LicenseGroupMessage = ($lgResults | Where-Object { $_.Message } | ForEach-Object { "$($_.GroupName):$($_.Message)" }) -join "; "
        }
        else {
            $row.LicenseGroupAction  = "SkippedBecauseMailboxNotShared"
            $row.LicenseGroupMessage = "Mailbox conversion did not confirm Shared within timeout; leaving licensing groups unchanged."
        }

        Write-Host "[$userId] OOO: $($row.OOOAction) | Forwarding: $($row.ForwardingAction) | Mailbox: $($row.ConversionResult) ($($row.MailboxType)) | License groups: $($row.LicenseGroupAction)" -ForegroundColor Cyan
    }
    catch {
        $row.Errors = $_.Exception.Message
        Write-Warning "[$userId] Error: $($_.Exception.Message)"
    }

    $report.Add([pscustomobject]$row) | Out-Null
}

$report |
Select-Object `
    UserId,
    LeavingDate,
    ForwardToSmtp,
    ForwardToDisplayName,
    OOOAction,
    OOOMessage,
    ForwardingMessage,
    ConversionResult,
    Errors |
Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

if ($transcribing) {
    try { Stop-Transcript | Out-Null } catch {}
}

if ($KeepExchangeSession.IsPresent) {
    Write-Host "Leaving Exchange Online session connected (KeepExchangeSession)." -ForegroundColor Yellow
}
else {
    Write-Host "Disconnecting Exchange Online session..." -ForegroundColor DarkGray
    Disconnect-ExchangeOnlineSafe
}

Write-Host "Log:        $logPath"
Write-Host "Report CSV: $csvPath"
Write-Host "`nDone." -ForegroundColor Green