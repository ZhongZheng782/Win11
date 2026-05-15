# Win11

WorkingSpace for Win11

## MarsHostSwitcher

Automatically switches `hosts` file entries for Synology NAS when the network changes between home (Mars Wi-Fi) and office.

### How it works

Two scheduled tasks work together:

| Task | Runs As | Role |
|------|---------|------|
| `MarsHostSwitcher` | SYSTEM | Modifies hosts file + flushes DNS |
| `MarsHostSwitcherNotify` | Current user | Shows balloon notification |

Both tasks trigger on: **Login / Network change / Workstation unlock**

The notification only appears when the hosts sync actually succeeded.

### Install

> Requires **Administrator** privileges.

```powershell
cd C:\path\to\Win11
.\install-task.ps1
```

### Files

| File | Description |
|------|-------------|
| `switch-hosts.ps1` | Main script (`-NotifyOnly` flag for notify-only mode) |
| `install-task.ps1` | Registers the two scheduled tasks |
| `launcher.vbs` | Silent launcher used by the notify task |
| `hosts.template` | NAS host entries to inject into the hosts file |

Shared runtime state is stored in `C:\ProgramData\MarsHostSwitcher\`.

### Logs

```
C:\ProgramData\MarsHostSwitcher\MarsHostSwitcher.log
```
