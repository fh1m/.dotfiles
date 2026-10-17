# The Field Trip

One little question leaves the desk. A parcel reaches Homie's lighthouse; an AUV takes a survey; the fish conduct a questionable peer review; a lantern returns to the sky. No research claim is inferred from this decorative story. Actual jobs use Zondo's separate verified courier receipts.

The references are personal: fh1m's underwater-robotics work, Mongla, careful baselines, a warm workshop, plants and an observatory for the questions below the questions. Zondo is the deskbuddy, not an illustration of fh1m. No baked-in character duplicates him.

## One world, five windows

Coordinates are logical desktop coordinates. Every export uses the same scene and 16-second timeline:

| Window | World origin | Current native export |
|---|---|---|
| Upper / observatory | −1920, −1080 | 1920×1080 |
| Homie / compute lighthouse | 960, −1080 | 1920×1080 |
| Lower / Mongla dock | −1920, 0 | 1920×1080 |
| Main / rooftop field lab | 0, 0 | 3840×2160 |
| ScreenPad / sensor garden | 0, 1080 | 3840×1100 |

A continuous bridge, horizon and pink cable cross these windows. The scene is intentionally sparse: slate/teal dusk with warm amber architecture rather than a black void or five busy illustrations. On Homie, the away variant marks Arete's travelling piece: “Out collecting questions.” Presence changes select it automatically. Local compositor geometry remains separate from the physical two-host map.

## Sharpness and playback

The first small full-world raster was rejected: a crop of a 1672-pixel image is not a native 4K wallpaper. The live scene instead combines resolution-independent SVG geometry with four original 1536×1024 imagegen architectural cutouts, placed below their source pixel density. Original animated actors are clipped from their transparent sheet. FFmpeg composes video into native-sized, delta-optimized GIFs; it does not enlarge the rejected panorama.

`awww` owns playback. Quickshell's wallpaper surface is unmapped while native playback is ready. There is no live Python painter, browser, shader or QML scene loop. The high-CPU prototype was removed, not retained as an optional hidden renderer. Rendering uses one filter thread, low CPU/I/O priority, a per-render lock and atomic completion. A one-frame palette avoids buffering a full 4K animation in memory.

The verified 4K export has 128 frames at 8 fps, 16.01 seconds including GIF timing quantization, approximately 516 KiB for the first inspected render. Cache processing is a one-time cost; the measured single-output daemon playback used about 1.3% of one CPU and 66 MiB RSS. These are observations, not budgets guaranteed on every GPU.

Reduced motion/quiet selects the native still. Missing or failed backends restore the existing QML wallpaper choices. Custom per-output overrides remain private. Render caches are disposable and excluded from content backups; keep the source and generated art in Git.

## Controls

```sh
sensei-wallpaper-story enable
sensei-wallpaper-story status
sensei-wallpaper-story sync       # Arete coordinates an already-warmed Homie
sensei-wallpaper-story disable    # restores original wallpaper choices
```

Initial renders are cached in `~/.cache/sensei-den-story/`. The reusable renderer is `sensei-story-render --role main --width 3840 --height 2160`. Export dimensions follow actual monitor pixels, not the logical size returned by awww query. Upstream source confirms awww multiplies logical dimensions by the output scale before allocating its canvas.

Sync warms caches and dispatches at a shared future boundary. Different refresh rates and independent host scheduling mean this is coordinated playback, not a promise of frame-perfect genlock. Do not start several sync/apply operations simultaneously.

## Zondo's scene contract

`world-v3.json` records named world-coordinate perches. `worldPlace` projects them through exactly the same viewport as the wallpaper. Perches include the telescope terrace, workshop roof, dock platform, underwater sensors and Homie's beacon balcony. Occupied-window checks take precedence: he must not land over code or controls. Motion, quiet, fullscreen safety and the exclusive cross-host lease remain independent of the wallpaper player.

When changing art, update the perches and inspect each view at native resolution. Add an actor by extending the fixed shared timeline, not by starting a new per-monitor animation with unrelated timing. Keep architectural cutouts below their source pixel dimensions. A replacement high-resolution screenshot is not evidence that a motion path or a physical call passed.

## Provenance and research

Built-in imagegen generated the transparent observatory, lighthouse, rooftop and dock cutouts and the drone/AUV/fish/lantern atlas on 17 October 2026. Originals remain in Codex's image library; maintained copies live under `home/.local/share/sensei-den/story/`. Prompts specified restrained slate/teal/amber/hot-pink pixel art, one complete isolated building per asset, generous transparency, walkable ledges, no humanoids, no text and no busy scenery. The rooftop and dock explicitly requested an AUV, small tools and references to underwater robotics/Mongla.

[awww upstream](https://codeberg.org/LGFae/awww), its installed 0.12.1 help, upstream image manual and `wallpaper.rs::get_dimensions` were inspected. [Cache documentation](https://man.archlinux.org/man/extra/awww/awww-clear-cache.1.en) explains preprocessing and versioned animation caches. The author's [memory discussion](https://www.lgfae.com/posts/2025-11-21-SettingAWallpaperWithLessThan250KB.html) concerns static wallpapers; we do not apply its static-memory claim to these animations.

## Deployment acceptance / 17 October 2026

Arete and Homie both passed 368 repository tests. All five live exports were inspected with ffprobe: native dimensions above, 128 frames, 16.01 seconds. Decoded frame hashes confirmed actual changing frames on Main, ScreenPad, Lower and Upper; Homie's GIF contains the shared courier sequence. Both clocks report NTP synchronization. Cross-host prepare/apply completed with the same recorded epoch (1792240154.44); dispatch completion differed by approximately 106 ms in that check, so phase-lock is not claimed.

A controlled awww stop on Arete restored visible QML wallpaper surfaces on all four displays; restart recovered native playback. Layer inspection then confirmed one native wallpaper owner on Homie as well. SSH-specific graphical-session discovery was repaired and exercised through the real sync command. Input/cursor/watch services stayed active; no user application was closed. Initial-cache work is finite and separate from idle playback.

The away variant was rendered and visually inspected locally without pretending the laptop had physically left. A future real undock remains a useful physical acceptance test. No live mouse-latency improvement is inferred from wallpaper performance measurements alone.
