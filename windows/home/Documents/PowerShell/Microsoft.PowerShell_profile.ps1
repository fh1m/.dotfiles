# Sensei · PowerShell profile. Installed by windows/tools/install.ps1.
# Keep this file small: machine-specific secrets and tokens never belong here.

$env:STARSHIP_CONFIG = Join-Path $HOME '.config\starship.toml'
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# History-based inline suggestions. Guarded because older PSReadLine builds lack them.
if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    try { Set-PSReadLineOption -PredictionSource History -ErrorAction Stop } catch { }
    try { Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction Stop } catch { }
    Set-PSReadLineOption -HistoryNoDuplicates
}

function Get-HomieBootCheck {
    # Read-only summary of this machine. Full elevated report: windows/tools/Test-HomieWindows.ps1
    Get-Disk | Format-Table Number, FriendlyName, SerialNumber, Size, PartitionStyle, IsBoot, IsSystem
}
