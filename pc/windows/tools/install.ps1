#Requires -Version 5.1
<#
.SYNOPSIS
  Render the Sensei Windows setup into a user profile.

.DESCRIPTION
  Dry run by default: prints what would change and writes nothing.
  -Apply writes files and per-user settings. Any file that is replaced is first copied to
  %USERPROFILE%\.local\state\dotfiles-backups\<stamp>\ with its relative path.
  Per-user environment variables live in HKCU\Environment and autostart entries in
  HKCU\...\Run. Nothing here needs Administrator, and the script refuses to run as one.
  Re-running with -Apply makes no changes once everything matches.

.PARAMETER TargetHome
  Root to render into. Defaults to the current user's profile. Tests use a temp folder.
  Environment and autostart are only written when TargetHome is the real profile.
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

# PowerShell reads its profile from the real Documents folder, which OneDrive can redirect
# (for example OneDrive\Documents). Use that folder for the real profile; tests use Documents.
$realDocs = [Environment]::GetFolderPath('MyDocuments')
$docsRel = 'Documents'
if (([IO.Path]::GetFullPath($TargetHome).TrimEnd('\') -eq [IO.Path]::GetFullPath($env:USERPROFILE).TrimEnd('\')) -and
    $realDocs.StartsWith($env:USERPROFILE, [StringComparison]::OrdinalIgnoreCase)) {
    $docsRel = $realDocs.Substring($env:USERPROFILE.Length).TrimStart('\')
}

# Source (under windows/home) -> destination (under the target home).
$Entries = @(
    @{ Source = 'home\Documents\PowerShell\Microsoft.PowerShell_profile.ps1'; Dest = "$docsRel\PowerShell\Microsoft.PowerShell_profile.ps1"; Render = $false },
    @{ Source = 'home\.config\starship.toml';                                  Dest = '.config\starship.toml';                             Render = $true },
    # Alacritty reads %APPDATA%\alacritty, not LocalAppData.
    @{ Source = 'home\AppData\Roaming\alacritty\alacritty.toml';              Dest = 'AppData\Roaming\alacritty\alacritty.toml';        Render = $true },
    @{ Source = 'home\AppData\Local\Microsoft\Windows Terminal\Fragments\Sensei\sensei.json'; Dest = 'AppData\Local\Microsoft\Windows Terminal\Fragments\Sensei\sensei.json'; Render = $true },
    @{ Source = 'home\.glzr\glazewm\config.yaml';                             Dest = '.glzr\glazewm\config.yaml';                       Render = $true },
    @{ Source = 'home\.config\yasb\config.yaml';                              Dest = '.config\yasb\config.yaml';                        Render = $false },
    @{ Source = 'home\.config\yasb\styles.css';                               Dest = '.config\yasb\styles.css';                         Render = $true },
    # Colours the Linux colorscheme reads from ~/.config/sensei/wallpaper-palette.json.
    @{ Source = 'home\.config\sensei\wallpaper-palette.json';                 Dest = '.config\sensei\wallpaper-palette.json';           Render = $true },
    @{ Source = 'home\.local\bin\sensei-weather.py'; Dest = '.local\bin\sensei-weather.py'; Render = $false }
)

# Neovim: the Linux config, copied as is, plus the Windows-only modules. Lazy writes its lockfile
# into the live config folder, so that one is seed-only: it is installed when missing and then left alone.
$nvimFiles = @(
    'init.lua', 'lazy-lock.json', 'colors\sensei.lua', 'syntax\rosmsg.vim',
    'snippets\cpp.lua', 'snippets\python.lua',
    'lua\sensei\options.lua', 'lua\sensei\keys.lua', 'lua\sensei\environment.lua',
    'lua\sensei\lsp.lua', 'lua\sensei\format.lua', 'lua\sensei\debug.lua',
    'lua\sensei\tasks.lua', 'lua\sensei\plugins.lua'
)
foreach ($file in $nvimFiles) {
    $Entries += @{ Source = "home\AppData\Local\nvim\$file"; Dest = "AppData\Local\nvim\$file"; Render = $false; SeedOnly = ($file -eq 'lazy-lock.json') }
}

# Per-user variables that point each tool at its config folder. GlazeWM reads
# ~/.glzr/glazewm/config.yaml by default, so it needs none.
$EnvVars = [ordered]@{
    YASB_CONFIG_HOME = Join-Path $TargetHome '.config\yasb'
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$backupRoot = Join-Path $TargetHome ".local\state\dotfiles-backups\$stamp"
$changed = New-Object System.Collections.Generic.List[string]
$backedUp = New-Object System.Collections.Generic.List[string]

foreach ($entry in $Entries) {
    $sourcePath = Join-Path $Root $entry.Source
    $destPath = Join-Path $TargetHome $entry.Dest
    if ($entry.SeedOnly -and (Test-Path -LiteralPath $destPath)) { continue }

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

# Per-user environment and autostart: only for the real profile, never for a test home.
$realHome = [IO.Path]::GetFullPath($env:USERPROFILE).TrimEnd('\')
$isRealHome = ([IO.Path]::GetFullPath($TargetHome).TrimEnd('\') -eq $realHome)
$envChanged = New-Object System.Collections.Generic.List[string]
if ($isRealHome) {
    foreach ($name in $EnvVars.Keys) {
        $want = [string]$EnvVars[$name]
        $have = [Environment]::GetEnvironmentVariable($name, 'User')
        if ($have -eq $want) { continue }
        $envChanged.Add("env:$name")
        if ($Apply) { [Environment]::SetEnvironmentVariable($name, $want, 'User') }
    }
    # GlazeWM starts YASB itself (see startup_commands in its config), so one Run entry is enough.
    $runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    # The v3.10.1 MSI installs to glzr.io\GlazeWM; the other two are fallbacks.
    $glazewm = @(
        (Join-Path $env:ProgramFiles 'glzr.io\GlazeWM\glazewm.exe'),
        (Join-Path $env:ProgramFiles 'glazewm\glazewm.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\glazewm\glazewm.exe')
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($glazewm) {
        # Wait for the desktop to settle, then start GlazeWM only if it is not already running.
        # A second GlazeWM exits with "Another instance is already running" and shows a fatal dialog.
        $startScript = "Start-Sleep -Seconds 20; if (-not (Get-Process glazewm -ErrorAction SilentlyContinue)) { Start-Process -FilePath '$glazewm' -ArgumentList 'start' }"
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($startScript))
        $cmd = "powershell.exe -NoProfile -WindowStyle Hidden -EncodedCommand $encoded"
        $have = (Get-ItemProperty -Path $runKey -Name 'Sensei-Tiling' -ErrorAction SilentlyContinue).'Sensei-Tiling'
        if ($have -ne $cmd) {
            $envChanged.Add('run:Sensei-Tiling')
            if ($Apply) { Set-ItemProperty -Path $runKey -Name 'Sensei-Tiling' -Value $cmd }
        }
    }
}

$result = [ordered]@{
    apply        = [bool]$Apply
    target       = $TargetHome
    managed      = $Entries.Count
    changed      = @($changed)
    backedUp     = @($backedUp)
    backup       = $(if ($backedUp.Count -gt 0) { $backupRoot } else { $null })
    userSettings = @($envChanged)
}
$result | ConvertTo-Json -Depth 3
