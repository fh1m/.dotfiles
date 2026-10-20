#Requires -Version 5.1
<#
.SYNOPSIS
  Install the Windows tools the Sensei setup uses, via winget. Dry run by default.

.DESCRIPTION
  Lists every package, marks which are already installed, and installs only the
  missing ones with -Apply. Uses exact package IDs; never installs over an existing one.
  The fonts are not in this list: ZedMono NF and Iosevka NFM are installed by hand from
  the pinned release in SETUP.md, because the Sensei labels and numbers depend on them.
#>
[CmdletBinding()]
param([switch]$Apply)

$ErrorActionPreference = 'Stop'

# Exact winget IDs. Min is the version read from winget on 2026-10-20; it is a floor, not a pin.
$Packages = @(
    @{ Id = 'Microsoft.PowerShell';      Name = 'PowerShell 7';                        Min = '7.6.7' },
    @{ Id = 'Starship.Starship';         Name = 'Starship prompt';                     Min = '1.27.0' },
    @{ Id = 'Neovim.Neovim';             Name = 'Neovim';                              Min = '0.12.6' },
    @{ Id = 'Alacritty.Alacritty';       Name = 'Alacritty';                           Min = '0.17.0' },
    @{ Id = 'junegunn.fzf';              Name = 'fzf';                                 Min = '0.74.5' },
    @{ Id = 'Python.Python.3.13';        Name = 'Python 3.13 (real, not the Store stub)'; Min = '3.13.15' },
    @{ Id = 'Git.Git';                   Name = 'Git';                                 Min = '2.55.0' },
    @{ Id = 'GitHub.cli';                Name = 'GitHub CLI';                          Min = '2.102.0' },
    @{ Id = 'Microsoft.WindowsTerminal'; Name = 'Windows Terminal';                    Min = '1.24.12741.0' },
    @{ Id = 'glzr-io.glazewm';           Name = 'GlazeWM (tiling WM)';                 Min = '3.10.1' },
    @{ Id = 'AmN.yasb';                  Name = 'YASB (status bar)';                   Min = '2.0.7' }
)

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is not available. Install App Installer from the Microsoft Store, then re-run.'
}

$report = foreach ($pkg in $Packages) {
    $listed = & winget list --id $pkg.Id -e --accept-source-agreements 2>$null | Out-String
    $installed = $listed -match [regex]::Escape($pkg.Id)
    $action = if ($installed) { 'present' } else { 'missing' }
    if ($Apply -and -not $installed) {
        & winget install --id $pkg.Id -e --source winget --silent --accept-package-agreements --accept-source-agreements
        $action = if ($LASTEXITCODE -eq 0) { 'installed' } else { "failed ($LASTEXITCODE)" }
    }
    [pscustomobject]@{ Name = $pkg.Name; Id = $pkg.Id; MinVersion = $pkg.Min; Status = $action }
}

$report | Format-Table -AutoSize
if (-not $Apply) { Write-Host 'Dry run. Re-run with -Apply to install the missing packages.' }
