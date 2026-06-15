# Mailbox Permissions Migration

A tool for managing delegate access on Exchange Online mailboxes. Migrates between Full Mailbox Access and granular folder-level permissions in either direction, and can remove either type of access on its own. Built to support a firm-wide move toward folder-level delegation.

## What it does

Each operation targets a delegate and a mailbox, and runs in one of four directions:

| Direction | Action |
|-----------|--------|
| 1 | **Migrate Full Access to Folder Permissions** — removes Full Mailbox Access and grants `PublishingEditor` on every folder (top level and subfolders), skipping system and hidden folders. |
| 2 | **Revert Folder Permissions to Full Access** — reinstates Full Mailbox Access with automapping and removes the folder-level permissions, preserving Calendar permissions so delegate calendar settings survive the revert. |
| 3 | **Remove Folder Permissions only** — strips folder-level permissions without granting Full Access. |
| 4 | **Remove Full Access only** — removes Full Mailbox Access without adding folder permissions. |

Folder operations are resolved by folder ID, so folders containing special characters are handled safely, and known system or hidden folders (Recoverable Items, Sync Issues, and similar) are skipped.

## Files

| File | Purpose |
|------|---------|
| `IndividualMigrationScript.bat` | Double-click launcher. Runs the migration tool. |
| `IndividualMigrationScript.ps1` | The migration logic. |
| `MigrationInput.csv` | Input file for bulk (CSV mode) operations. |

## How to run

Double-click `IndividualMigrationScript.bat`, or run the script directly:

```powershell
.\IndividualMigrationScript.ps1
```

On launch you choose an input mode:

- **Manual entry** — queue one or more operations interactively. The queue is shown back to you and requires confirmation before any of it runs.
- **CSV import** — bulk process every entry in `MigrationInput.csv`.

## Input format

`MigrationInput.csv` uses three columns:

```csv
SecretaryDelegate,FeeEarnerTargetMailbox,Direction
secretary@company.com,feeearner@company.com,1
secretary2@company.com,feeearner2@company.com,2
```

`Direction` must be `1`, `2`, `3`, or `4` as described in the table above.

## Requirements

- `ExchangeOnlineManagement` module (the script connects automatically if no session is active)
- Permissions to modify mailbox and mailbox-folder permissions in Exchange Online

## Safety features

- **Queue and confirm.** In manual mode, operations are queued and shown back for review; nothing runs until you confirm.
- **Per-operation summaries.** Each operation prints its own result table, and a combined timestamped CSV report is written to the script folder on completion.
- **Calendar preservation.** Reverting to Full Access (Direction 2) deliberately leaves Calendar permissions intact to avoid wiping delegate calendar settings.

## Notes

To audit permissions before or after a migration, use the Check Script in the parent folder.
