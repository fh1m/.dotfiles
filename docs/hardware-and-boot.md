# Hardware, displays, power and boot

[← Workstation](../README.md) · [Installation](installation.md)

## Reference machine

ASUS ZenBook Pro Duo UX581GV, Intel UHD 630, NVIDIA RTX 2060, Intel AX200 wireless and two vertically arranged built-in panels. The configuration uses named outputs rather than relying on DRM enumeration order. Installed baseline versions are recorded separately; those are observations, not mandatory downgrade targets.

| Output | Mode | Scale | Logical position |
|---|---|---|---|
| eDP-1 | 3840×2160 at 60 Hz | 2 | 0×0 |
| DP-2 ScreenPad | 3840×1100 at ~60.02 Hz | 2 | 0×1080 |

The ScreenPad physically sits below the main display. It has its own bottom bar and brightness control. The main panel owns top-bar detail views. Both use comfortable logical text sizing.

## ScreenPad driver

The custom [Plippo/asus-wmi-screenpad](https://github.com/Plippo/asus-wmi-screenpad) module exposes ScreenPad backlight support on the relevant ASUS hardware. Use its current upstream installation instructions, matching kernel headers and DKMS where supported. Verify `asus_screenpad` under `/sys/class/backlight`, not just whether a package installed.

```sh
ls /sys/class/backlight
cat /sys/class/backlight/asus_screenpad/max_brightness
asusctl backlight --screenpad-brightness 100
```

If your asusctl build does not expose that custom option, use `brightnessctl -d asus_screenpad` after checking device permissions. Verify the custom module after kernel updates and in the actual booted initramfs. Not every fallback kernel was tested with the custom driver.

Dedicated fan, screen-swap and ScreenPad keys emitted ASUS-specific events. The setup maps those through `zenbook-hotkeys.xkb` for the `asus-wmi-hotkeys` device, leaving ordinary keyboards unchanged. Use captured events for your model rather than assuming all ASUS laptops send the same keycodes.

## Power and cooling

The reference backend is system76-power. Performance/turbo and boost cooling are used on AC, balanced/firmware fan policy on battery. Screen brightness is preserved when a backend profile would otherwise dim it. Training keeps the session awake; leaving training does not cause immediate forced suspend.

Manual dim/lock policy: no idle dim, no automatic idle lock; battery-only suspend after ten minutes, no AC idle suspend. After resume the ScreenPad is restored. Manual lock and power controls remain explicit.

The root fan helper accepts only `auto` and `boost` and checks UX581GV. Hardware control and its narrow sudo permissions are separate from the user dotfiles. Do not grant unrestricted passwordless shell access to make a widget button work.

## NVIDIA power and updates

Internal panels stay Intel-wired. NVIDIA runtime power policy uses stable PCI addresses. The NVIDIA HDMI ancestry, rather than an obsolete DRM card number, determines when an external display needs the GPU awake. Dynamic Boost startup was disabled because the tested hardware does not meet its requirements; CUDA access was retained.

`system/etc/modprobe.d/nvidia.conf` is a **reference example**. Match options to your current NVIDIA driver documentation. Do not apply an obsolete kernel option merely because it appeared in an old guide. Maintain kernel/userspace alignment and a bootable fallback.

## Bootloader to working state

The desired aesthetic was a hidden GRUB menu and clean boot. The retained changes hid the normal menu and removed unnecessary GRUB theme/font overhead. Recovery entries were kept. The ASUS firmware logo was **not** replaced or flashed; firmware branding is not the same as a Plymouth theme. There is no claim of a custom BIOS logo or universal direct-boot modification.

Reference postboot timing was 32.321 s across firmware, loader, kernel, initrd and userspace. GDM login occurred earlier than a lingering `plymouth-quit-wait` unit finished. A systemd target timestamp is not necessarily the first usable desktop frame. No verified boot-speed improvement was claimed before a subsequent comparable boot.

```sh
systemd-analyze time
systemd-analyze critical-chain
systemd-analyze blame
journalctl -b -p warning
systemctl --failed
```

Review a unit’s dependency path before disabling it. `network-online` waiting had dependents including Docker/update services; it was not blindly removed. Firmware/initramfs contents were retained rather than deleting required firmware to make an image smaller.

If adjusting GRUB, back up `/etc/default/grub`, retain the ability to reveal the menu, regenerate `/boot/grub/grub.cfg` using the distribution’s supported process, and validate before reboot. Do not use a blanket copy of root configuration on another laptop.

## Credentials and sessions

The actual migration preserved browser profiles and GNOME Keyring. Automatic login plus a passwordless keyring was a deliberate convenience/security tradeoff on the original machine; the exported setup does not make it for you. Prefer disk encryption and a normal password/PAM unlock path where appropriate. Secrets and login policies are not included in Git.

## Other laptop checklist

Replace output names/modes/scale, power backend, fan interfaces, touchpad name, special keycodes, render PCI addresses, Bluetooth headset match and phone identity. Test suspend/resume, Wi-Fi reconnect, battery policy, camera/microphone and charging controls before making the desktop your only session.
