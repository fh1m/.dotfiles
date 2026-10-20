# Meeting audio: investigation and tools

Controllers and Homie physical testing are deferred by the owner. Work on Arete first.

## Verified locally

- Dedicated YC1006 USB mic is the default, 48 kHz mono and unmuted.
- Vesktop initially held simultaneous streams on built-in, GeneralPlus and YC1006 inputs. Explicit stream routing corrected that inconsistency but the listener still reported low volume.
- Owner reports local Vesktop Mic Test is clear while the remote listener hears quiet audio. This does not prove the sender or receiver is at fault.
- Raw sample: peak −28.5 dBFS / RMS −30.2 dBFS. Simultaneous Den Voice sample: peak −22.5 / RMS −24.2 dBFS. Neither clipped. Signal-only measurement, no audio retained; speech intelligibility was not assessed by those numbers.
- EasyEffects 8.3.0 loaded compressor and limiter; Vesktop capture was linked to easyeffects_source. System default stayed the physical mic. No audio-service restart.
- whisper.cpp local bundled JFK sample transcribed correctly in about 2.97 seconds with two CPU threads. This is a functional test, not a live conversation benchmark.
- Live call volume is **unresolved**. Await local WebRTC stats, without audio recordings. No private diagnostics belong in this public repository.

## Decisions

Whisper.cpp is already the implementation behind `sensei-voice transcribe`. It performs local speech recognition, not denoising or gain correction. No continuous transcription of a private call.

Initial +6 dB A/B processing amplified a DC offset and did not fix remote volume. The revised Den Voice chain is 80 Hz high-pass (BWC, x2) → +12 dB post-filter gain → short-term loudness normalization (−23 LUFS target, −40 dBFS silence threshold) → 2:1 compression above −18 dBFS → −3 dBFS limiter, gain boost disabled. No noise gate or noise suppression that could cut quiet speech. A listener retest is still required; this is not a claim of restored call quality. LSP LV2 plugins supply the compressor/limiter. EasyEffects automatic input/output routing is disabled in a fresh managed configuration. Existing user configurations are preserved.

`sensei-voice-effects on` routes existing Vesktop microphone streams only; speaker monitors and other applications are excluded. `off` restores recorded routes when they still exist and remain managed. It does not change mute states or system defaults, and it does not claim persistent call-device selection after an app restart. Sound → Meeting provides these explicit actions.

If using the processed input across a rejoin, select Easy Effects Source in Vesktop. Keep the physical microphone as the system default; making the effects source its own upstream default can cause bad routing. Raw bypass is always available. Do not stack Discord suppression and additional denoisers without an A/B test.

## Twenty targeted searches

Executed 2026-10-21. Search results identify candidates; primary sources below determine technical conclusions.

1. Vesktop mic test works but call quiet.
2. Vesktop developer tools / debugging API.
3. Vencord AudioSettingsStore / MediaEngineStore.
4. Vesktop exposeDevTools setting.
5. whisper.cpp stream and VAD.
6. mijorus Whisper microphone implementation.
7. arniesaha linux-whisper implementation.
8. whisper.cpp CPU/base-model benchmarks.
9. EasyEffects microphone compressor/limiter.
10. EasyEffects RNNoise documentation.
11. DeepFilterNet realtime latency.
12. werman noise-suppression-for-voice PipeWire integration.
13. Discord input sensitivity / automatic gain control.
14. Equibop Linux microphone.
15. WebCord microphone / WebRTC.
16. Legcord microphone/API.
17. Electron remote-debugging switches.
18. Vesktop getUserMedia processing constraints.
19. PipeWire pw-top xruns.
20. WirePlumber target.object and default restoration.

## Primary-source findings

