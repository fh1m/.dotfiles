# Pen and presence / execution ledger

Approved 17 October 2026. Restore the earlier private rooftop/VHS wallpapers and animate a connected engineering sequence. Replace persistent focus corners/dimming with a short destination-display pulse. Repair Zondo's texture loading, speech placement and cross-host scheduling. Integrate the connected XP-Pen Star G960S Plus with Upper and both native scratch and Obsidian drawing flows. Preserve bars and input recovery.

| Stage | Acceptance | State |
|---|---|---|
| Recovery | Existing private wallpaper/companion choices backed up | Saved under local den-experience-backups/pen-pass |
| Tablet | Pressure-capable headless driver, Upper mapping, widget profiles and test surface | In progress |
| Capture | Instant native scratch and learning-linked Obsidian drawing | Pending |
| Presence | Brief destination pulse; no persistent dim; no input interception | Pending |
| Zondo | Stable sprites and speech, lively context, safe cross-host travel | Pending |
| Wallpaper | Original art retained; native full-colour animation, linked five-display story | Pending |
| ScreenPad | Every mode fits and real actions work, including Drawing | Pending |
| Release | Both-host tests, source/installed match, rollback docs and normal push | Pending |

Physical handwriting, tilt/eraser feel and call intelligibility cannot be certified by synthetic input. Keep those separate from automated evidence. No disk/firmware or private account changes.

## Research carried into implementation

36 targeted searches in the planning turn; unrelated results were discarded. Primary code was inspected for OpenTabletDriver's G960S Plus configuration, pen report parser, Artist Mode, console JSON/settings operations; awww's APNG decoder; Qt Image reload semantics; installed Hyprland Lua device configuration. Practitioner reports informed tradeoffs, not proof of device behavior.

- https://github.com/OpenTabletDriver/OpenTabletDriver — headless Artist Mode, pressure/tilt/eraser parser, CLI JSON/preset APIs. Current CachyOS package is 0.6.7-2.
- https://opentabletdriver.net/Wiki/FAQ/Linux — Artist Mode bindings and pressure; do not run competing drivers.
- https://opentabletdriver.net/Wiki/FAQ/General — monitor-layout changes can require daemon refresh; keep mapping ownership explicit.
- https://www.xp-pen.com/product/star-g960s-star-g960s-plus.html — model features, 9×6 inch area, 8192 pressure levels, tilt, eraser and four keys. USB 28bd:0918 matches upstream device configuration.
- https://wiki.hypr.land/0.55.0/Configuring/Advanced-and-Cool/Devices/ — bind Tablet (not Tool/Pad) to output through hl.device.
- https://doc.qt.io/qt-6/qml-qtquick-image.html — changing sourceClipRect reloads the source; asynchronous loading without retention can blank frames.
- https://doc.qt.io/qt-6/qml-qtquick-animatedsprite.html — preloaded fixed-size frames and time-based sprite playback.
- https://codeberg.org/LGFae/awww — inspected source supports APNG/GIF/WebP animation. Full-colour APNG avoids GIF palette loss; 25 fps gives integer 40 ms delays.
- https://github.com/LGFae/swww/issues/246 — historical occluded-output callback stalls; reproduce current runtime before assigning blame.
- https://xournalpp.github.io/guide/whirlwind-tour/ — correct stylus classification and temporary tools.
- https://docs.krita.org/en/reference_manual/preferences/tablet_settings.html — raw tablet tester distinguishes pressure-capable pen events from mouse events.
- https://github.com/zsviczian/obsidian-excalidraw-plugin — editable diagrams, SVG export and linked notes. Existing plugin is already enabled in Workbench.
- https://github.com/zsviczian/obsidian-excalidraw-plugin/issues/2773 — handwriting ergonomics and limitations; retain a native scratch option.
- https://www.reddit.com/r/ObsidianMD/comments/1k9yhsy/ — individual reports support separating native handwriting from durable linked notes; not a consensus claim.

Defaults: both writing flows, with native scratch for global capture and Excalidraw inside Noesis. Tablet keys undo/redo/eraser/pan. Zondo remains local-only, lively but quiet/fullscreen policies prevail. No vendor GUI dependency, automatic online OCR or global key injection into unrelated apps.

### Full-area and visible-tools correction

The ScreenPad instrument now spans its available width above the bar. System navigation uses three roomy columns with semantic glyphs and the shared UI font. Scratchpad launches keep the normal toolbar visible; `sensei-draw focus` or F11 explicitly toggles the clean writing view. The active scratch was returned to normal mode without closing it or discarding unsaved ink. The virtual pen has an explicit full-output region, cleared secondary active-area crop and neutral compositor rotation; the physical aspect crop remains owned by OTD. Physical edge reach needs a real pen check after this correction.

### 18 October: speech, bar ownership and paper-only input

Speech uses a separately testable `SpeechLayout.js`: a tight content-height card, clear space around the pet, no covering app windows. Routine geometry refreshes retain a safe existing perch; speech no longer forces a relocation. Atlas loading retains the old image while loading. A genuine generated six-frame gentle wave/dance atlas adds a slower 140ms loop and click greetings vary without online conversations. Quiet, DND, reduced motion and fullscreen policies remain authoritative. The private chatter setting is 45 seconds on Arete.

Bar buttons use their actual `QsWindow.window.screen` for opening and toggling. Anchor coordinates are stored by output as well as action, so an external bar cannot overwrite the main bar's anchor. Official reference: https://quickshell.org/docs/v0.3.2/types/Quickshell/QsWindow/ .

The scratch mapper reads only the owned Xournal scratch window's accessible viewport and zoom, then recognizes the white sheet inside that viewport from an ephemeral screenshot. It discards screenshot bytes, keeps an eight-pixel paper inset, and maps both OTD aspect and compositor region to that paper. It recalculates on viewport/zoom changes, not every pen sample. Outside the owned scratch it falls back to the chosen output. Missing accessibility or unrecognized paper uses the output fallback; this is not proof of physical edge reach. The tablet was disconnected during the software validation.

OLED overrides cover GTK3/4 structural surfaces, headerbars, path bars, sidebars, cards and popovers, preserving document paper and content. Already-running GTK apps may retain their loaded style until next launch; do not kill a file manager with possible active operations to force a cosmetic reload.

Validation: 374 repository tests passed on Arete (18 October). Live popup IPC confirmed System visible on Upper and absent on Main for an explicit Upper open. A separate owned Nautilus process showed black structural surfaces; it was closed afterward. The user's existing Nautilus and unsaved Xournal windows were preserved. Cursor input was not restarted. Physical pen mapping remains pending reconnection and stroke testing. The rooftop animation compiler is available but was not enabled as part of these UI repairs; saved original wallpapers remain visible.

Additional live check: the existing unsaved Xournal scratch viewport was detected and the white paper recognized as an 824 × 574 logical-pixel region within Upper, excluding its toolbar/sidebar and grey margins. The test restored the previous focused window. This verifies geometry extraction, not physical pen strokes. GTK accessibility and document portal services were restored and active after the isolated Nautilus style test.
