# Credits and provenance

The shell began with **[Wrayth](https://github.com/bowenbride/wrayth)** by **bowenbride**, a Quickshell desktop for Hyprland. Its GPL-3.0 license, source notices, design document and Chakra Petch OFL notices are retained. This repository is fh1m’s adapted robotics workstation, not a claim to have authored Wrayth from scratch.

| Project | Role | License / attribution |
|---|---|---|
| Wrayth | Starting shell, deck, visual language, helpers, lockscreen | GPL-3.0; `home/.config/quickshell/wrayth/LICENSE` |
| Hyprland | Compositor, Lua bindings, window and workspace control | Upstream BSD license; dependency |
| Quickshell | QML surfaces, D-Bus integrations, capture and IPC | Upstream LGPL/GPL licensing; dependency |
| spotify-player / aome510 | Patched native Spotify Connect player | MIT; `vendor/spotify-player/LICENSE` |
| librespot | Native Spotify streaming underneath the player | Included dependency licenses; see Cargo.lock |
| Plippo/asus-wmi-screenpad | UX581 ScreenPad brightness support | External driver; install from its own upstream |
| KDE Connect, Tailscale, Termux, Syncthing | Phone control, private transport, commands and sync | External dependencies; each project retains its own license |
| PipeWire, WirePlumber, BlueZ | Audio graph, policy and Bluetooth | External dependencies |
| Chakra Petch | Bundled accent font | OFL; bundled `OFL.txt` |
| Zed Mono, Iosevka / Nerd Fonts | Text and glyphs | Installed separately; retain upstream font licenses |

Desktop screenshots show fh1m’s actual setup. Wallpaper references: [main](https://wallhaven.cc/w/w5q8px), [ScreenPad](https://wallhaven.cc/w/6lqvql). Original artwork belongs to its creators; the original wallpaper files are not redistributed here. Bundled Wrayth-generated wallpapers retain their original provenance.

The custom setup, experiments and documentation were developed by fh1m with coding assistance. Hardware findings are observations on one laptop, not upstream promises. Original source notices are retained rather than replaced.
