# Music, transport and Bluetooth

[← Workstation](../README.md)

![Spotify studio](assets/spotify.png)

## Current default: lightweight Connect player

Playback and library browsing now use a pinned, patched **go-librespot** service.
Global search uses Spotatui on demand, with its streaming disabled. Neither needs
the official Spotify desktop client running. Artwork, timed lyrics, fullscreen
listening and media keys retain the existing widget interface.

[Setup, capabilities, recovery and measured checks](digital-den/SPOTIFY-HEADLESS.md) ·
[24-query research ledger](digital-den/SPOTIFY-RESEARCH-2026-10-19.md).

Account → Use official Spotify remains an explicit fallback. The earlier desktop
bridge is preserved; it is not silently started after headless failures.

## Optional native backend and its history

The following describes the retained native transport and earlier investigations.
Its Web API quota is independent from the current desktop-session backend.

### Native path

```mermaid
flowchart LR
    Click[Widget / global key] --> C[Compiled local transport]
    C --> UDP[Loopback daemon interface]
    UDP --> Player[Patched spotify-player / librespot]
    Player --> Pulse[Per-client PulseAudio stream]
    Pulse --> PW[PipeWire + WirePlumber]
    PW --> Sink[Speakers or Bluetooth]
    Catalogue[Playlist / library request] --> API[Spotify Web API worker]
    Events[Native playback events] --> UI[Widget metadata + artwork]
```

The Web API is for catalogue/account work, not the fast local transport path. Independent workers prevent playlist fetching from blocking play/pause. Native events carry track, position, state and device ownership; stale remote snapshots cannot casually overwrite them. Artwork replacement does not blank the old cover while downloading.

## Build and authenticate

The repository retains the modified `spotify-player` 0.25.1 source, lockfile and MIT license. Build it with `scripts/build-spotify.sh`, then build the C bridge. Do not substitute the distribution binary and expect the private patches to exist.

