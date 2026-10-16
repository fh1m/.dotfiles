# Daily controls

[← Workstation](../README.md)

Use **Ctrl+Shift+?** or **Super+F2** for the searchable Quickshell shortcut guide. Type an action, key, or category; fuzzy matches appear immediately. Arrow keys choose a row, Enter copies its shortcut, Esc closes it. The effective Lua configuration is the source of truth if a binding changes.

The terminal's internal tab, pane, copy and session shortcuts are in [Terminal →](terminal.md).

| Key | Action |
|---|---|
| Tap Super | Native-icon application launcher on the focused display |
| Super+1…7 | Terminal / Web / Code / Study / Sim / Work / Misc |
| Super+Shift+1…7 | Move focused window to the chosen workspace |
| Alt+Tab / Shift+Alt+Tab | Window switcher forwards/backwards |
| Super+Tab / Shift+Super+Tab | Workspace switcher |
| Super+A | Workspace overview; drag windows between tiles |
| Alt+grave / Shift+Alt+grave | Instances of current application |
| Enter / click | Choose; modifier release keeps the view open |
| Escape | Cancel / back |
| Super+Return, Super+Q, Alt+Return | Focus existing terminal or launch |
| Alt+W | Focus existing Chrome or launch |
| Alt+F | Focus existing file manager or launch |
| Shift + application launch key | Force a new window where supported |
| Super+C | Close focused window |
| Super+V / Super+F | Float/tile / fullscreen |
| Super+arrows | Directional focus |
| Super+mouse drag / right-drag | Move / resize window |
| Super+Shift+Up/Down | Move to main / ScreenPad monitor |
| Super+W | Theme / wallpaper picker |
| Super+Alt+G | Toggle native tab group for the focused window |
| Super+Alt+H/L | Move focused window into an existing group left/right |
| Super+Alt+J/K | Next/previous tab in the group |
| Super+Alt+U | Remove focused window from its group |
| Drag onto group title | Add another window to that tab group |
| Super+Shift+V | Persistent clipboard |
| Super+Shift+M | System Monitor |
| Super+E | sensei deck (Super+Shift+E restarts its terminal) |
| Super+L | Manual lock |
| Super+Ctrl+P | Power menu |
| Ctrl+Space | Spotify play/pause |
| Ctrl+Left/Right | Previous/next Spotify track |
| Ctrl+Up/Down | Spotify volume up/down |
| Print | Area screenshot, saved and copied |
| Shift+Print | Output screenshot |
| Alt+Print | Active window screenshot |
| Ctrl+Print | Whole desktop screenshot |
| Super+Print | Output recording toggle |
| Super+Shift+Print | Area recording toggle |
| Super+Shift+D | Area OCR to clipboard (requires tesseract) |
| Super+Space | Launcher (the same as tapping Super) |
| Super+P | Calculator (the power menu is Super+Ctrl+P) |
| Super+J | Toggle split layout |
| Super+Y | Pin the focused window |
| Super+G / Super+Shift+G | Remove / restore window gaps |
| Super+Ctrl+Left/Right | Focus the left / right monitor |
| Super+Ctrl+Shift+Left/Right | Move the focused window to the left / right monitor |
| Alt+Shift+G | Resume the native tab group |
| Super+Shift+Space | Workbench scratch window |
| Super+Alt+P | Workbench lab capture |
| Super+Ctrl+D | Toggle quiet mode |
| Super+Shift+] / Super+Shift+[ | ScreenPad brightness up / down, 10% steps |

Screenshots go to `~/Pictures/Screenshots`, recordings to `~/Videos/Screencasts`. Clipboard history is local/private, not part of Git. Review global Ctrl+arrow choices if they conflict with your editor’s word-navigation preferences.

## ZenBook function layer

Dedicated ASUS fan, swap and ScreenPad buttons use model-specific events. Standard brightness/volume/media/microphone/touchpad keys are mapped where available.

| Key | Reference action |
|---|---|
| Super+F3 | System quick controls |
| Super+F4 | Microphone mute |
| Super+F5 | Power mode |
| Super+F6 | Touchpad |
| Super+F7 | Keyboard illumination |
| Super+F8 | Display swap |
| Super+F9 | Keep-awake override |
| Super+F10 | Camera control |
| Super+F11 | Output recording |
| Super+F12 | Robotics controls |

Plain F1–F12 remain available to applications. Capture your own device’s special-key events before copying the UX581 map.

The pointer focuses the window it enters; no click is needed. ScreenPad Utility is separate from the seven subjects. The workspace rail shows the local count, active subject and urgency, with a neutral enclosure.
