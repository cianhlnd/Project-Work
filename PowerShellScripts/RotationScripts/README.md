# Trainee Rotation Automation

Automates moving trainees between departments on a rotation cycle. For each trainee it corrects Active Directory group membership, updates the Department and Office attributes, and adjusts shared mailbox access - all driven by a single JSON configuration file so the rotation logic can be changed without touching the script.

## What it does

The wrapper runs the rotation script with `-WhatIf` first, shows you exactly what would change, and waits for a `RUN` or `SKIP` confirmation before committing anything live. For each user in the input file the script will:

- Remove the user from every rotation group, then add only the groups for their target department.
- Update the `Department` and `physicalDeliveryOfficeName` (Office) attributes to match the target department.
- Grant or remove shared mailbox `FullAccess` and `SendAs` permissions depending on whether the target department should have access.
- Skip any user who is already in the correct state, so re-running is safe and idempotent.

Department names are resolved through an alias map, so friendly or shorthand values in the spreadsheet (e.g. `dep1`) map cleanly to canonical department names.

## Files

| File | Purpose |
|------|---------|
| `TraineeRotationAutomation.bat` | Double-click launcher. Runs the wrapper. |
| `RotationWrapper.ps1` | Runs the rotation script with a dry-run preview and confirmation. |
| `TraineeRotation.ps1` | Core rotation logic for AD groups, attributes, and mailbox access. |
| `RotationConfig.json` | Defines rotation groups, department-to-group mappings, office mappings, aliases, and the shared mailbox. |
| `RotationInput.csv` | Input file listing each trainee and their target department. |

## How to run

Double-click `TraineeRotationAutomation.bat`, or run the wrapper directly:

```powershell
.\RotationWrapper.ps1
```

All paths resolve relative to the folder, including the configuration file, so no editing is required to run it from a new location.

## Input format

`RotationInput.csv` needs a `UserID` and a `Department` column:

```csv
UserID,Department
jbloggs,Department1
asmith,Department2
```

## Configuration

`RotationConfig.json` controls all the rotation logic:

- **RotationGroups** - the full set of department groups a trainee may belong to (all are removed before the correct ones are re-added).
- **DepartmentGroups** - the groups to apply for each department.
- **DepartmentNameMap** - the value written to the AD `Department` attribute.
- **DepartmentOfficeMap** - the value written to the AD `Office` attribute.
- **DepartmentAliases** - shorthand or alternative spellings mapped to canonical department names.
- **SharedMailbox** - the shared mailbox identity and which departments should have access to it.

## Requirements

- RSAT Active Directory PowerShell module (`ActiveDirectory`)
- `ExchangeOnlineManagement` module for the shared mailbox permission steps
- Permissions to modify group membership, update user attributes, and manage mailbox permissions

## Safety features

- **Dry-run first.** The wrapper previews all changes with `-WhatIf` before anything is committed.
- **Explicit confirmation.** A live run only proceeds after you type `RUN`.
- **Idempotent.** Users already in the correct state are skipped, so the script can be run repeatedly without side effects.

## Notes

The `LogFolder` default is a parameter and can be overridden at runtime. Logs and a per-run CSV report are written there with a timestamp.
