# Graphics ABI repair — Arete, 2026-10-20

The permanent fix is an aligned, package-managed Mesa/LLVM stack. Do not pin
Mesa alone while updating its LLVM dependency. Do not replace missing LLVM
SONAMEs with symlinks to a different major version.

## Confirmed cause

`IgnorePkg = mesa lib32-mesa` left Mesa 26.1.1 installed while the system moved
to LLVM 23. `ldd` on both Mesa EGL and GLX reported missing `libLLVM.so.22.1`.
This was a held CachyOS package, not evidence of a locally edited Mesa library:
`pacman -Qkk mesa` reported zero altered files. Earlier recovery notes called it
custom; that was an overly broad description of the installed stack.

The same full upgrade installed NVIDIA userspace 615.78.08 and a matching module
for CachyOS 7.2.11, but the running 7.2.8 session retained NVIDIA 615.71.09.
Those are separate failures: repairing Mesa restores Intel rendering immediately;
a normal reboot is necessary to replace the in-use NVIDIA kernel module safely.

## Applied repair

- Saved the original pacman configuration locally before edits.
- Removed only Mesa/lib32-Mesa from IgnorePkg, preserving repositories and trust.
- Refreshed signed databases and downloaded the complete upgrade transaction.
- Preflighted the signed replacement Mesa against installed LLVM 23 and created
  a real Intel Wayland EGL context using it before installation.
- Installed the full pending transaction, including Mesa/lib32-Mesa 26.2.4.
- Verified EGL and GLX have no unresolved dependencies and both package file
  checks report zero altered files.
- Verified actual Intel Wayland OpenGL rendering without a private library path.
- Removed the temporary den-cursor runtime library override and relaunched the
  shell/cursor renderer without the old NVIDIA/LLVM recovery directory.
- Left input capture, desktop applications, disks and compositor running.

Private backups and package logs are under
`~/.local/state/sensei/graphics-repair/`; the original root configuration backup
is `/etc/pacman.conf.before-graphics-repair-20261020`. They are not published.
Cached recovery libraries are retained as inactive recovery material.

## Check now and after reboot

```sh
cd ~/.dotfiles
python3 scripts/check-graphics-stack.py
# 0 = aligned; 1 = broken libraries; 2 = NVIDIA reboot still required.
# --json gives a machine-readable receipt and ignores LD_LIBRARY_PATH/LD_PRELOAD.
ldd /usr/lib/libEGL_mesa.so.0 | rg 'LLVM|not found'
XDG_RUNTIME_DIR=/run/user/$(id -u) eglinfo -B -p wayland
nvidia-smi
```

Before reboot, `nvidia-smi` can still report the known loaded/installed mismatch.
Do not unload NVIDIA under the running multi-monitor compositor. Save work and
reboot normally. The installed CachyOS 7.2.11 module reports NVIDIA 615.78.08;
physical output and NVIDIA operation after reboot are not yet verified.

Use normal complete system upgrades (`pacman -Syu`). If a future renderer needs
an upstream workaround, retain it at its narrow implementation boundary rather
than indefinitely freezing Mesa. The existing Aquamarine display patch is
unchanged. Private Qt builds should be rebuilt after a Qt minor-version upgrade;
the main shell already selects the packaged binary when its Qt stamp differs.

References: [Arch system maintenance](https://wiki.archlinux.org/title/System_maintenance),
[Arch Mesa package SONAMEs](https://archlinux.org/packages/extra/x86_64/mesa/sonames/).
