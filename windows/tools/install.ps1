#Requires -Version 5.1
<#
.SYNOPSIS
  Render the Sensei Windows dotfiles into a user profile.

.DESCRIPTION
  Dry run by default: prints what would change and writes nothing.
  -Apply writes files. Any file that is replaced is first copied to
  %USERPROFILE%\.local\state\dotfiles-backups\<stamp>\ with its relative path.
  Re-running with -Apply makes no changes once the files match.
  Refuses to run as Administrator, like scripts/install.py refuses root.

.PARAMETER TargetHome
  Root to render into. Defaults to the current user's profile. Tests use a temp folder.
#>
[CmdletBinding()]
param(
    [switch]$Apply,
    [string]$TargetHome = $env:USERPROFILE
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot          # windows/
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run as your normal user, not Administrator.'
}

$palette = [IO.File]::ReadAllText((Join-Path $Root 'palette\sensei.json'), [Text.Encoding]::UTF8) | ConvertFrom-Json

function Resolve-Token([string]$Path) {
    $node = $palette
    foreach ($part in $Path.Split('.')) {
        $node = $node.$part
        if ($null -eq $node) { throw "Unknown palette token: $Path" }
    }
    [string]$node
}

function Expand-Template([string]$Text) {
    $evaluator = [System.Text.RegularExpressions.MatchEvaluator] { param($m) Resolve-Token $m.Groups[1].Value }
    [regex]::Replace($Text, '\{\{([a-z_.]+)\}\}', $evaluator)
}

# Source (under windows/home) -> destination (under the target home).
$Entries = @(
    @{ Source = 'home\Documents\PowerShell\Microsoft.PowerShell_profile.ps1'; Dest = 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'; Render = $false },
    @{ Source = 'home\.config\starship.toml';                                  Dest = '.config\starship.toml';                             Render = $true },
    @{ Source = 'home\AppData\Local\alacritty\alacritty.toml';                Dest = 'AppData\Local\alacritty\alacritty.toml';           Render = $true },
    @{ Source = 'home\AppData\Local\Microsoft\Windows Terminal\Fragments\Sensei\sensei.json'; Dest = 'AppData\Local\Microsoft\Windows Terminal\Fragments\Sensei\sensei.json'; Render = $true }
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$backupRoot = Join-Path $TargetHome ".local\state\dotfiles-backups\$stamp"
$changed = New-Object System.Collections.Generic.List[string]
$backedUp = New-Object System.Collections.Generic.List[string]

foreach ($entry in $Entries) {
    $sourcePath = Join-Path $Root $entry.Source
    $destPath = Join-Path $TargetHome $entry.Dest

    $text = [IO.File]::ReadAllText($sourcePath, [Text.Encoding]::UTF8)
    if ($entry.Render) { $text = Expand-Template $text }
    $bytes = $Utf8NoBom.GetBytes($text)

    if (Test-Path -LiteralPath $destPath -PathType Leaf) {
        $current = [IO.File]::ReadAllBytes($destPath)
        if ([Convert]::ToBase64String($current) -eq [Convert]::ToBase64String($bytes)) { continue }
    }

    $changed.Add($entry.Dest)
    if (-not $Apply) { continue }

    if (Test-Path -LiteralPath $destPath) {
        $backupPath = Join-Path $backupRoot $entry.Dest
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backupPath) | Out-Null
        Copy-Item -LiteralPath $destPath -Destination $backupPath -Force
        $backedUp.Add($entry.Dest)
    }

    $parent = Split-Path -Parent $destPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $temp = "$destPath.dotfiles-new"
    [IO.File]::WriteAllBytes($temp, $bytes)
    Move-Item -LiteralPath $temp -Destination $destPath -Force
}

$result = [ordered]@{
    apply    = [bool]$Apply
    target   = $TargetHome
    changed  = @($changed)
    backedUp = @($backedUp)
    backup   = $(if ($backedUp.Count -gt 0) { $backupRoot } else { $null })
}
$result | ConvertTo-Json -Depth 3
