# PowerShellCoding

PowerShell scripts, administrative utilities, and working examples for Windows systems administration. This repository covers Windows and Windows Server, Active Directory, Microsoft 365 / Exchange, Remote Desktop Services, Hyper-V, Windows Update, and workstation setup.

Maintained by [@RivalDad](https://github.com/RivalDad). Contributions and improvements are welcome.

> **Repository status:** This is a collection of scripts and reference material, **not** a versioned or production-certified PowerShell module. The scripts vary in age, completeness, prerequisites, and operational impact. Review the source and test in an isolated environment before use.

## What's included

| Area | Examples | What to expect |
| --- | --- | --- |
| Windows inventory | [Reboot check](Scripts/Get-PendingReboot.ps1), [hardware information](Scripts/Get-ServerHardwareInfo.ps1) | Local diagnostics and inventory snippets |
| Active Directory | [User OU lookup](Scripts/get-UserOU.ps1), [group membership](Scripts/Get-UserGroupMembership.ps1) | Directory queries and some account-changing procedures |
| Microsoft 365 / Exchange | [Mailbox report](Scripts/Get-MailboxReport.ps1), [external forwarding review](Scripts/Get-O365ExternalMailForward.ps1) | Reporting and legacy administrative examples; some require modernization |
| RDS / Hyper-V / DFSR | [Profile disk report](Scripts/Get-UserProfileDisks.ps1), [DFSR backlog](Scripts/Get-DFSRbacklog.ps1) | Infrastructure diagnostics and potentially state-changing WMI operations |
| Windows updates and provisioning | [Update history](Scripts/Get-UpdateHistory.ps1), [Windows update installation](Scripts/Install-WindowsUpdate.ps1), [workstation setup](Scripts/Setup-Windows.ps1) | Both reporting and **system-changing** scripts |

**[Browse the complete script catalog](docs/SCRIPT_CATALOG.md)** for descriptions, impact labels, and known caveats for all 43 PowerShell files.

## Getting started

1. **Review** the script you intend to run, including every command, path, credential prompt, and external dependency.
2. **Check prerequisites:** many scripts target Windows PowerShell 5.1 and Windows-specific APIs; PowerShell 7 support has not been validated. Depending on the script, you may need RSAT ActiveDirectory, Hyper-V, Exchange Online / Microsoft 365 modules, or administrative permissions. Several older scripts use legacy Microsoft 365 connections that may no longer work.
3. **Test** in a nonproduction environment, then run with the minimum privileges necessary.

For example, on Windows, clone the repository and run the reboot-status check (an informational script):

```powershell
git clone https://github.com/RivalDad/PowershellCoding.git
Set-Location .\PowershellCoding
powershell.exe -NoProfile -File .\Scripts\Get-PendingReboot.ps1
```

The example checks common reboot-pending indicators and outputs `True` or `False`. It is **not** a general instruction to execute other scripts without review. Follow your organization's execution policy and change-control process.

## Important safety notes

- **Some scripts make irreversible or disruptive changes**, including disabling accounts, removing group memberships or user profiles, uninstalling apps, changing registry keys, and installing Windows updates. A report-oriented filename does not guarantee read-only behavior.
- **Some files contain environment-specific values** such as paths, server names, or integration configuration; replace or remove these before reuse. Do not commit tenant identifiers, customer data, access tokens, signed URLs, or other secrets.
- **Legacy dependencies:** scripts using `MSOnline`, basic-authentication remote PowerShell, or older Office deployment helpers should be treated as historical examples until modernized and validated.
- **No blanket compatibility or testing claim:** scripts have not been validated together or against a published OS / module support matrix. Read the [catalog](docs/SCRIPT_CATALOG.md) for file-specific cautions.

## Contributing and security

Bug reports, improvements, documentation, and tested fixes are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for submission guidelines. For a potentially sensitive security issue, follow [SECURITY.md](SECURITY.md); do not publish exploit details or secrets in a public issue.

## License and attribution

The repository's top-level [LICENSE](LICENSE) contains **The Unlicense**. Some files also contain notices identifying other authors or distinct terms. Preserve those notices and confirm your right to reuse or redistribute any third-party material; the repository-level license does not override third-party rights.

All scripts are provided **as-is**, without warranty or a guarantee of suitability for a particular environment.
