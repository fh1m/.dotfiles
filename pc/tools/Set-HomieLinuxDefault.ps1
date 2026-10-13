# Native Windows counterpart. Inspection is default; -Apply explicitly changes
# only firmware display order, preserving the Windows loader and all partitions.
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param([switch]$Apply)
$ErrorActionPreference = 'Stop'
$systemDisk = Get-Partition -DriveLetter C | Get-Disk
if ($systemDisk.SerialNumber.Trim() -ne 'B2BNDC42100667') {
    throw 'C: is not verified Revenger. No changes.'
}
$linuxDisks = @(Get-Disk | Where-Object { $_.SerialNumber.Trim() -eq 'NBYC26A00A16934' })
if ($linuxDisks.Count -ne 1 -or $linuxDisks[0].Size -ne 256060514304) {
    throw 'Verified Dahua disk is absent or ambiguous. No changes.'
}
$esp = @(Get-Partition -DiskNumber $linuxDisks[0].Number | Where-Object {
    $_.Guid -and ([guid]$_.Guid -eq [guid]'ecc241c3-ebbe-4ca0-bdca-8635593f07b9')
})
if ($esp.Count -ne 1) { throw 'Dahua EFI partition identity mismatch. No changes.' }
$firmware = (& bcdedit.exe /enum firmware /v | Out-String)
if ($LASTEXITCODE -ne 0) { throw 'Run from elevated PowerShell; firmware inventory unavailable.' }
$blocks = @($firmware -split '(?:\r?\n){2,}' | Where-Object {
    $_ -match [regex]::Escape('\EFI\LIMINE\LIMINE_X64.EFI')
})
if ($blocks.Count -ne 1) { throw 'Expected exactly one Limine firmware object. No changes.' }
$identifiers = [regex]::Matches($blocks[0], '\{[0-9a-fA-F-]{36}\}')
if ($identifiers.Count -ne 1) { throw 'Limine firmware identifier is ambiguous. No changes.' }
$linuxId = $identifiers[0].Value
Write-Host "Verified Revenger C:, Dahua EFI and unique Limine firmware object $linuxId."
Write-Host $blocks[0]
if ($Apply -and $PSCmdlet.ShouldProcess('UEFI firmware display order', 'Put verified Limine first')) {
    & bcdedit.exe /set '{fwbootmgr}' displayorder $linuxId /addfirst
    if ($LASTEXITCODE -ne 0) { throw 'Firmware order update failed.' }
    & bcdedit.exe /enum '{fwbootmgr}' /v
    Write-Host 'Inspect readback, then use Restart to return through the Linux menu.'
} else {
    Write-Host 'No changes. Use -Apply for the reviewed native Windows correction.'
}
