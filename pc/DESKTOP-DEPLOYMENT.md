# Desktop deployment

The laptop's base home/ and system/ sources retain their own policy. The pc overlay supplies the direct-NVIDIA desktop policy and UI adaptations. Read AGENTS.md and STATE.md before changing boot or storage.

## Reapply or restore

Use the complete checkout, not a pc-only sparse checkout:

```sh
cd "$HOME/.dotfiles-pc"
git sparse-checkout disable  # only if sparse checkout is enabled
python3 scripts/install.py --hardware pc
python3 scripts/test-install.py
python3 scripts/install.py --hardware pc --apply
sensei-palette "$HOME/Pictures/wallpapers/wallhaven-1q2p3v.png"
```

Preview and apply produce JSON listing changed paths. Each apply stores a private manifest under ~/.local/state/dotfiles-backups. To undo a particular apply, pass its exact backup directory to `python3 scripts/install.py --restore /absolute/backup/path`. Several incremental applies require reversing their manifests newest first. Do not treat root Snapper snapshots as home backups: @home is separate. Never put private manifests, wallpaper artwork or home copies in Git.

Machine facts come from sensei-machine and pc/home/.config/sensei/machine.json. This desktop has one direct NVIDIA GPU, DP-3, scale 1, no Intel GPU, no battery and no ScreenPad. The advertised LG mode is 1920x1080 at 74.97 Hz. Rediscover output names before reusing this profile on different hardware.

## Desktop behavior

Wrayth retains the personal workspace, switcher, media and robotics UI. Desktop overlays enable animations, two-pass blur, shadows, glass and translucent terminals. Inter handles interface text; JetBrains Mono Nerd Font handles terminals and aligned data. Starship supplies the new zsh prompt. Existing shells need a new shell to load it; do not kill running work to refresh a prompt. The persistent tmux server uses the existing backtick prefix.

The supplied pink-building wallpaper is downloaded privately from wallhaven 1q2p3v. `sensei-palette` coordinates the shell, terminal, prompt and tmux. Artwork is not bundled. Reapplying templates can reset generated colors, so republish the chosen palette afterward.

`sensei-chrome` is the default browser launcher. Native Wayland renders on NVIDIA. Experimental decoder settings are used only while the saved kernel/driver/browser fingerprint matches the actual successful local test; updates automatically fall back to standard rendering until retested. No browser sandbox is disabled. mpv uses the desktop NVDEC path; screen recording first tries NVENC and retains software fallback.

Private stock configuration is preserved at ~/.local/state/pc-rebuild/stock-20261013-075332. A separate copy at ~/.local/share/sensei-stock-recovery/config powers the new “Hyprland · Stock recovery” session; its old blanket root X access command was removed. Xfce is also installed. These alternatives have not yet been exercised through a fresh login. The stock greeter is preserved.

## Workloads and gates

The dedicated ML environment is ~/.local/share/sensei-ml/venv, Python 3.12.15. PyTorch 2.11.0+cu128 exposes sm_75, identifies the GTX 1660 SUPER and passes a GPU matmul against a CPU reference. CUDA toolchain/container success does not establish all future extensions or models work. Keep project dependencies isolated and pin tested versions.

ROS runs natively in Linux containers, with Jazzy and Humble isolated from the host shell. Jazzy and Humble local rclpy/std_msgs publish/subscribe passed in their official desktop images. A bounded Jazzy RViz GUI test reports OpenGL 4.6 and the host NVIDIA process list identifies rviz2 using the GPU. Multi-machine DDS, Gazebo, devices and representative project builds have their own acceptance gates. Do not infer their success from an image pull.

Spotify needs the user's local client/account configuration; Syncthing/Tailscale/KDE Connect need actual peer pairing. Never commit these credentials or device identities. Steam/Gamescope/GameMode/MangoHud installation is preparation, not a gaming benchmark.

Before merging into main: portable installer tests, current desktop acceptance, laptop runtime smoke test and a reviewed pc-to-main merge commit. Never force-push. Before storage conversion: isolated restart/cold boot, exact reconnected disk identities, both SATA OSes independent, checked up-to-date preservation copies and a second physical copy of important HDD-only files. None of those gates can be replaced by dotfile tests.
