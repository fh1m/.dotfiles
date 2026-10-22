# Focus cues

22 October 2026

The cursor companion renderer no longer paints a full-display pink focus pulse.
It uses a warm-ivory (#e6d7bb), brief 180×4 logical-pixel top-edge marker, only on the focused
output, with an empty input region and no keyboard focus/exclusive zone. It appears on
window/display focus changes, eases in for 110 ms, holds for 420 ms and fades
out over 650 ms; reduced-motion mode uses a short static cue. Native
active-window borders are two pixels in muted rose; inactive borders remain
neutral. Final custom Hyprland overrides enforce this after generated theme
settings. Applied and queried on Arete and Homie without restarting input sharing.
The legacy `sensei-den companion pulse on/off` command now toggles the brief
marker; it cannot restore the removed screen flash. Cursor locate-on-demand rings
are separate and unchanged. Live backups: ~/.local/state/den/focus-before-2026-10-22/.
