# Read-only native Windows acceptance; run from an elevated PowerShell.
$ErrorActionPreference = 'Stop'
$systemDisk = Get-Partition -DriveLetter C | Get-Disk
if ($systemDisk.SerialNumber.Trim() -ne 'B2BNDC42100667') {
    throw 'C: is not the verified Revenger Windows disk. Stop and report this.'
}
$power = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'
$clock = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation'
$nvidia = 'NVIDIA utility unavailable; native driver verification pending.'
if (Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue) {
    $nvidia = (& nvidia-smi.exe '--query-gpu=name,driver_version' '--format=csv,noheader' | Out-String)
}
$result = [ordered]@{
    Timestamp = (Get-Date).ToUniversalTime().ToString('o')
    SystemDisk = $systemDisk | Select-Object FriendlyName, SerialNumber, Size, PartitionStyle, IsBoot, IsSystem
    FastStartupEnabled = $power.HiberbootEnabled
    RealTimeIsUniversal = $clock.RealTimeIsUniversal
    Firmware = (& bcdedit.exe /enum firmware | Out-String)
    PowerStates = (& powercfg.exe /a | Out-String)
    Nvidia = $nvidia
}
$directory = Join-Path $env:LOCALAPPDATA 'Homie\boot-verification'
New-Item -ItemType Directory -Force $directory | Out-Null
$file = Join-Path $directory ('windows-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json')
$result | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 $file
Write-Host "Verified C: is Revenger. Private result saved to $file"
if ($power.HiberbootEnabled -ne 0) { Write-Warning 'Fast Startup needs verification/disablement before Linux NTFS writes.' }
if ($clock.RealTimeIsUniversal -ne 1) { Write-Warning 'Windows UTC RTC alignment remains pending.' }
