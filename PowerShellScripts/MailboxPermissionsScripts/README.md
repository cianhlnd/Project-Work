# Mailbox Permissions

Tooling for managing and auditing delegate access to mailboxes in Exchange Online. Built to support a firm-wide migration away from broad Full Mailbox Access toward granular, folder-level delegate permissions, with a separate read-only tool for verifying the state of any mailbox.

## Contents

| Folder | Purpose |
|--------|---------|
| `Migration Script/` | Applies and changes delegate access — migrating between Full Mailbox Access and folder-level permissions, or removing either. |
| `Check Script/` | Read-only auditing tool that reports the current Full Access, folder-level, and private-items permissions on a mailbox. |

## Background

In a delegated mailbox setup (for example, a secretary acting on behalf of a fee earner), access can be granted in two broad ways:

- **Full Mailbox Access** - the delegate effectively has the whole mailbox. Simple, but coarse: there is no way to withhold individual folders.
- **Folder-level permissions** - access is granted per folder (e.g. `PublishingEditor` on the inbox and subfolders), which allows finer control over what a delegate can and cannot see.

The Migration Script handles the transition between these two models in either direction. The Check Script is used alongside it to confirm the current state before and after changes, and to support access reviews.

Each subfolder has its own README with the specific usage details, input format, and run instructions.

## Requirements

Both tools require the `ExchangeOnlineManagement` module and permissions to read and modify mailbox and mailbox-folder permissions in Exchange Online. Each script connects to Exchange Online automatically if a session is not already active.

## Safety

The Check Script is entirely read-only and makes no changes. The Migration Script previews queued operations and requires explicit confirmation before applying anything.
