# Homie / radio window

The tower glyph appears on Homie's main bar while the RTL-SDR is connected.
Open it for FM audio, a seven-second USB test, a five-second spectrum receipt,
or Gqrx's full receiver/waterfall. The live survey shows real one-second integrations
with a rolling waterfall, and stops when the panel closes or after ten minutes.
Nothing scans in the background.

The actual receiver is RTL2838 with an R820T tuner. It receives; it cannot
transmit. The antenna's placement is useful, but coverage depends on band,
antenna resonance, local noise, terrain and gain—not merely window height.

```sh
sensei-radio status
sensei-radio test
sensei-radio scan fm
sensei-radio sensors      # explicit 15-second 433.92 MHz observation
sensei-radio record 94.4  # five-second broadcast FM IQ, SigMF + SHA-512
sensei-radio compare      # last two matching-band scans, preserve both receipts
sensei-radio history
sensei-radio fm 94.4 20    # MHz and RF gain in dB; not a station identity claim
sensei-radio stop
sensei-radio open         # Gqrx; close it before another receiver action
```

One dongle has one active owner. Den tests/captures/FM serialize through a lock;
Gqrx owns USB separately and a busy-device error never kills it. Stop affects only
the Den FM unit. Disconnecting does not leave a restart loop or stuck audio.
FM is routed through PipeWire at a conservative stream volume; system audio
controls can move/mute it. RF gain is not speaker volume.

## Things worth trying

| Job | Tool | What the result means |
|---|---|---|
| Find broadcast FM peaks | Widget / rtl_power | Relative spectrum, then manually listen |
| Compare antenna position or USB noise | Repeat the same bounded scan | Compare measured bins; not calibrated field strength |
| Decode your own weather/sensor packets | rtl_433 | Hardware/protocol and frequency must match your device |
| Understand AM/FM/SSB and filter widths | Gqrx | Interactive demodulation, waterfall and bookmarks |
| Observe 1090 MHz energy | Spectrum preset | Does not claim aircraft were decoded |
| Explore ADS-B positions | readsb/dump1090, optional | Needs appropriate antenna and sustained receiver ownership |
| Learn satellite reception | SatDump, optional | Check currently transmitting satellites, pass times and antenna first |
| Study cellular radio | Power-only preset; own offline/lab IQ in GNU Radio | No subscriber identities, private content or decryption |

GSM/gr-gsm is a specialized learning tool, not an automatic "nearby phones"
feature. It is deliberately not started by this desktop. GNU Radio (installed
with Gqrx) is available for controlled signal-processing experiments.

Bounded spectrum CSV and the latest JSON receipt live under
`~/.local/state/sensei-radio/`, private to the user. Units are explicitly relative,
uncalibrated dB. Sample loss is reported, not hidden. No feed uploads or exposed
rtl_tcp listener. The optional package list is `packages/radio.txt`.

Measured on Homie's actual hub: seven seconds at 2.048 MS/s reported zero lost
samples; FM survey returned 257 bins. FM output monitor: 30,848 signed 16-bit
samples, RMS 1,630.36, peak 5,103. This verifies a live audio path, not the
identity or intelligibility of a broadcast station.

## Pen and displays

The same hub's XP-Pen uses the shared `sensei-draw` workflow. Homie targets its
main DP-3; Arete retains Upper with automatic fallback. Driver settings and notes
are not copied between hosts. The user confirmed Homie's position/pressure.

```sh
sensei-draw quick          # one resumable white-paper scratchpad
sensei-draw status
sensei-draw focus          # optional distraction-free view; normal tools remain available
```

Hardware brightness remains preferred. Arete's USB-C adapter rejects DDC even
with longer retry timing. Upper therefore uses per-output gamma dimming through
wl-gammarelay-rs, labelled Software dimming. It changes pixels, not the backlight,
and is clamped above black. No full-screen QML dim layer or gamma modification
on the other displays. The neutral gamma returns if the helper stops.

Build the optional helper with `scripts/setup-display-dimming.sh`, install the
dotfiles, then enable `sensei-display-dimming.service` on a host that needs it.
Do not run another gamma/night-light owner simultaneously. Native DDC controls
coalesce slider changes and no longer perform a blocking read after every write.

## Experiment evidence

The Experiments tab records five seconds of broadcast-FM IQ as SigMF (`cu8`,
1.024 MS/s, 10,240,000 bytes) with capture-start UTC, hardware, frequency and
SHA-512. Incomplete captures are removed instead of being labelled successful.
The matching-bin comparison preserves both run IDs and warns that changing
signal strength is a confound. Receipts and raw samples stay private and local.

Live backend test: eight real frames with 257 bins each, followed by confirmed
process termination. Actual SigMF recording completed at the expected byte count.
A 15-second sensor observation heard zero matching packets; this is retained as
a valid negative observation, not a receiver or decoding success claim.

Older tutorials recommending NOAA-15/18/19 APT are outdated: the constellation
was decommissioned in 2025. Use current SatDump/ARISS transmission information.