Configure `~/.config/spotify-player/app.toml` with **your own Spotify client ID** and an allowed loopback redirect. The published value is a placeholder. Spotify account, API eligibility/scopes and Premium playback restrictions apply. Consult [spotify-player](https://github.com/aome510/spotify-player) and [Spotify’s current migration guide](https://developer.spotify.com/documentation/web-api/tutorials/february-2026-migration-guide) when configuring a new account.

```sh
sensei-spotify-login
systemctl --user enable --now sensei-spotify.service
journalctl --user -u sensei-spotify.service -f
```

Tokens stay in private local cache directories and are not committed. Do not put a client secret into a public desktop config. The local UDP/transport path is a loopback interface, not a service to expose over the network.

## What changed

The player avoids duplicate daemon/TUI catalogue work, preserves skip intent, restores local queue context, and preloads one next track earlier. The audio cache is bounded at 256 MiB. Local ownership is deliberately selected; automatic reconnect does not keep stealing Spotify Connect playback from another chosen device.

Playlist rows distinguish **browse the collection** from **play it**. API parsing accepts modern `/items` wrappers and older `track` forms; pagination is context-bound; repeated URIs are removed; inherited search filters are cleared. A late library request cannot empty or replace a newer playlist page.

Bridge status calls measured roughly 2–4 ms in short local samples. Cold audio retrieval had previously taken 2.7–3.4 seconds after the command arrived. Preloading helps known next tracks; uncached/unavailable songs still depend on network/Spotify responses. This is not a claim that every remote track can start instantly.

## Sound controls

The Sound panel reports active output/source, devices/profiles and per-application streams. Volume acknowledgement is separate from delayed catalogue requests, so a slider does not snap back to an old server value. Detailed subscriptions run while the panel is open; native PipeWire controls provide immediate feedback.

The system output slider in the Sound panel allows up to 150% gain. The bar's sound badge wheel stops at 100%, so an accidental scroll cannot push the output past full. Spotify Connect's own volume remains 0–100%; use the system output for extra gain. Values above 100% can clip a loud recording.

The experiment with an aggressive Spotify client latency override made listening less robust. It was removed. Normal client buffering (~145 ms observed in one sample) and normal CPU priority provide scheduling headroom without slowing UI command dispatch. Global PipeWire quantum/sample rate were not broadly changed.

## Bluetooth investigation

The reference headset exposed SBC, SBC-XQ and hands-free CVSD, but not AAC/aptX/LDAC. A setting cannot invent a codec the devices do not negotiate. Regular SBC at tested bitpool 53 was more stable than XQ in the captured comparison.

Moving Wi-Fi to 5 GHz reduced 2.4 GHz coexistence pressure. Discovery stops when the widget closes and expires after 20 seconds; paired devices appear from cached state immediately. Automatic hands-free switching is disabled for the music policy so microphone use does not unexpectedly replace stereo playback. Hands-free remains manually selectable.

On the UX581GV the AX200 Wi-Fi interface still had power saving enabled on 5 GHz. The following disables it for the active NetworkManager connection, removing one possible sleep/wake contributor to headset stalls:

```sh
nmcli connection modify YOUR_WIFI_CONNECTION 802-11-wireless.powersave 2
sudo iw dev YOUR_WIFI_INTERFACE set power_save off
iw dev YOUR_WIFI_INTERFACE get power_save
```

Use the actual connection/interface names on another machine. The NetworkManager setting persists; the `iw` command applies it immediately. This can cost some battery power.

The 2026-09-28 Spotify skip test found a separate, digital gap before Bluetooth: 1.05 seconds of silence on two early skips. Preloading the next URI immediately when the local queue is accepted reduced an early Next sample to 0.15 seconds of silence. This does not prove the radio is always clear; PipeWire also logged missing AX200 packet-completion reports during a local tone test. Steady Spotify audio showed zero PipeWire graph errors in a 24-second sample.

The bar keeps album art still, with a loading indicator while a track loads and a paused indicator when appropriate.

On 2026-10-03, a long-lived player lost its streaming channel after a DNS disruption. Its process and local control socket remained up, but `StartUris` returned `channel closed` and the headset monitor stayed digitally silent. Restarting only `sensei-spotify.service` rebuilt the session and a new capture confirmed nonzero PCM at the Bluetooth output. The transport recovers this specific session failure once. **Next/Previous are never replayed after recovery:** their outcome is ambiguous, so check the current track before skipping again. Other failures remain visible.

## Den playback and request budget — 2026-10-15

Next/Previous now send exactly one native command. A following Play/Pause used
to race Spotify Connect ownership and could revive a changed queue. The UI waits
for a changed URI before accepting another Next acknowledgement. Device names
come from each host's configuration; Homie does not impersonate Arete.

The Rust daemon and Python catalogue helper share a locked, persistent per-host
gate: at most ten Web API requests in a rolling 30 seconds. The observed
`Retry-After` is preserved without a 15-minute cap. `QUOTA_EXCEEDED` stays blocked
until explicit operator reset; the application does not invent a subscription
reset date or switch client identities to get around a quota. Cached content and
native playback remain separate paths. This local request budget is **not** the
account's remaining Spotify quota, and is not a cross-host quota server.

```sh
sensei-spotify budget
# Only after resolving the provider restriction:
sensei-spotify budget-reset
```

The 90-minute passive observation had 1,076 status samples, zero status errors,
zero unexpected backward position resets and two track transitions. Only 121
samples were playing: this was not 90 minutes of uninterrupted listening. Native
UDP regression tests verify one command per skip; a real external-device transfer
is a separate acceptance check. [Spotify quota policy](https://developer.spotify.com/documentation/web-api/concepts/quota-modes).

`pw-top` showed no graph underruns even when listening still jittered. HCI timing revealed a more specific issue: short stalls caused an outgoing L2CAP socket to hit queue pressure, and PipeWire’s sink could drop packets. A headset-only `SO_SNDBUF` interceptor increased queue headroom. A larger-buffer trace recorded 3,375 packets over 44.99 seconds with zero sequence gaps; SBC-XQ comparison recorded 20 gaps in 45 seconds. Those samples support the change, not a promise of zero radio interruptions forever.

## Optional socket workaround on a new machine

Build `src/bluetooth/a2dp-buffer.c`. The published code requires `SENSEI_A2DP_ADDRESS`; without it, it passes socket operations through unchanged. Use the example WirePlumber drop-in under `system/bluetooth`, substitute your actual headset address, and activate it only after reproducing a relevant issue. It affects outgoing Bluetooth A2DP L2CAP traffic for that peer, not TCP, ALSA or every headset.

```sh
systemctl --user daemon-reload
systemctl --user restart wireplumber
```

A restart can invalidate an existing Spotify audio stream; recover the player after maintenance. Roll back by removing only that drop-in, daemon-reloading and restarting WirePlumber. The workaround trades additional queue latency during radio stalls for fewer packet losses. No root cause is claimed for every possible Spotify network/audio interruption.

## Useful checks

```sh
wpctl status
pactl list sink-inputs
bluetoothctl info HEADSET_ADDRESS
pw-top
# Packet tracing needs appropriate privilege and contains device metadata:
sudo btmon
```

Do not publish raw traces or pairing state. The Bluetooth panel provides connection counts, device trust/block/nickname, audio state, bounded discovery and diagnostic tools. Only advertised battery/codec/radio data is displayed; unavailable fields remain labelled.

References: [WirePlumber Bluetooth configuration](https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/bluetooth.html), [PipeWire media sink](https://github.com/PipeWire/pipewire/blob/master/spa/plugins/bluez5/media-sink.c), [Intel Wi-Fi driver documentation](https://wireless.docs.kernel.org/en/latest/en/users/drivers/iwlwifi.html).