| Source | Finding / decision |
|---|---|
| [whisper.cpp](https://github.com/ggml-org/whisper.cpp) and [stream example](https://github.com/ggml-org/whisper.cpp/tree/master/examples/stream) | Recognition and streaming examples; retain pinned existing local implementation, not an audio enhancer. |
| [mijorus Whisper](https://github.com/mijorus/whisper), [linux-whisper](https://github.com/arniesaha/linux-whisper) | Dictation frontends overlap our existing explicit local transcription; no reason to install overlapping apps to fix call volume. |
| [EasyEffects](https://github.com/wwmm/easyeffects) | PipeWire effects host; reuse instead of writing a DSP server. Do not set its virtual devices as the system default. |
| [8.3 compressor](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/compressor_preset.cpp), [limiter](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/limiter_preset.cpp), [KConfig schemas](https://github.com/wwmm/easyeffects/tree/v8.3.0/src/contents/kcfg) | Matched preset keys, enum values and defaults to installed version; confirmed actual loaded settings. |
| [Vesktop developer options](https://github.com/Vencord/Vesktop/blob/v1.6.7/src/renderer/components/settings/DeveloperOptions.tsx) | Built-in chrome://webrtc-internals and GPU diagnostics. Prefer live WebRTC stats over a speculative client replacement. |
| [Vencord plugin docs](https://docs.vencord.dev/intro/) | Plugin interfaces exist; Discord webpack stores are internal and can change. Do not treat them as a stable public voice-control API. |
| [Vesktop issue 939](https://github.com/Vencord/Vesktop/issues/939) | Similar symptom, maintainer could not reproduce. Anecdotal issue report, not proof of our root cause. |
| [Discord troubleshooting](https://support.discord.com/hc/en-us/articles/360045138471-Discord-Voice-and-Video-Troubleshooting-Guide) | Check input mode, input volume, receiver-specific user volume and noise suppression; avoid reinstall/restart during the call. |
| [WirePlumber priorities](https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/priorities.html) | Saved defaults outrank priority; keep existing USB preference and respect explicit selection. |
| [pw-top](https://pipewire.pages.freedesktop.org/pipewire/page_man_pw-top_1.html) | Diagnose graph errors/latency rather than blindly tuning quantum. |
| [DeepFilterNet](https://github.com/Rikorose/DeepFilterNet), [RNNoise filter](https://github.com/werman/noise-suppression-for-voice) | Useful noise-reduction candidates; defer until raw/call gain discrepancy is understood. More suppression can damage quiet speech. |
| [Equibop](https://github.com/Equicord/Equibop), [WebCord](https://github.com/SpacingBat3/WebCord), [Legcord](https://github.com/Legcord/Legcord) | Alternative clients considered. A swap changes several variables and does not establish why this call is quiet; defer. |

## Next diagnosis

Inspect audio-source levels, outbound audio packets/bytes, remote loss and RTT from the active PeerConnection. Preserve private dumps locally only. A successful local mic test does not prove correct remote receive gain, and a packet count alone does not prove intelligible speech. Validate the final change with the actual listener.

## Supplied diagnostics: confirmed offset, call still unresolved

The owner supplied an RTCStatsDump gzip plus input/output WAV and AEC debug files. These remain outside Git. The stats format is a `RTCStatsDump` header followed by JSON lines, not a single JSON document. Parse only whitelisted audio statistics; never publish addresses, session identifiers or conversation content. No transcription was performed.

- Supplied input recording: DC mean roughly 0.058–0.066 full-scale in sampled windows. AC RMS across 1-second windows: median −52.8 dBFS, 99th percentile −43.9, maximum −28.4. The total RMS was dominated by DC; it did not demonstrate usable speech volume.
- Fresh physical-mic check: mean 0.0313, total RMS −30.1 dBFS, AC RMS −58.7. This confirms the offset exists upstream of the Discord call. It does not establish whether hardware, ALSA controls or firmware introduced it.
- Revised processed-source check before the additional +12 dB post-filter gain: mean about −0.000001, RMS/AC RMS −59.4 dBFS, no clipping. DC removal verified through the actual EasyEffects source.
- Stats snapshot: 42 samples spanning about 41 seconds. Outbound packets increased 1347 → 1757, remote-reported packet loss stayed zero, RTT about 58–68 ms. Media-source audioLevel peaked at ~0.0188 (−34.5 dBFS), often zero. No evidence of packet loss in this interval; no claim about all network paths or the receiver's volume.
- Owner still reports low volume. At the subsequent live check no Vesktop process or microphone capture stream existed. Need a live joined call to confirm the chosen source and measure transmitted speech after the revised chain.

Regression tests now ensure a constant DC offset cannot be marked as microphone signal. The meeting panel exposes AC RMS and the DC warning. Total peak/clipping remain separately reported.
