# Post-install verification

Record results in STATE.md after inspecting the actual desktop. Run these locally on the relevant OS; the laptop's outputs describe the laptop, not this PC. These commands inspect state; they do not format disks. Do not mark a test passed from a plan or screenshot of an installer summary.

## Windows PowerShell

```powershell
Get-Disk | Format-Table Number,FriendlyName,SerialNumber,Size,PartitionStyle,IsBoot,IsSystem
Get-Partition -DriveLetter C | Get-Disk | Format-List FriendlyName,SerialNumber,IsBoot,IsSystem
Get-Partition | Format-Table DiskNumber,PartitionNumber,DriveLetter,Type,Size
Get-ComputerInfo | Select-Object WindowsProductName,WindowsVersion,OsBuildNumber,BiosFirmwareType
Get-Tpm
manage-bde -status
powercfg /a
nvidia-smi
```

Get-Tpm/encryption queries may require an elevated PowerShell. An unavailable nvidia-smi before installing the NVIDIA driver is a pending step, not proof the GPU failed.

Success conditions: new C: is **Revenger B2BNDC42100667**, GPT/UEFI; its disk holds the system EFI and Windows/recovery partitions; the old NVMe/Toshiba are preserved. Windows reports Pro through Settings → System → Activation; do not infer the edition only from an ISO filename or a legacy WindowsProductName string. Check activation status separately from installation success.

TPM should be present/ready for the supported Windows setup. Confirm encryption is off or deliberately deferred as requested; hibernation/Fast Startup disabled before Linux NTFS writes. Test network, NVIDIA driver, display, reboot and cold boot. After all disks reconnect, confirm the selected Windows menu entry still boots the new Revenger system.

## CachyOS terminal

```sh
cat /etc/os-release
uname -r
test -d /sys/firmware/efi && echo 'UEFI boot'
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,UUID,MOUNTPOINTS
findmnt /
findmnt /boot
sudo efibootmgr -v
nvidia-smi
systemctl --failed
free -h
swapon --show
/lib/ld-linux-x86-64.so.2 --help
```

If that loader path differs, locate the installed loader; do not invent output. x86-64-v3 should be supported, v4 not supported on this Ryzen 3600X.

Success conditions: root is **Dahua NBYC26A00A16934**, Btrfs; /boot is its own FAT32 EFI of at least 4096 MiB; Limine is installed on that SSD; correct NVIDIA module and user-space driver work. Confirm `/home` subvolume layout and actual snapshot coverage. Do not assume snapshot configuration from choosing Btrfs alone.

GPU work requires actual tests: Vulkan/OpenGL rendering, a CUDA-enabled framework GPU operation, and later a small representative ROS/Gazebo/RViz workload. Install the needed tools first; lack of a test tool is pending, not failed hardware. ROS networking and USB/serial access need checks with real devices/peers. Test an LTS fallback and a recoverable Btrfs snapshot after configuring them.

## Both OSes and protected data

- Menu boot into new Windows and CachyOS; firmware direct boot into each SSD; original Ubuntu fallback on NVMe.
- Confirm boot entries reference the correct SATA EFI partitions. Save EFI/config backups after proving them, using discovered mount paths.
- Verify Toshiba filesystem UUID `3b5d6396-a091-4aac-bb67-fc0e90da988b`, backup completion records and sample restores. It remains ext4; do not accept a Windows format prompt.
- Recheck free capacity. Restore irreplaceable archived SATA files to a second physical drive before relying on the HDD as their only remaining copy. Maintain historical copies rather than blindly merging old configs over new ones.
- Before final NVMe conversion, quiesce changing apps/services or use an offline copy, preserve final Ubuntu personal files plus any new service data, check the preservation copy and confirm both SATA OSes boot without the NVMe. This is a later staged operation.

## Windows user environment (Sensei)

```powershell
pwsh -NoProfile -File pc\windows\tests\install.Tests.ps1
pwsh -NoProfile -File pc\windows\tools\install.ps1
pwsh -NoProfile -File pc\windows\tools\bootstrap.ps1
Get-Process glazewm, yasb -ErrorAction SilentlyContinue | Select-Object ProcessName, Id
```

The first command runs the installer checks. The second is a dry run and writes nothing; `-Apply` needs an approved step. The third lists winget packages and installs nothing without `-Apply`. A passing test is not a screen check: confirm both bars are visible on the desktop after a restart.
