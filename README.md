# Sensei · Windows

The Windows port of the Sensei desktop. This branch is **Windows-only**: it does not
share files with the Linux setup on `main`. The two keep the same palette and mindset,
not the same code.

```powershell
cd ~\dotfiles-windows
powershell -NoProfile -ExecutionPolicy Bypass -File windows\tools\bootstrap.ps1          # dry run: what is missing
powershell -NoProfile -ExecutionPolicy Bypass -File windows\tools\bootstrap.ps1 -Apply   # install missing tools
powershell -NoProfile -ExecutionPolicy Bypass -File windows\tools\install.ps1            # dry run: what would change
powershell -NoProfile -ExecutionPolicy Bypass -File windows\tools\install.ps1 -Apply     # write, with backups
```

- Dry run is the default. `-Apply` backs up every replaced file under
  `%USERPROFILE%\.local\state\dotfiles-backups\<stamp>\`.
- Run as your normal user. The installer refuses an Administrator session.
- Re-running is safe: once files match, nothing changes.

## What is here

| Path | Purpose |
|---|---|
| `windows/palette/sensei.json` | Single colour source. Every template reads from it. |
| `windows/home/` | Files that get rendered into your profile (PowerShell, Starship, Alacritty, Windows Terminal). |
| `windows/tools/install.ps1` | Renders and installs the files above. |
| `windows/tools/bootstrap.ps1` | Installs missing tools with exact winget IDs. |
| `windows/tools/Test-HomieWindows.ps1` | Read-only hardware and boot check. Run it elevated. |
| `windows/tools/Set-HomieLinuxDefault.ps1` | The only firmware write. Dry run unless `-Apply`. |
| `windows/tests/install.Tests.ps1` | Installer checks. Runs on this PC and in CI. |
| `windows/docs/PORT.md` | How each Linux piece maps to Windows, and the lag findings. |

## Not in scope yet

Tiling window manager, status bar and the Den input-sharing features are not ported in
this branch. See `windows/docs/PORT.md` for the planned Windows equivalents.
