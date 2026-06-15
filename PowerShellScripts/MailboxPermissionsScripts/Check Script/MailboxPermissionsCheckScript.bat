@echo off
powershell.exe -ExecutionPolicy Bypass -File "%~dp0MailboxPermissionsCheckScript.ps1"
pause
