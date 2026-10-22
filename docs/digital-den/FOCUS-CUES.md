# Focus cues

22 October 2026

The cursor companion renderer no longer paints a full-display pink focus pulse.
It uses a stationary 64×3 logical-pixel top-edge marker, only on the focused
output, with an empty input region and no keyboard focus/exclusive zone. Native
active-window borders are two pixels in muted rose; inactive borders remain
neutral. Final custom Hyprland overrides enforce this after generated theme
settings. Applied and queried on Arete and Homie without restarting input sharing.
The legacy `sensei-den companion pulse on/off` command now toggles the stationary
marker; it cannot restore the removed screen flash. Cursor locate-on-demand rings
are separate and unchanged. Live backups: ~/.local/state/den/focus-before-2026-10-22/.
