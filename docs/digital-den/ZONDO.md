# Zondo / a quieter kind of desk company

Zondo is fh1m’s local desktop character. No microphone, window-title logging, key capture or cloud model is involved.

## This pass

- Keep the existing renderer and cross-host leases. Add an original sixteen-pose illustrated atlas: dance sequence, reading, mug, stretch, stargazing, juggling, robot, paper plane, sketchbook, binoculars, plant, guitar and sleep.
- Rotate activities independently from speech. Music state comes from Spotify MPRIS; the existing authenticated lease carries a fresh boolean across hosts so he can dance on Homie to music playing on Arete (and vice versa). It expires with the lease; no catalogue requests. Paused music returns to ordinary activities.
- Explore 35 candidate positions on exposed wallpaper. Never draw over app windows; the bar perch remains the fallback. A clear bounding corridor permits walking or paper-plane travel in two dimensions; a blocked corridor uses departure/reappearance instead of flying over code.
- Persist only the last 40 line IDs and sequence position locally. New sessions do not restart the same jokes. This is repetition memory, not a claim that Zondo understands the user. Content remains inspectable in `notes.json`.
- Personal callbacks cite the public [about page](https://fh1m.github.io/about/), read on 17 October 2026. RocketPy, rover keyboard alignment, TVC and Mongla e-stop references come from that page. No invented recollections.
- Desk checks use real RAM, home-volume space and uptime. Thermal warnings identify a sensor, not a claimed CPU/GPU reading. Warning cooldown: 30 minutes. No fake emergency or emotional inference.
- A five-second, click-through welcome card on session/presence changes. No bootloader, initramfs, display manager or input grab changes. This is a graphical-session welcome, not a firmware boot splash.
- Terminal opacity .96, GTK3/4 dark controls and raspberry accent, consistent Qt UI font and cursor settings. App-specific custom rendering can override desktop styling.

## Controls and preferences

`sensei-den companion dance`, `read`, `sip`, `stretch`, `stargaze`, `juggle`, `robot`, `plane`, `sketch`, `explore`, `garden`, `guitar`, `sleep`, `wave`, `tip`, `tour`.

`more` favors the current line’s category; `less` retires that exact line. The System → Den controls expose both. Line indexes are append-only: keep existing `notes.json` entries in order when adding material.

Existing `quiet on`, `chatter off`, `motion off`, `roam off` and `hide` remain available. Preferences: `~/.config/sensei-den/companion.json`; set `activitySeconds` (15–120) and `chatterSeconds` (45–600) for pacing, `welcome:false` to suppress arrival cards or `hiddenNotes:[id,...]` to exclude lines. Local repetition state: `~/.local/state/sensei-den/zondo-memory.json`; deleting it resets repetition memory, not content. No study notes or AI credentials are read.

## Research and boundaries

- [GTK3 CSS](https://docs.gtk.org/gtk3/css-overview.html) and [GTK4 CSS provider](https://docs.gtk.org/gtk4/class.CssProvider.html): use native supported CSS; do not transplant GTK3 CSS into GTK4 or force GTK_THEME globally.
- [GTK settings](https://docs.gtk.org/gtk4/class.Settings.html): persist theme/cursor defaults in the existing settings files.
- [Shijima-Qt](https://github.com/pixelomer/Shijima-Qt) provides a mature external pet runner; its extra runtime and desktop-specific window integration do not solve our exclusive cross-host routing, so the existing small QML renderer is retained.
- [GNOME UI styling](https://developer.gnome.org/hig/guidelines/ui-styling.html) recommends existing classes/color variables: keep native controls and semantics.
- [Lan Mouse](https://github.com/feschber/lan-mouse) documents layer-shell capture and wlroots emulation separately. Our character never owns either.
- [Exploring interactions with companion virtual agents](https://rodrigo-calvo.com/assets/papers/companions.pdf): seven-day exploratory study of 24 analyzed participants; repetitive responses and memory inconsistencies were reported, with no significant loneliness reduction. This is not proof that an animated character improves wellbeing. Variety, user control and unobtrusive behavior here are design choices to test, not clinical claims.
- Existing Den input ownership is separate from character rendering. Automatic locator rings at every host crossing are removed; explicit Ctrl locator and emergency recovery stay intact.

## Assets

Built-in imagegen produced `zondo-life-v2.png` (transparent 4×4 atlas) and `den-welcome-v1.png` (arrival-card scene). Both live in `home/.local/share/sensei-companion/`. The prompts specified the existing black-haired engineer identity, raspberry headphones, sixteen distinct actions, and a quiet robotics workshop. They are original illustrations, not screenshots.

## Verification ledger

- Original atlas and workshop scene inspected; the arrival card and live paper-plane pose were captured and inspected on Arete. The second imagegen atlas and measured transparent-gutter rectangles fix the tight edges found in the first real crop; the padded reading pose was re-captured and inspected.
- GTK3/GTK4 CSS loaded with zero parser errors. Installer preview reported no remaining changes after application.
- 302 shared tests passed, including 15 companion checks and 17 continuity checks. Native input unit suite: 5 passed.
- 12 live round trips covered top→bottom, right→left, top→left and right→bottom at multiple edge positions, plus triple-Ctrl pause/resume. Sharing restored afterward. Cursor asset hashes match.
- Real Spotify Playing state reached Zondo. The previous paused state was restored. Both hosts received the initial Zondo deployment with no input-service restart.
- Neovim smoke, including actual Ruff formatting and LSP hover, passed on Arete, Homie and auv-ros2. The container emitted its existing first-password warning before the smoke succeeded; this pass did not set a container password.
- Cold boot, physical unplug and subjective long-session cursor smoothness are not claimed as completed hardware tests.

## Qt compatibility repair

Arete’s rolling repository supplied a Qt6.12-built qt6ct while the installed Qt is 6.11.2. A real Qt6 QApplication probe fell back to light colors; configuring files alone was insufficient. The installed qt5ct/qt6ct packages provide normal tooling, and `scripts/build-qt-theme.py` builds pinned upstream qt6ct 0.11 (`00823e4`) against the installed Qt into `~/.local/opt/sensei-qt6ct`. No system Qt was upgraded or replaced. The plugin retains upstream’s minor-version compatibility guard.

Both Qt5 and Qt6 offscreen QApplication probes now report the same actual dark window, pink highlight and 11pt JetBrains Mono Propo font. `QT_QPA_PLATFORMTHEME=qt5ct` is supported by both providers; the private Qt6 plugin path is shared through Hyprland and environment.d. New apps inherit it immediately through Hyprland/DBus; already-running applications may retain their cached palette until reopened.

After a Qt minor-version update, rerun `python3 ~/.dotfiles/scripts/build-qt-theme.py` on that host. It preserves the previous private provider and never writes system libraries. Keep existing upstream notices; it uses the official [qt6ct source](https://www.opencode.net/trialuser/qt6ct), not a replacement widget engine. To undo, revert the appearance environment/config files from the installer backup and reopen affected apps. No reboot is required for the theme itself.
