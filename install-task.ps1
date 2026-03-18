# install-task.ps1
# 此腳本用於將 switch-hosts.ps1 註冊到工作排程器，以實現自動切換。

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run as Administrator!"
    Pause
    Break
}

$taskName = "MarsHostSwitcher"
$oldTaskName = "SyncSynologyHosts"
$scriptPath = Join-Path (Get-Location) "switch-hosts.ps1"

if (-not (Test-Path $scriptPath)) {
    Write-Error "Could not find switch-hosts.ps1!"
    Pause
    Break
}

# 移除舊任務（如果存在）
if (Get-ScheduledTask -TaskName $oldTaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $oldTaskName -Confirm:$false
    Write-Host "Removed old task '$oldTaskName'."
}

$vbsPath = Join-Path (Get-Location) "launcher.vbs"

# 建立捷徑以註冊 AppID: 網路設定
$shortcutName = "網路設定"
$shortcutPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\$shortcutName.lnk"
if (-not (Test-Path $shortcutPath)) {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Save()
}

$userSid = (Get-WmiObject Win32_UserAccount -Filter "Name='$env:USERNAME' and Domain='$env:USERDOMAIN'").SID

# 定義任務 XML
$taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")</Date>
    <Author>$env:COMPUTERNAME\$env:USERNAME</Author>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
    </LogonTrigger>
    <SessionStateChangeTrigger>
      <Enabled>true</Enabled>
      <StateChange>SessionUnlock</StateChange>
    </SessionStateChangeTrigger>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Delay>PT5S</Delay>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"&gt;&lt;Select Path="Microsoft-Windows-NetworkProfile/Operational"&gt;*[System[(EventID=10000)]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
    </EventTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$userSid</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
    <Compatibility>4</Compatibility>
    <RestartOnFailure>
      <Interval>PT1M</Interval>
      <Count>3</Count>
    </RestartOnFailure>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>wscript.exe</Command>
      <Arguments>"$vbsPath" "$scriptPath"</Arguments>
    </Exec>
  </Actions>
</Task>
"@

# 註冊任務
Register-ScheduledTask -Xml $taskXml -TaskName $taskName -Force

Write-Host "Successfully installed '$taskName'." -ForegroundColor Green
Write-Host "The task will run:"
Write-Host "1. On Log on"
Write-Host "2. On Network change (SSID: Mars)"
Write-Host "3. On Workstation unlock"
# No pause for non-interactive execution
