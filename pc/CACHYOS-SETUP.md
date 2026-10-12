# CachyOS workstation setup: verified hardware, planned changes

This is a plan for the NEW CachyOS install, not a script to run on current Ubuntu. Do not apply laptop-specific hybrid-GPU, ASUS laptop, or ScreenPad settings from the user's dotfiles.

## Base install

- Target Dahua C800 256GB, serial NBYC26A00A16934 only. UEFI/GPT, its own 4 GiB FAT32 EFI partition mounted at /boot, remaining disk Btrfs with CachyOS subvolumes. Limine boot manager. Use stable CachyOS repositories; no testing repo.
- Ryzen 5 3600X is Zen 2. The running loader confirms x86-64-v3 support, not v4. Use installer-selected v3 packages; never force znver4/v4 packages onto this CPU.
- Start with stock linux-cachyos and the matching NVIDIA driver selected by chwd. Add an LTS kernel with its matching NVIDIA module as fallback. Do not stack several custom schedulers/governor tweaks before measuring stock performance.
- GTX 1660 SUPER is Turing with 6 GiB VRAM. NVIDIA's open kernel modules support Turing; use CachyOS packages, never NVIDIA's .run installer. Verify nvidia-smi, OpenGL/Vulkan and a CUDA/framework workload. Keep modules matched across every installed kernel. Do not disable GSP when using open modules, which require it.
- User prefers keyboard-first Hyprland and existing dotfiles. Establish a functioning session first, then adapt the desktop-specific dotfiles. Keep an available fallback desktop/session for troubleshooting. Do not blindly overwrite the whole new ~/.config with an old distro profile.

## Workloads

- ROS Humble projects retain Ubuntu 22.04 environments; Jazzy projects retain Ubuntu 24.04 environments. Official Jazzy binaries are Ubuntu-based, not native Arch packages. Use explicit, pinned Docker/Distrobox environments when official ROS dependencies matter. Containers share the host kernel and are not full VMs. Configure GUI/GPU, device access and DDS networking deliberately, and test Gazebo/RViz plus ROS discovery. Native Arch ROS builds are optional per-project work, not the default compatibility promise.
- Configure NVIDIA Container Toolkit from distribution packages and test a pinned GPU-enabled container. Store important source code/data in host bind mounts so replacing containers cannot delete them. Do not preserve irreplaceable data solely inside disposable container writable layers.
- ML: use per-project Python environments and pinned CUDA-capable framework builds that include Turing/sm_75 support. Match driver/runtime/framework compatibility. Validate an actual GPU operation before installing a large bundle of AI tools. Six GiB VRAM limits model/batch size; an OS tweak does not increase physical VRAM or add RTX tensor hardware.
- Keep CPU build concurrency bounded for 16 GiB RAM: start around six aggregate compiler processes and measure peak memory. Use ccache where appropriate. Put source, build directories, datasets and container storage on NVMe after its final conversion.
- Grant serial/USB access with appropriate udev rules and groups for the NEW distro; never chmod device nodes or the whole home directory to 777. Test actual robotics peripherals.

## Storage and reliability

- Initially leave NVMe Ubuntu root/home/EFI/swap untouched. Use Dahua for the new system until the final NVMe migration. Later mount Linux NVMe Btrfs at /data by filesystem UUID; shared NTFS at /shared; HDD ext4 at /storage.
- Enable and confirm periodic SSD TRIM, limited Btrfs snapshots and maintenance. Use a modest compression setting such as zstd:1 initially if appropriate to installer defaults; benchmark rather than assume higher compression helps already compressed datasets.
- Keep CachyOS's existing ZRAM and memory settings initially; do not layer conflicting Zswap/ZRAM configurations on top. Check behavior under actual workloads and size a disk-backed fallback swap only if needed.
- Enable Snapper/Limine integration, bound snapshot/kernel retention, and monitor root/EFI free space. Save a verified boot-config and EFI copy on HDD. Do not assume root rollback restores data in every home/data subvolume.
- Automate selected, versioned backups and drive-health notifications after baseline boot tests. Toshiba has finite space; full-drive backup of all disks will not fit. No encryption now, per user.
- Keep CPU power management and security mitigations at defaults. No blanket mitigations=off, overclock, forced persistent GPU clocks, or speculative kernel command-line flags.

## Hardware improvements, separate from installation

- RAM is 2x8GB Corsair DDR4-3200 but the firmware previously reported 2133 MT/s. Check the BIOS/DOCP profile after establishing a stable baseline; test memory before trusting an altered setting. Do not promise 3200 stability without testing.
- Motherboard is ASUS TUF B450M-PLUS GAMING, BIOS 2202 (2020). Review firmware/fTPM requirements before Windows setup; no unattended BIOS flash. SVM was disabled and TPM was not exposed in Ubuntu. Enable required supported firmware features with a recorded recovery route, not compatibility bypasses by default.
- Ethernet is currently 100 Mbps despite a gigabit-capable Realtek NIC. Check cable and router/switch ports. OS tuning cannot raise a physical 100 Mbps negotiated link to gigabit.
- LG display exposes approximately 75 Hz as well as 60 Hz. Select/test 75 Hz after NVIDIA/desktop setup.
- A 32 GiB RAM upgrade is likely more useful for concurrent ROS simulation, compilation and ML than aggressive kernel tweaks, but no purchase or performance guarantee is made here.

## Acceptance checks before migrating off Ubuntu

Cold boot and restart into Windows and CachyOS; firmware direct boot of both SSDs; visible Limine choices; LTS kernel boot; snapshot recovery; nvidia-smi and CUDA/framework operation; Vulkan/game smoke test; ROS GUI, discovery and actual devices; backup restore of selected files; clean NTFS access after full Windows shutdown. Record results, do not mark tests passed before running them.

Sources: [CachyOS optimized repositories](https://wiki.cachyos.org/features/optimized_repos/), [CachyOS settings](https://wiki.cachyos.org/features/cachyos_settings/), [CachyOS tweaks](https://wiki.cachyos.org/configuration/general_system_tweaks/), [NVIDIA kernel modules](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/kernel-modules.html), [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html), [Open Robotics Jazzy release](https://www.openrobotics.org/blog/2024/5/ros-jazzy-jalisco-released).
