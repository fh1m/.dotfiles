# Bluetooth audit — 27 September 2026

## Path and evidence

oraimo SoundPro 2C → Intel AX200 USB Bluetooth (8087:0029) → btusb/Intel firmware → BlueZ git 5.87.r222 → WirePlumber → PipeWire 1.6.8 → Spotify native PulseAudio client. The Logitech LIFT shares the adapter and was left connected.

Initial Wi-Fi was 2.4 GHz, channel 11, 40 MHz width, surrounded by other 2.4 GHz networks. Bluetooth discovery was still running while the panel was closed and music played. These are plausible radio contention contributors; there was no controller crash or firmware timeout in the inspected kernel log and the initial PipeWire samples had no underruns. The user reported “Smooth so far” after moving Wi-Fi to 5 GHz. This supports an interference diagnosis but does not prove every previous glitch had the same cause.

USB autosuspend was already disabled both in the kernel command line and the AX200 USB device runtime power setting. Intel Wi-Fi/Bluetooth coexistence was already enabled. These settings were preserved; no driver unload, kernel swap or experimental Bluetooth options were added.

## Changes

- Activated the existing saved `fh1m_5g` network at 5765 MHz. Set its band to 5 GHz and autoconnect priority to 20. The saved 2.4 GHz network remains available as fallback. The resulting Wi-Fi signal was about -49 dBm with an 866.7 Mbit/s negotiated receive rate.
- Discovery now stops when the Bluetooth widget closes and expires after 20 seconds while open. Paired/cached devices remain immediately visible. A bounded scan remains available when adding devices.
- Trusted only the user-authorized oraimo headset. Added a WirePlumber rule reconnecting its A2DP music profile on partial connections.
- Disabled automatic hands-free profile switching. The device exposes SBC stereo, SBC-XQ and CVSD hands-free; no AAC/aptX/LDAC profile was advertised. Kept normal SBC for stability rather than forcing a higher bitrate. Hands-free can still be chosen manually from Sound profiles; apps use the existing non-Bluetooth microphones by default.
- Removed the 110% software output boost to avoid potential digital clipping. Headset hardware volume may be restored by the device on reconnection; it remains adjustable normally.

## Verification and limits

Two disconnect/reconnect cycles succeeded: disconnect about 0.27 seconds, reconnect 3.52 and 3.66 seconds, both restored A2DP. Both displays and the mouse remained available. A short radio capture showed no HCI disconnect/error event during its observation; raw capture data was discarded after review. 55 active audio samples showed maximum PipeWire error counter 0, with little processing load. The final headset stream carried Spotify stereo correctly.

WirePlumber intentionally pauses MPRIS players when their output disappears (`linking.pause-playback=true`). This was preserved to prevent unintended playback through laptop speakers. After reconnect, Play recreates the stream normally. The temporary Wi-Fi band handoff also interrupted Spotify network access; the client was restarted and its current playlist/track restored. That maintenance interruption is separate from Bluetooth transport stability.

This is evidence of improvement, not a promise that radio interference, distance, device batteries or future driver regressions can never interrupt audio. Suspend/resume and cold boot were not tested because the live desktop was kept running.

## Rollback

Before-change files and profile values are in `~/.local/state/bluetooth-audit-20260927/`. Remove `~/.config/wireplumber/wireplumber.conf.d/60-sensei-bluetooth.conf` and reset the saved autoswitch setting to restore default microphone switching. Restore the saved 5 GHz profile values to undo its preference. Bluetooth system configuration and firmware were not altered.

