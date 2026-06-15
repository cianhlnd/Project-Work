## Repository structure

| Folder | Contents |
|--------|----------|
| [`PowerShellScripts/`](./PowerShellScripts) | Production PowerShell automation developed and deployed in a live IT environment. |
| [`UniProjects/`](./UniProjects) | Academic and personal software projects. |

## PowerShellScripts

A set of production automation tools that handle real, repetitive administrative work across on-premises Active Directory, Exchange Online, and file server storage. Each tool is built around a safety-first model: dry-run previews, explicit confirmation before any live change, per-run logging, and safety limits to guard against accidental bulk operations. Every script declares its module dependencies up front with `#Requires`, and all paths resolve relative to the script's own folder so each tool is self-contained and portable.

| Tool | Purpose |
|------|---------|
| [`LeaverScripts/`](./PowerShellScripts/LeaverScripts) | End-to-end offboarding suite covering AD account disablement and cleanup, Exchange Online mailbox conversion and forwarding, and file server archiving — run in sequence from a single wrapper. |
| [`RotationScripts/`](./PowerShellScripts/RotationScripts) | Automates moving trainees between departments on a rotation cycle, correcting AD group membership, attributes, and shared mailbox access from a JSON configuration file. |
| [`MailboxPermissionsScripts/`](./PowerShellScripts/MailboxPermissionsScripts) | Tools to migrate mailbox delegate access between Full Access and folder-level permissions, plus a read-only auditing tool to report on existing access. |

Each folder has its own README with full usage details, input formats, prerequisites, and safety notes.

> **Note on data:** All scripts have been sanitised for public release. Company names, domains, mailbox addresses, department names, and infrastructure paths have been replaced with placeholders (e.g. `company.com`, `Department1`). No real organisational data is present in this repository.

## UniProjects

Academic and personal projects from my Computer Science degree and self-directed learning.

| Project | Description |
|---------|-------------|
| `final-year-project` | _[Add a one-line description — e.g. tech stack and what it does]_ |
| `Memento` | _[Add a one-line description]_ |
| `MyCommand` | _[Add a one-line description]_ |
| `Shape Creator` | _[Add a one-line description]_ |
| `musicTriviaX` | _[Add a one-line description]_ |