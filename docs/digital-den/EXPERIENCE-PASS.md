# Den experience pass / 17 October 2026

Approved request: implement, preserve active work and input recovery. Zondo is the user's deskbuddy, never a representation of fh1m.

| Milestone | Done when | State |
|---|---|---|
| Voice first | USB mic preferred, unmuted, bounded capture measured; per-app routing and explicit pre-meeting checks available | Active: wrong muted default found and corrected |
| Physical Den | Homie global position above/right from laptop centre; editable drag map; directional keyboard handoff follows physical neighbours only when docked | Matching partial-edge builds deployed; 8 crossings and release/resume passed; directional Upper→Homie and return verified |
| Surface polish | Shared header/action spacing, source-labelled camera, correct popup origin, display editor accessible from each brightness button | Deployed on Arete; visual corrections in progress |
| Den / ScreenPad | Dedicated System Den tab; user-selected Normal/Simulation/Coding/Hardware instruments with real context, no forced takeover | Implemented; acceptance details below |
| Network workbench | Read-only route/DNS/link/client inventory; reviewed explicit bounded LAN discovery and diagnostic tool launches; no unattended scanning | Implemented; acceptance details below |
| Developer tools | Local-only Atuin integration preserving arrows, lnav log actions/MIME, nvitop GPU tools on both hosts | Implemented; acceptance details below |
| Speech tools | Distinguish mic-monitor Whisper from STT; local-only opt-in bounded transcription with visible capture; no automatic model downloads or typing into other apps | Implemented; acceptance details below |
| OLED theme | GTK3/4 background black, coherent pink selections/actions, Qt compatibility preserved and visually inspected | Implemented; acceptance details below |
| Zondo | Pet/drag/toss, intentional games/hide-seek, receipts with contextual poses, bounded cross-host courier; quiet/reduced-motion honored | Implemented; acceptance details below |
| Wallpaper story | Original linked pixel-art scenes, awww integration with static/reduced-motion fallback and preserved per-output overrides | Implemented; acceptance details below |
| README | Remove requested workstation/Zondo artwork, correct identity wording, retain genuine desktop screenshots | Implemented; acceptance details below |
| Release | Focused/full tests, actual both-host checks, private backup, clean commits/push; clearly distinguish unperformed physical/voice acceptance | Implemented; acceptance details below |

No physical vehicle controls, password collection, automatic offensive scans or changes to data drives. Mic measurements cannot certify remote call intelligibility without a real listener. Whisper transcription is not noise suppression. Keep recordings private and delete disposable samples. NetworkManager remains connection owner; diagnostics complement it rather than race it. Existing desktop bars remain unchanged except the specifically requested entry points.

## Dependency decisions

Keep connection ownership in NetworkManager and audio ownership in PipeWire/WirePlumber. Use existing system facilities rather than competing background daemons.

| Project | Actual gap | Decision |
|---|---|---|
| Atuin | Search previous shell commands locally | Use local-only; no account, import or sync by default. Keep ordinary arrow keys and existing Alt+R search. |
| lnav | Navigate and correlate logs | Use on demand for explicit log files and user-unit journals. Never claim all plain text as logs. |
| nvitop | Interactive GPU/process inspection | Use on demand; no second always-on GPU collector. |
| whisper.cpp | Offline speech transcription | Use only for explicit bounded transcription; model loaded on demand. It does not enhance microphone audio. |
| mijorus/whisper | Hear microphone return | Defer: existing camera/meeting check already provides explicit microphone monitoring. |
| linux-whisper | Global dictation hotkey and automatic typing | Defer: overlaps the planned bounded transcription action; automatic typing risks entering text into agents or the wrong application. |
| awww | Per-output wallpaper presentation | Use only after single-owner startup/fallback is verified. Installed does not mean the wallpaper migration is complete. |

Acoustic acceptance remains open: two finite test recordings yielded blank transcription. Signal delivery and zero clipping are not proof of intelligibility. Disposable recordings remain private and must be removed after diagnosis.

## Implementation checkpoint

- Existing suite plus new bounded-network tests: 357 passed. With geometry, voice metrics and game rules added: 366 passed (39.199 s) on Arete. Homie validation is pending this checkpoint.
- Installer preview is idempotent after Arete deployment. Main renderer was restarted without restarting native input.
- Known speech fixture transcribed locally: “The robot is ready. Testing the microphone and the speakers.” Temporary audio is removed by the transcription wrapper. Real acoustic tests remain separate.
- Native partial-edge build compiled successfully. Activation requires matching binaries/helpers and a supervised recovery timer on both hosts.
- Physical map, context modes, games, courier and wallpaper ownership code are present; live acceptance is tracked below, not implied by this list.
- Visual inspection caught overlapping ScreenPad controls and an incorrect wallpaper parent binding; both were corrected before release.

## Native story and live checks / 17 October, evening

- Both hosts passed the 366-test suite at f355044. Arete subsequently passed 368 tests including native GIF dimensions, frame count, concurrent rendering and cache reuse. Final exact-revision deployment follows this checkpoint.
- Native input remained separate from UI reloads. Four edge routes passed twice, emergency pause/resume passed, and Super+Right from Upper reached Homie with a verified downward return. One earlier exact-coordinate side-return assertion failed; later bounded reruns passed, so this is not a claim that every future crossing is infallible.
- Atuin, lnav, nmap and on-demand nvitop are installed on both hosts. Whisper.cpp and a checksum-verified base model are available on demand. No online speech service or automatic typing was added.
- Real ScreenPad modes, bounded network diagnostics, camera source labels, games and a separate Den tab are implemented. Actual hardware/voice acceptance is distinct from code coverage.
- Native 4K/ScreenPad GIFs replace independent scene images. Quickshell's wallpaper surface unmaps during awww ownership. The high-CPU QML scene prototype was removed. Homie's lighthouse and away chapter belong to the shared timeline; see STORY.md.
- A malformed focus-beacon QML separator was caught in the live cursor-renderer log and repaired. Native input did not restart; the renderer loaded successfully afterward. Stronger four-corner marks and a top beacon replace default full-screen dimming.
- Acoustic speaker→USB-mic tests still yielded silence/blank transcription despite sample delivery without clipping. A known speech file transcribes correctly; Discord/remote-listener intelligibility is NOT certified. No reboot, physical unplug or unattended boot test is claimed.

Wallpaper release acceptance: 368 tests passed on Arete (41.863 s) and Homie (38.718 s). Five native GIF exports verified; real cross-host sync and single-owner layer checks passed after fixing SSH session environment discovery. Deliberate awww stop→QML fallback→native recovery passed on all four Arete displays. See STORY.md for exact evidence and limits. This closes the native-story delivery, not the still-open physical acoustic/Discord and unattended-boot acceptance.
