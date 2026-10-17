# Experience pass: sources and decisions

17 October 2026. Official projects and installed help were inspected; these are integration decisions, not claims that a mascot treats loneliness.

| Source | Finding applied |
|---|---|
| [WirePlumber priorities](https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/priorities.html) | A remembered user default outranks session priority. Preserve explicit selection; prefer the identified USB microphone without repeatedly overriding users. |
| [Discord troubleshooting](https://support.discord.com/hc/en-us/articles/360045138471-Discord-Voice-and-Video-Troubleshooting-Guide) | Input mode, device selection, permissions and application mute are independent of OS audio routing. A PipeWire sample is not remote-call acceptance. |
| [mijorus Whisper](https://github.com/mijorus/whisper) | Microphone return, not transcription or denoising. Existing explicit monitor UI fills this role; avoid another app and low-quantum tuning. |
| [whisper.cpp](https://github.com/ggml-org/whisper.cpp) | Local, on-demand transcription. Pin a CPU build and checked multilingual base model; never type model output into another program automatically. |
| [linux-whisper](https://github.com/arniesaha/linux-whisper) | Hotkey dictation is useful, but automatic typing overlaps the existing agent-sensitive workflow. Defer the wrapper, retain explicit transcript preview. |
| [Atuin configuration](https://docs.atuin.sh/configuration/config/) | Local history search can be used without sync. Preserve arrows, exclude space-prefixed commands and keep secret filtering; filtering is not a guarantee that all sensitive commands are detected. |
| [lnav usage](https://docs.lnav.org/en/latest/usage.html) | Native log parsing and journal JSON navigation remove a need for a bespoke log viewer. Invoke on demand. |
| [nvitop](https://nvitop.readthedocs.io/en/stable/) | GPU/process inspection belongs in an interactive tool. No duplicate polling daemon. |
| [awww](https://codeberg.org/LGFae/awww), installed CLI help | Per-output images, nearest-neighbour pixel-art scaling and finite fade transitions. Keep a single wallpaper owner and recover to existing QML images if services fail. Website access failed during this pass; installed help was used rather than inventing an API. |
| [Qt DragHandler](https://doc.qt.io/qt-6/qml-qtquick-draghandler.html) | Bounded local interaction can reuse the existing character surface; no global pointer grab or new character framework. |

Original scene assets were generated with imagegen for this pass, then visually inspected. Four landscape PNGs are approximately 1672×940/941; ScreenPad is 2144×733. They are pixel art, not claimed to be native 4K images. Animation uses finite awww transitions and three tiny QML beacon fades, disabled under reduced motion. The four-role sprite atlas is 1254×1254 with explicit cell boundaries. These assets depict Zondo as a deskbuddy, not the user's identity.
