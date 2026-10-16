# Zondo / a quieter kind of desk company

Zondo is fh1m’s local desktop character. He is not a person, a therapist, or a watcher of private conversations. No microphone, window-title logging, key capture or cloud model is involved.

## This pass

- Keep the existing renderer and cross-host leases. Add an original sixteen-pose illustrated atlas: dance sequence, reading, mug, stretch, stargazing, juggling, robot, paper plane, sketchbook, binoculars, plant, guitar and sleep.
- Rotate activities independently from speech. Music state comes from Spotify MPRIS; no catalogue requests. Paused music returns to ordinary activities.
- Explore 35 candidate positions on exposed wallpaper. Never draw over app windows; the bar perch remains the fallback. Relocation across occupied space is a departure/reappearance, not a flight over code.
- Persist only the last 40 line IDs and sequence position locally. New sessions do not restart the same jokes. This is repetition memory, not a claim that Zondo understands the user. Content remains inspectable in `notes.json`.
- Personal callbacks cite the public [about page](https://fh1m.github.io/about/), read on 17 October 2026. RocketPy, rover keyboard alignment, TVC and Mongla e-stop references come from that page. No invented recollections.
- Desk checks use real RAM, home-volume space and uptime. Thermal warnings identify a sensor, not a claimed CPU/GPU reading. Warning cooldown: 30 minutes. No fake emergency or emotional inference.
- A five-second, click-through welcome card on session/presence changes. No bootloader, initramfs, display manager or input grab changes. This is a graphical-session welcome, not a firmware boot splash.
- Terminal opacity .96, GTK3/4 dark controls and raspberry accent, consistent Qt UI font and cursor settings. App-specific custom rendering can override desktop styling.

## Controls and preferences

`sensei-den companion dance`, `read`, `sip`, `stretch`, `stargaze`, `juggle`, `robot`, `plane`, `sketch`, `explore`, `garden`, `guitar`, `sleep`, `wave`, `tip`, `tour`.

`more` favors the current line’s category; `less` retires that exact line. The System → Den controls expose both. Line indexes are append-only: keep existing `notes.json` entries in order when adding material.

Existing `quiet on`, `chatter off`, `motion off`, `roam off` and `hide` remain available. Preferences: `~/.config/sensei-den/companion.json`; set `welcome:false` to suppress arrival cards or `hiddenNotes:[id,...]` to exclude lines. Local repetition state: `~/.local/state/sensei-den/zondo-memory.json`; deleting it resets repetition memory, not content. No study notes or AI credentials are read.

## Research and boundaries

- [GTK3 CSS](https://docs.gtk.org/gtk3/css-overview.html) and [GTK4 CSS provider](https://docs.gtk.org/gtk4/class.CssProvider.html): use native supported CSS; do not transplant GTK3 CSS into GTK4 or force GTK_THEME globally.
- [GTK settings](https://docs.gtk.org/gtk4/class.Settings.html): persist theme/cursor defaults in the existing settings files.
- [Exploring interactions with companion virtual agents](https://rodrigo-calvo.com/assets/papers/companions.pdf): exploratory evidence, not proof that an animated character improves wellbeing. Variety, user control and unobtrusive behavior here are design choices to test, not clinical claims.
- Existing Den input ownership is separate from character rendering. Automatic locator rings at every host crossing are removed; explicit Ctrl locator and emergency recovery stay intact.

## Assets

Built-in imagegen produced `zondo-life-v1.png` (transparent 4×4 atlas) and `den-welcome-v1.png` (arrival-card scene). Both live in `home/.local/share/sensei-companion/`. The prompts specified the existing black-haired engineer identity, raspberry headphones, sixteen distinct actions, and a quiet robotics workshop. They are original illustrations, not screenshots.

## Verification ledger

Pending: generated atlas inspection, QML runtime load, varied activities, real music-state change, both-host deployment, cursor/theme equality, tests and visual inspection. Cold boot and physical unplug are not claimed without performing them.
