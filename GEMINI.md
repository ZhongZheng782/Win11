# Win11

This project serves two primary purposes:
1.  **Windows Environment Setup:** automating the configuration of Windows machines (specifically self-hosted GitHub Actions runners).
2.  **Runner Monitoring:** A Python-based automation to monitor the status of GitHub Actions runners and report to a Google Sheet.

## Project Structure

*   `setup.ps1`: PowerShell script for setting up a Windows environment.
*   `runner-status.py`: Python script to fetch runner statuses from GitHub and update a Google Sheet.
*   `json2dotenv.py`: Helper script to convert Google Service Account JSON files into a string format suitable for environment variables.
*   `.github/workflows/action-runner.yml`: GitHub Actions workflow that periodically runs the monitoring script.

## 1. Windows Environment Setup (`setup.ps1`)

This PowerShell script is designed to provision a Windows machine with common development tools.

**Prerequisites:**
*   Must be run as **Administrator**.
*   Chocolatey must be installed (implied by usage).

**What it does:**
1.  Checks for Administrator privileges.
2.  Displays current user and service information (specifically searching for "actions.runner").
3.  Installs/Updates the following via Chocolatey:
    *   `winmerge`
    *   `vscode`
4.  Upgrades all Chocolatey packages.

**Usage:**
```powershell
# Open PowerShell as Administrator
.\setup.ps1
```

## 2. Runner Monitoring (`runner-status.py`)
...
### Helper: `json2dotenv.py`
...
## 3. Network Switcher (`switch-hosts.ps1`)

Automates network-dependent configurations when the machine moves between home (Mars) and other networks.

**What it does:**
1.  **Detects Network:** Checks if connected to the "Mars" SSID or if the Synology NAS (192.168.31.101) is reachable.
2.  **Hosts Synchronization:** 
    *   **At Home:** Uncomments entries in `hosts.template` and syncs them to `C:\Windows\System32\drivers\etc\hosts`.
    *   **Away:** Comments out those entries to avoid routing issues.
3.  **DNS Fix (Cisco AnyConnect):**
    *   **At Home:** Automatically disables the "Cisco AnyConnect Virtual Miniport Adapter" (Ethernet 2) to prevent it from hijacking DNS, which restores normal DNS resolution.
    *   **Away:** Re-enables the adapter so VPN can function normally if needed.
4.  **Notifications:** Shows a Windows Toast notification (via `launcher.vbs`) to inform the user of the current environment.

**Installation:**
Run `install-task.ps1` as **Administrator** to register the script in Windows Task Scheduler. It will trigger on:
*   User Login
*   Network Change (Event ID 10000)
*   Workstation Unlock

## 4. CI/CD (`.github/workflows/action-runner.yml`)


The monitoring script is automated via GitHub Actions.

*   **Trigger:**
    *   Push to `main`.
    *   Manual dispatch.
    *   **Schedule:** Every 20 minutes (`*/20 * * * *`).
*   **Runner:** `[Windows, x64, Self-hosted]`
*   **Secrets:**
    *   `ENDPOINT1_HEADER_TOKEN`
    *   `ENDPOINT2_HEADER_TOKEN`
    *   `GDRIVE_API_CREDENTIALS`
