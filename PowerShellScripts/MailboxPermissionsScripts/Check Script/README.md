# Mailbox Permissions Checker

A read-only auditing tool for Exchange Online mailboxes. Reports what delegate access exists on a mailbox across three dimensions — Full Mailbox Access, folder-level permissions, and private-items (calendar) access — without making any changes.

## What it does

For a given mailbox you choose which checks to run. The tool can report on any combination of:

- **Full Mailbox Access** — non-inherited Full Access grants, excluding system accounts.
- **Folder Permissions** — per-folder access rights across every folder in the mailbox, resolved by folder ID so folders with special characters in their names are handled correctly.
- **Private Items** — whether a delegate can view private calendar items.

You can check a specific delegate, or leave the delegate blank (or `none`) to report on everyone with access to the mailbox. Results are printed to the console grouped by mailbox and check type, and exported to a timestamped CSV report.

## Files

| File | Purpose |
|------|---------|
| `MailboxPermissionsCheckScript.bat` | Double-click launcher. Runs the checker. |
| `MailboxPermissionsCheckScript.ps1` | The auditing logic. |
| `MailboxPermissionCheckInput.csv` | Input file for bulk (CSV mode) checks. |

## How to run

Double-click `MailboxPermissionsCheckScript.bat`, or run the script directly:

```powershell
.\MailboxPermissionsCheckScript.ps1
```

On launch you choose an input mode:

- **Manual entry** — queue one or more checks interactively, then process them together.
- **CSV import** — bulk process every entry in `MailboxPermissionCheckInput.csv`.

## Input format

`MailboxPermissionCheckInput.csv` uses three columns. `SecretaryDelegate` may be left blank or set to `none` to check all delegates on the mailbox. `Direction` selects which checks to run.

```csv
SecretaryDelegate,FeeEarnerTargetMailbox,Direction
secretary@company.com,feeearner@company.com,7
none,feeearner2@company.com,1
```

`Direction` values:

| Value | Checks run |
|-------|------------|
| 1 | Full Mailbox Access |
| 2 | Folder Permissions |
| 3 | Private Items |
| 4 | Full Mailbox Access + Folder Permissions |
| 5 | Full Mailbox Access + Private Items |
| 6 | Folder Permissions + Private Items |
| 7 | All three |

## Requirements

- `ExchangeOnlineManagement` module (the script connects automatically if no session is active)
- Permissions to read mailbox and mailbox-folder permissions in Exchange Online

## Notes

This tool is **read-only** — it reports permissions and never modifies them. A timestamped results CSV is written to the script folder on completion. To apply or change permissions, use the Migration Script in the parent folder.
