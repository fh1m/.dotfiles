# Den media, motion and radio pass — 2026-10-20

Preserve shared main, private account state and input escape controls. No disk,
bootloader, credential-copy or unattended radio service changes.

1. [x] Reproduce media failure; fix native overlay controls, bounded stream recovery,
   aspect ratio, immersive lyrics and hover-safe auto-hide.
2. [x] Soften focus pulse; inspect cursor policy without taking input away.
3. [x] Validate Zondo sprite boundaries and one-character presentation; smooth motion.
4. [x] Verify widget output ownership and coalesced brightness on both hosts.
5. [x] Configure Homie's detected XP-Pen 28bd:0918 and its existing drawing tools.
6. [x] Install receiver tools for actual RTL2838 0bda:2838; bounded USB test and
   spectrum capture; useful themed Radio widget/button only with receiver present.
7. [x] Validate on both machines, document measured limits, commit and deploy main.

Radio tool ownership: librtlsdr for hardware, Gqrx for real receiver/waterfall,
rtl_power for explicit bounded spectrum receipts, rtl_433 for explicit own-sensor
experiments. One receiver owner at a time; no background scans, bias-tee activation,
EEPROM writes, network listener or private-communication decoding.

## Acceptance / measured 2026-10-20

- Shared main deployed to both hosts; both installer previews report zero changes.
- Homie desktop harness: all 11 checks passed. No native input restart or new grab.
- Full Python suite: 433 tests passed; receiver tests include incomplete IQ cleanup,
  exclusive ownership, invalid tuning, early FM startup failure and seed-only Gqrx.
- Radio panel: actual 257-bin live frames and four waterfall rows; Receipts view
  loaded real history. Closing stopped rtl_power; no Radio/QML reference errors.
- Seven-second USB test reported zero lost samples at 2.048 MS/s. Real FM audio
  samples were measured. Gqrx opens with rtl=0 at 2.048 MS/s, in the shared dark
  theme; DSP remains an explicit user action.
- Five-second IQ: 10,240,000 bytes, official SigMF 1.2.5 schema valid, SHA-512 valid.
  Fifteen-second sensor observation: zero packets, retained as negative evidence.
- XP-Pen: driver/mapping service active; user physically confirmed position/pressure.
- Both hosts use CPU-backed cursor textures; native input sharing remains active.
  Frame clipping removes duplicate bar characters; perceived smoothness still
  depends on actual hardware/compositor behavior and is not claimed perfect.
- Real YouTube metadata failure repaired; native playback was observed advancing
  with video frames. Mini transport and lyric-centric immersive UI were inspected.
- Brightness writes/restoration: HDMI and Homie hardware, Upper software fallback.

No aircraft, satellite, GSM-content reception or calibrated RF measurement is
claimed. No actual monitor unplug/reboot was performed during this pass. Private
Google keyring/account permission limits documented in MEDIA-CENTER.md remain.

### Cursor continuity follow-up

The event socket closed during this pass; the cursor daemon previously returned
on EOF, stopping its visual renderer. It now reconnects with a bounded retry delay
without restarting the renderer or native input service. Arete's updated daemon
remained the same PID with zero restarts from 04:36 through 10:46. Layer-panel
geometry is published privately and used as an exclusion area for Zondo and his
bubble; live checking moved him outside an open display panel. No window text,
clipboard content or video content is used by that geometry mechanism.

### Final deployment check, 10:50

Both host worktrees are clean at the deployed implementation revision; installer
previews report zero changes. Homie's 11 desktop checks pass again, and the fresh
shell reports no QML errors. The RTL-SDR is now physically absent from both USB
inventories: its button hides, the disconnected panel is usable, and no rtl_power
process remains. Earlier attached-hardware measurements above remain the test
receipts; no final attached-device test is falsely claimed. Arete's saved manual
input pause is enabled and preserved; Triple Ctrl resumes through the existing
toggle. Cursor visual services are active without restart churn. Main tests:
433 passed; separate native cursor/recovery tests: five passed.
