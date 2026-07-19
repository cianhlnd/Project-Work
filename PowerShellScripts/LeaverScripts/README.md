# Leaver Automation

An end-to-end offboarding suite for processing leavers across on-premises Active Directory, Exchange Online, and file server storage. The three stages run in sequence from a single wrapper, each with a mandatory dry-run preview before any change is committed.

## What it does

The wrapper runs three scripts in order. Each one previews its changes with `-WhatIf` first, then waits for you to type `RUN` or `SKIP` before doing anything live.

1. **ADLeaverScript.ps1** - On-premises Active Directory stage. Disables the account, sets an account expiry date, removes the user from all groups except a safe allowlist (e.g. `Domain Users`, `MailboxLicence`), clears personal attributes, hides the user from the address book, and moves the object to the Expired OU.
2. **ExchangeLeaverScript.ps1** - Exchange Online stage. Converts the mailbox to a shared mailbox, configures an Out of Office message, sets internal mail forwarding, and removes licensing groups once the shared conversion is confirmed. Includes a safety gate that refuses to process accounts still enabled in AD, so the AD stage must run first.
3. **FileServersLeaverScript.ps1** - File server stage. Deletes FSLogix profile and ODFC containers (2019 and 2025, standard and IT), archives the user's Documents and "My Binders" folders, and relocates Downloads. Uses `robocopy` with long-path support for reliable moves of deep folder structures.

## Files

| File | Purpose |
|------|---------|
| `LeaverAutomation.bat` | Double-click launcher. Runs the wrapper. |
| `LeaverPowerShellWrapper.ps1` | Orchestrates the three stages with per-stage confirmation. |
| `ADLeaverScript.ps1` | Active Directory offboarding stage. |
| `ExchangeLeaverScript.ps1` | Exchange Online offboarding stage. |
| `FileServersLeaverScript.ps1` | File server cleanup and archiving stage. |
| `LeaversInput.csv` | Input file listing the leavers to process. |

## How to run

Double-click `LeaverAutomation.bat`, or run the wrapper directly:

```powershell
.\LeaverPowerShellWrapper.ps1
```

All paths resolve relative to the folder, so no editing is required to run it from a new location.

## Input format

`LeaversInput.csv` accepts a `UserID` (or `Username`) column for the samAccountName, plus optional columns used by the Exchange stage:

```csv
UserID,LeavingDate,ForwardToSmtp,ForwardToDisplayName
jbloggs,01/03/2026,joe.bloggs@company.com,Joe Bloggs
```

## Requirements

- RSAT Active Directory PowerShell module (`ActiveDirectory`)
- `ExchangeOnlineManagement` module for the Exchange stage
- Permissions to modify users, move objects, manage group membership, convert mailboxes, and access the file server shares

Each script declares its module dependencies with a `#Requires` statement, so it will stop with a clear error if a required module is not installed. Install the modules first:

```powershell
# Active Directory module (RSAT)
# Windows 10/11:
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
# Windows Server:
Install-WindowsFeature RSAT-AD-PowerShell

# Exchange Online module (from the PowerShell Gallery)
Install-Module ExchangeOnlineManagement -Scope CurrentUser
```

## Safety features

- **Dry-run first.** Every stage runs with `-WhatIf` and shows the planned changes before anything is committed.
- **Per-stage confirmation.** Each stage requires an explicit `RUN` to proceed.
- **Maximum user limit.** A configurable cap (default 25 per run) guards against accidental bulk processing; exceeding it requires `-OverrideMaxUsers`.
- **Enabled-account gate.** The Exchange stage will not touch an account that is still enabled in AD.

## Notes

The file server roots in `FileServersLeaverScript.ps1` (FSLogix profile stores, archive locations, redirected folder roots) are intentionally hardcoded - they map to fixed infrastructure paths rather than anything relative to this repository. The `LogFolder` defaults are parameters and can be overridden at runtime.
