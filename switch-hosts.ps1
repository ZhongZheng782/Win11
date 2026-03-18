# switch-hosts.ps1
# Pure ASCII script. Optimized for ZERO-FLASHING and THROTTLED notifications.

$logFile = "$env:TEMP\MarsHostSwitcher.log"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# --- THROTTLE CHECK ---
# Prevent multiple notifications within 10 seconds
$lastRunFile = "$env:TEMP\MarsHostSwitcher.lastrun"
if (Test-Path $lastRunFile) {
    $lastRunTime = Get-Date (Get-Content $lastRunFile)
    if ((Get-Date) -lt $lastRunTime.AddSeconds(10)) {
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Throttled (Ran too recently)" | Out-File $logFile -Append
        Exit
    }
}
Get-Date | Out-File $lastRunFile

"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Script started (Admin: $isAdmin)" | Out-File $logFile -Append

# Wait for network stability
Start-Sleep -Seconds 5

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptRoot) { $scriptRoot = Get-Location }
$templateFile = Join-Path $scriptRoot "hosts.template"
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$synologyIP = "192.168.31.101" 
$homeSSID = "Mars"

if (-not (Test-Path $templateFile)) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Error: hosts.template not found" | Out-File $logFile -Append
    Break
}

$currentNetworks = Get-NetConnectionProfile | Select-Object -ExpandProperty Name
$isMars = $currentNetworks -contains $homeSSID
$canPing = Test-Connection -ComputerName $synologyIP -Count 1 -Quiet

function Show-Notification {
    param([string]$Title, [string]$Message)
    try {
        $ErrorActionPreference = "Stop"
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
        $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
        $textNodes = $template.GetElementsByTagName("text")
        $textNodes.Item(0).AppendChild($template.CreateTextNode($Title)) > $null
        $textNodes.Item(1).AppendChild($template.CreateTextNode($Message)) > $null
        $toast = [Windows.UI.Notifications.ToastNotification]::new($template)
        $toast.ExpirationTime = [DateTimeOffset]::Now.AddSeconds(5)
        
        # AppID: ???? (Registered via shortcut in install-task.ps1)
        $appName = [char]0x7DB2 + [char]0x8DEF + [char]0x8A2D + [char]0x5B9A
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appName).Show($toast)
    } catch {
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Notification Error: $_" | Out-File $logFile -Append
    }
}

if ($isMars -or $canPing) {
    $atHome = $true
    $title = [char]0xD83C + [char]0xDFE1 + " " + [char]0x5728 + [char]0x5BB6 + [char]0x4E2D + ".."
    $msg = [char]0x5DF2 + [char]0x9023 + [char]0x7DDA + [char]0x81F3 + " $homeSSID, NAS " + [char]0x8A2D + [char]0x5B9A + [char]0x5DF2 + [char]0x540C + [char]0x6B65 + [char]0x3002
    Show-Notification -Title $title -Message $msg
} else {
    $atHome = $false
    $title = [char]0xD83C + [char]0xDFE2 + " " + [char]0x5728 + [char]0x5916 + [char]0x9762 + ".."
    $msg = [char]0x7DB2 + [char]0x8DEF + [char]0x5DF2 + [char]0x5207 + [char]0x63DB + " ($currentNetworks), NAS " + [char]0x8A2D + [char]0x5B9A + [char]0x5DF2 + [char]0x505C + [char]0x7528 + [char]0x3002
    Show-Notification -Title $title -Message $msg
}

if (-not $isAdmin) { Break }

$startMarker = "# === SYNOLOGY START ==="
$endMarker = "# === SYNOLOGY END ==="
$templateLines = Get-Content $templateFile
if (-not $atHome) {
    $templateLines = $templateLines | ForEach-Object { if ($_ -match "\S" -and $_ -notmatch "^#") { "#" + $_ } else { $_ } }
}

$maxRetries = 5
$retryCount = 0
$success = $false
while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        $ErrorActionPreference = "Stop"
        $currentHosts = Get-Content $hostsPath
        $newHosts = @()
        $inSection = $false
        $sectionFound = $false
        foreach ($line in $currentHosts) {
            if ($line -eq $startMarker) {
                $inSection = $true
                $sectionFound = $true
                $newHosts += $startMarker
                $newHosts += $templateLines
                continue
            }
            if ($line -eq $endMarker) {
                $inSection = $false
                $newHosts += $endMarker
                continue
            }
            if (-not $inSection) { $newHosts += $line }
        }
        if (-not $sectionFound) {
            $newHosts += "`n$startMarker"
            $newHosts += $templateLines
            $newHosts += $endMarker
        }
        $newHosts | Set-Content $hostsPath -Encoding ASCII
        $success = $true
    } catch {
        $retryCount++
        Start-Sleep -Seconds 1
    }
}

if ($success) {
    ipconfig /flushdns
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Sync success" | Out-File $logFile -Append
}
