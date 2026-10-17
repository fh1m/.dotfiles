# Desktop V4 / execution ledger

Preserve live sessions, input sharing, private content and host GPU policy. One shared main; PC hardware overlays only.

| Milestone | Done when |
|---|---|
| Zondo interaction | User can choose/respond to short prompts, teach custom lines, adjust pacing; no continuous model/API requests; shared repetition memory retained |
| GTK / fonts | Real GTK3/4 styles parsed; native Qt provider retained; common controls styled, application-specific styling boundary documented |
| Session control | Physical short power key opens options; graceful close requests preserve unsaved prompts; remaining apps shown; explicit override available; no shutdown in tests |
| Ethernet | Only connected wired device shows before Bluetooth; measured speed/traffic and detailed network panel; no animation at idle |
| Camera | Button only when available; preview and explicit audio test scoped to open view; stops on close; no recording by default |
| Displays | Connected layout shown; existing graphical arrangement editor integrated with persisted user overrides and rollback; no hardcoded code edits for travel |
| Music | Artwork wash behind large lyric typography; optional queue pane and controls; timed-follow retained |
| Arrival / assets | Fullscreen click-through finite animation, high-resolution generated art, reduced-motion handling; no permanent renderer added |
| Both hosts | Same intended revision/profile deployed, GUI/runtime checked, no input-service interruption, clean Git, documentation and visual README updated |

Named image-enhancer/canvas-design/remotion/font-optimizer/readme-architect skills are unavailable. Built-in imagegen, native QML, fontconfig, official toolkit documentation and existing repo tools are the available implementation path.

## Verified on Arete, 2026-10-17

- Full shell startup succeeds after repairing the missing components import in DenControls. This failure had also removed the shell-owned wallpaper; a real eDP-1 capture confirms its return.
- Listening-room transport, queue, playlists, seek fraction and a real paired Escape passed `scripts/check-music-ui.py --live`. Exit/display controls now remain visible in Focus mode rather than fading during pointer travel.
- Camera preview produced actual frames; closing the panel stopped capture. Audio monitoring is explicit, limited to 15 seconds, and has not been subjectively tested for feedback safety.
- Physical power-key dispatch was tested with a paired virtual key and the login1 inhibitor active. No shutdown/reboot or mass application close was performed.
- Graphical display editor launched and detected all four local displays; no real layout was overwritten for testing. User overrides intentionally supersede automatic Den routing until reset.
- GTK3/GTK4 styles parsed without errors. Electron/custom-rendered applications retain their own theme boundaries.
- Zondo remains Den-wide, with exclusive cross-host travel leases and shared repetition history. Local-only means no online model conversations. Explicit personal memories stay private on the host where saved; ordinary Talk messages are not retained.

## New artwork

Both assets were generated with built-in imagegen and visually inspected. No unavailable image-enhancement tool was claimed or used.

- `den-welcome-v2.png`: actual 1672×941 background illustration; native QML typography remains resolution-independent. Prompt: original nighttime robotics laboratory in Dhaka, underwater robot, sensor board, warm desk lamp, raspberry circuit accents, quiet city window, dark plum/ivory/teal palette, breathing room for live typography, no text/logos/watermark. Requested 4K; tool returned the dimensions above, so this is not represented as native 4K.
- `zondo-climb-v1.png`: 2172×724 transparent four-pose horizontal strip, based on the existing Zondo sprite. Prompt: black-haired chibi engineer, black hoodie and raspberry headphones/sneakers; reach, grip/pull, knee raised, seated dangling legs; invisible ledge, consistent scale, transparent generous padding, no labels/scenery. Used by a lightweight four-frame climbing animation.

Roof placement is curated for the existing building wallpaper, with aspect and window-occlusion checks. Unknown wallpaper uses the established safe placement policy; no continuous screen vision runs.

## Cross-host deployment / remaining boundary

Shared revision `7478a8d` deployed on both hosts. A desktop-shell-only restart was necessary to discover newly added singleton types; native input was not restarted. Both main shells report Configuration Loaded. Homie correctly reports its 1 Gb/s wired link; Arete reports its 100 Mb/s link. The full shared suite passed 308 tests. Arete's live music test passed again after the restart.

Homie's optional `nwg-displays` installation is blocked by sudo rejecting the previously supplied password; the user has been asked to install that package locally. Its existing monitor routing is preserved. Audio-loopback subjective listening, actual shutdown, and physical display unplugging were not performed as destructive/disruptive acceptance tests.
