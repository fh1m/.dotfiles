# Receiver and desktop investigation — 2026-10-20

24 initial targeted searches, followed by specific DDC/gamma diagnostics. Search
results guided source inspection; forum experiences are hypotheses, not tests.
No claim of reading every result or validating every optional decoder.

| Searches (four targeted questions per row) | Primary sources read | Decision |
|---|---|---|
| RTL-SDR V4/Linux drivers; SDR++; Gqrx; CubicSDR | [Osmocom](https://github.com/osmocom/rtl-sdr), [SDR++](https://github.com/AlexandreRouma/SDRPlusPlus), [Gqrx](https://github.com/gqrx-sdr/gqrx) | Identify actual hardware first. Use distro librtlsdr and Qt/GNU Radio Gqrx; no duplicate receiver framework. |
| rtl_433 devices; ADS-B/readsb; SatDump; rtl_fm/rtl_power | [rtl_433](https://github.com/merbanan/rtl_433), [SatDump](https://docs.satdump.org/), [rtl_power manual](https://manpages.debian.org/experimental/rtl-sdr/rtl_power.1.en.html) | Bounded spectrum plus real FM now; aircraft/satellite decoding remains antenna/task-specific, not fake success. |
| Bangladesh reception rules; gr-gsm; XP-Pen support; Hyprland tablet mapping | [gr-gsm](https://github.com/ptrkrysik/gr-gsm), [OpenTabletDriver](https://opentabletdriver.net/), [libinput](https://wayland.freedesktop.org/libinput/doc/latest/tablet-support.html) | No legal claim inferred from search results. Power-only cellular view; configure detected XP-Pen with the existing Artist Mode integration. |
| libmpv/Qt render stacking; Lyrics Plus; Qt hover/opacity; NVIDIA cursor flicker | [Qt FBO](https://doc.qt.io/qt-6/qquickframebufferobject.html), [Spicetify](https://github.com/spicetify/cli), [Qt HoverHandler](https://doc.qt.io/qt-6/qml-qtquick-hoverhandler.html) | Explicit overlay z-order; 16:9 mini viewport; lyric-centric view; motion reveals tools and a wide hover target prevents premature hiding. |
| USB hub sample loss; SDR++ remote bandwidth; rtl_433 MQTT; receiver driver/ownership | [rtl-sdr source](https://github.com/osmocom/rtl-sdr), [rtl_433 hardware](https://github.com/merbanan/rtl_433/blob/master/docs/HARDWARE.md), [SDR++ manual](https://www.sdrpp.org/manual.pdf) | Actual hub benchmark, one owner, no always-on listener or automatic MQTT publication. |
| Sprite flicker; CAVA smoothing; Wacom/libinput; Gqrx gain/squelch | [Qt Image](https://doc.qt.io/qt-6/qml-qtquick-image.html), [CAVA](https://github.com/karlstav/cava), [Linux Wacom](https://linuxwacom.github.io/), [Gqrx](https://www.gqrx.dk/) | Source-clipped retained images; one desktop character, remove duplicate bar renderers; shared CAVA with a bounded smoothed curve, not synthetic activity. |

Additional source checks: [ddcutil FAQ](https://www.ddcutil.com/faq/),
[USB-C](https://www.ddcutil.com/typec/),
[per-output gamma relay](https://github.com/MaxVerevkin/wl-gammarelay-rs).
The relay is pinned to `9874e4a273a01f60e578a896183d67aa7a23572c` (1.0.1),
compiled with the lockfile and two jobs. It idles in one thread; measured service
memory was about 320 KiB, peak 2 MiB. Wayland reported 1,024-entry gamma ramps.

## Source-backed defects and actual corrections

- `youtube_music.run`: full metadata exceeded 8 MiB during a real play request.
  Installed yt-dlp source supports `youtube:skip=translated_subs`; redundant
  translated tracks are skipped without removing publisher captions or the cap.
- `MusicVideoSurface`: explicit controls z-order and a viewport preserving 16:9
  replace ambiguous stacking and the short fixed-height mini-player.
- `cursor-ui/shell.qml`: old pulse reached 10% in 50 ms; new pulse reaches 5.5%
  over 180 ms and eases away over 520 ms, with focus settling before triggering.
- `Companion.qml`: a scaled full atlas depended on crop geometry. The renderer
  now clips the source frame directly and retains loaded imagery. Independent
  bar sprites are removed so the leased desktop renderer is authoritative.
- `ExternalDisplays`: optimistic slider state preserves the latest queued target;
  slow DDC receipts cannot visibly pull the slider backwards. Backend avoids the
  redundant read after each successful write.
- Actual `ddcutil` bus 11 on Arete rejected getvcp 10 even with doubled timing;
  per-output gamma fallback was verified at 92% and restored. HDMI and Homie's
  hardware brightness were also exercised and restored.

Practitioner reports about USB noise, signal overload and broken DDC adapters
were used to choose measurements. They do not establish receiver coverage or
prove perceptual cursor smoothness. Physical pen acceptance came from the user.

## Extended receiver pass

Eight further targeted searches covered rtl_power streaming, rtl_433 bounded
JSON output, rtl_sdr sample counts, SigMF, SDR++ decimation, Gqrx local control,
NOAA satellite status and ARISS event schedules. Primary checks:
[SigMF](https://github.com/sigmf/SigMF),
[Gqrx controls](https://www.gqrx.dk/doc/remote-control),
[rtl_433 usage](https://github.com/merbanan/rtl_433/blob/master/docs/STARTING.md),
[NOAA decommissioning](https://www.nesdis.noaa.gov/news/legacy-orbit-noaa-decommissions-the-poes-satellite-constellation),
[ARISS](https://www.ariss.org/press-releases).

These changed implementation: explicit live rolling waterfall, same requested
20 dB RF gain across survey comparisons, SigMF captures with start timestamp and
SHA-512, immutable receipts and negative sensor results. Gqrx already provides
proper demodulation, filtering and waterfall; no parallel homegrown demodulator
or exposed control server was built. Legacy NOAA APT is not advertised as live.

Additional implementation verification read Gqrx's upstream `mainwindow.cpp`,
`dockrxopt.cpp` and `mainwindow.ui`: the seed-only input configuration uses real
supported keys, and Ctrl+D is its Start DSP shortcut. Actual packaged Gqrx 2.17.7
opened `rtl=0` with that profile. Qt 6 requires qt6ct rather than the session's
Qt 5 theme selector. Official SigMF 1.2.5 JSON schema and actual file SHA-512
were validated in an isolated uv environment, without installing Python packages
into the system interpreter.
