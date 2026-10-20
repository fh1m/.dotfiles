#Requires -Version 5.1
<#
  Plain-assertion tests for windows/tools/install.ps1. No Pester needed, so the same file
  runs on this PC and in CI. Each check throws on failure; the script exits non-zero.
#>
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Installer = Join-Path $Root 'tools\install.ps1'
$failures = 0

function Assert-True([bool]$Condition, [string]$Message) {
    if ($Condition) { Write-Host "PASS  $Message" }
    else { Write-Host "FAIL  $Message"; $script:failures++ }
}

function New-TempHome {
    $path = Join-Path ([IO.Path]::GetTempPath()) ('sensei-test-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $path | Out-Null
    $path
}

function Get-Tree([string]$Path) {
    if (-not (Test-Path $Path)) { return '' }
    (Get-ChildItem -LiteralPath $Path -Recurse -File | Sort-Object FullName | ForEach-Object {
        $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        $_.FullName.Substring($Path.Length) + ' ' + $hash
    }) -join "`n"
}

# 1. Dry run must write nothing.
$home1 = New-TempHome
$before = Get-Tree $home1
$dry = & $Installer -TargetHome $home1 | ConvertFrom-Json
Assert-True ((Get-Tree $home1) -eq $before) 'dry run writes nothing'
Assert-True ($dry.apply -eq $false) 'dry run reports apply=false'
Assert-True ($dry.changed.Count -eq 8) 'dry run lists all eight managed files'

# 2. Apply writes the four files, rendered.
$applied = & $Installer -Apply -TargetHome $home1 | ConvertFrom-Json
$alacritty = Join-Path $home1 'AppData\Local\alacritty\alacritty.toml'
Assert-True (Test-Path $alacritty) 'apply writes alacritty.toml'
$alacrittyText = [IO.File]::ReadAllText($alacritty)
Assert-True ($alacrittyText -notmatch '\{\{') 'no template tokens remain after render'
Assert-True ($alacrittyText -match 'background = "#090807"') 'terminal background token rendered'
Assert-True ($alacrittyText -match 'program = "pwsh"') 'alacritty launches PowerShell 7'
Assert-True ($applied.changed.Count -eq 8) 'first apply changes eight files'
Assert-True ($applied.backup -eq $null) 'no backup on first apply (nothing replaced)'

# 3. Second apply is a no-op.
$again = & $Installer -Apply -TargetHome $home1 | ConvertFrom-Json
Assert-True ($again.changed.Count -eq 0) 'second apply makes zero changes'

# 4. A user-edited file is backed up before it is replaced.
$starship = Join-Path $home1 '.config\starship.toml'
Add-Content -LiteralPath $starship -Value '# user edit'
$edited = & $Installer -Apply -TargetHome $home1 | ConvertFrom-Json
Assert-True ($edited.changed -contains '.config\starship.toml') 'edited starship.toml is detected'
Assert-True ($edited.backedUp -contains '.config\starship.toml') 'edited starship.toml is backed up'
Assert-True (Test-Path (Join-Path $edited.backup '.config\starship.toml')) 'backup copy exists under the stamped folder'
Assert-True (-not ([IO.File]::ReadAllText($starship) -match '# user edit')) 'managed file is restored to repo content'

# 5. The palette is the only colour source: changing a token changes the render.
$rendered = [IO.File]::ReadAllText((Join-Path $home1 '.config\starship.toml'))
Assert-True ($rendered -match "rose = '#fb4670'") 'starship palette rendered from palette/sensei.json'

# 6. Komorebi border colours come from the palette, and a test home never writes per-user settings.
$komorebi = [IO.File]::ReadAllText((Join-Path $home1 '.config\komorebi\komorebi.json'))
Assert-True ($komorebi -match '"single":\s*\{ "r": 242, "g": 61,\s+"b": 112 \}') 'komorebi single border is the Sensei rose'
Assert-True ($applied.userSettings.Count -eq 0) 'test home writes no environment or autostart settings'

Remove-Item -LiteralPath $home1 -Recurse -Force
Write-Host ''
if ($failures -gt 0) { Write-Host "$failures check(s) failed."; exit 1 }
Write-Host 'All installer checks passed.'