Primary references: [Intel/Linux Wi-Fi coexistence](https://wireless.docs.kernel.org/en/latest/en/users/drivers/iwlwifi.html), [WirePlumber Bluetooth rules](https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/bluetooth.html), [BlueZ reconnect policy](https://raw.githubusercontent.com/bluez/bluez/master/src/main.conf).

## Deeper jitter diagnosis and targeted fix

The user still heard intermittent jitter after the radio cleanup. A 44.98-second HCI trace contained 2,929 outgoing SBC packets, 26 RTP sequence discontinuities, 58 packet gaps over 30 ms and a maximum gap of 90.102 ms. Codec bitpool oscillated between 39 and 53. Live management RSSI was -14 (this controller metric is not the cached discovery RSSI). Audio threads already had realtime scheduling (PipeWire priority 88, WirePlumber audio loop 83).

WirePlumber debug logs confirmed the exact failure: the Bluetooth send socket returned EAGAIN, the encoder reduced its bitpool, and PipeWire's media-sink implementation discarded that packet. These transport drops do not necessarily increment the ordinary pw-top ERR counter. Wi-Fi power-save off was tested separately and still produced 22 discontinuities over about 36 seconds; that unsuccessful setting was reverted, including the saved profile.

A small local C shim now enlarges the send socket buffer only for the oraimo headset’s AVDTP L2CAP socket. It changes the requested buffer from 2,864 to 8,592 bytes (Linux reports twice the requested size). PipeWire reads the actual buffer back, so its queue accounting remains consistent. It is loaded only into the user WirePlumber service through `~/.config/systemd/user/wireplumber.service.d/60-sensei-a2dp-buffer.conf`; source and shared library are in `~/.local/share/sensei-bluetooth/`. There is no new daemon, polling loop or per-audio-frame processing. Nonmatching device addresses, non-AVDTP profiles and non-Bluetooth sockets keep their original buffer behavior. Fixture checks verified target-device enlargement and unchanged other-device/other-profile buffers. The shim uses a thread-safe symbol resolver.

This is a custom workaround for short controller/device stalls, rather than an upstream configuration option. It permits extra queueing latency when the radio stalls, in exchange for avoiding dropped music packets. It does not change Spotify’s command handling or audio codec and does not overcome sustained radio congestion.

In the matching 44.99-second enlarged-buffer trace, 3,375 packets had **zero sequence discontinuities**, maximum gap 68.727 ms and only 15 gaps over 30 ms. SBC bitpool stayed at 53 throughout. A separate 25-second debug window had zero buffer-pressure bitrate reductions. This provides stronger evidence than the earlier zero pw-top errors. User listening confirmation and longer observation remain the practical check.

To roll back just the socket workaround: remove the `60-sensei-a2dp-buffer.conf` service drop-in, run `systemctl --user daemon-reload`, then restart WirePlumber. A WirePlumber restart can leave this Spotify client’s existing PulseAudio sink unusable, so restart/recover Spotify playback after maintenance; ordinary Bluetooth disconnect instead triggers a deliberate pause and Play resumes normally. All debug log levels were restored to warning level after capture. Raw HCI captures are discarded after timing summaries are extracted.

Source evidence: [PipeWire media-sink transport handling](https://github.com/PipeWire/pipewire/blob/master/spa/plugins/bluez5/media-sink.c), notably the EAGAIN path that drops a packet and the SO_SNDBUF readback.

Further listening still reported occasional jitter despite two enlarged-buffer traces with zero sequence gaps. The generated local tone was not audible enough to establish a valid comparison. Removed Spotify’s aggressive PULSE_LATENCY_MSEC override and changed service Nice=5 to Nice=0; its observed client buffer increased from about 45 to 145 ms. This trades a small amount of audio queue latency for more scheduling headroom. No global PipeWire quantum or sample-rate changes were made. The Bluetooth send buffer fix remains active and codecs remain unmodified.

Final larger-client-buffer trace: {"packets": 3375, "seconds": 44.99, "sequence_discontinuities": 0, "largest_gap_ms": 59.934, "gaps_over30ms": 6, "bitpool_range": [53, 53]}.

## Quality and device-control follow-up

A controlled SBC-XQ comparison produced 20 RTP sequence discontinuities in 45 seconds, versus zero in the larger-buffer regular-SBC traces. XQ also reduced bitpool under pressure. Restored regular SBC, keeping its full tested bitpool 53. The headset does not advertise AAC/aptX/LDAC; a setting cannot invent codec support. The raw XQ capture is discarded after its timing summary. These measurements establish improvement, not a guarantee against radio interference or Spotify network stalls.

The Bluetooth bar shows the connected-device count and pulses while audio uses the Bluetooth output. Its panel has Device, Audio, Adapter and Tools pages: trust/block/nickname/wake, reported battery/radio metadata, codec/profile selection, output/mute/volume, discovery/pairability, and on-demand diagnostics. Unreported battery/radio values are labelled rather than fabricated. Discovery ends after 20 seconds or closing the panel. Expensive detailed polling and audio subscriptions run only while open.

Useful tools already available: `bluetoothctl` for pairing/controller state; `btmon` for packet timing; `pw-top` for graph errors; `wpctl` for routing/settings; `pavucontrol` for per-app sound. These complement the panel without adding resident managers. Refer to [WirePlumber Bluetooth configuration](https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/bluetooth.html), [WirePlumber settings](https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/settings.html), and [Intel wireless documentation](https://wireless.docs.kernel.org/en/latest/en/users/drivers/iwlwifi.html).
