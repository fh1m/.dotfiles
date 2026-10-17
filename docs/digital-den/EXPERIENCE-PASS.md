# Den experience pass / 17 October 2026

Approved request: implement, preserve active work and input recovery. Zondo is the user's deskbuddy, never a representation of fh1m.

| Milestone | Done when | State |
|---|---|---|
| Voice first | USB mic preferred, unmuted, bounded capture measured; per-app routing and explicit pre-meeting checks available | Active: wrong muted default found and corrected |
| Physical Den | Homie global position above/right from laptop centre; editable drag map; directional keyboard handoff follows physical neighbours only when docked | Implemented; native partial-edge build compiled, live rollout pending |
| Surface polish | Shared header/action spacing, source-labelled camera, correct popup origin, display editor accessible from each brightness button | Deployed on Arete; visual corrections in progress |
| Den / ScreenPad | Dedicated System Den tab; user-selected Normal/Simulation/Coding/Hardware instruments with real context, no forced takeover | Pending |
| Network workbench | Read-only route/DNS/link/client inventory; reviewed explicit bounded LAN discovery and diagnostic tool launches; no unattended scanning | Pending |
| Developer tools | Local-only Atuin integration preserving arrows, lnav log actions/MIME, nvitop GPU tools on both hosts | Pending |
| Speech tools | Distinguish mic-monitor Whisper from STT; local-only opt-in bounded transcription with visible capture; no automatic model downloads or typing into other apps | Pending |
| OLED theme | GTK3/4 background black, coherent pink selections/actions, Qt compatibility preserved and visually inspected | Pending |
| Zondo | Pet/drag/toss, intentional games/hide-seek, receipts with contextual poses, bounded cross-host courier; quiet/reduced-motion honored | Pending |
| Wallpaper story | Original linked pixel-art scenes, awww integration with static/reduced-motion fallback and preserved per-output overrides | Pending |
| README | Remove requested workstation/Zondo artwork, correct identity wording, retain genuine desktop screenshots | Pending |
| Release | Focused/full tests, actual both-host checks, private backup, clean commits/push; clearly distinguish unperformed physical/voice acceptance | Pending |

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
