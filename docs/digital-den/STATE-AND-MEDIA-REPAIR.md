# Den state and media repair — 23 October 2026

## What changed

- **Wi-Fi:** a running Quickshell Process cannot be reused by just replacing its
  command. Connect/disconnect now finish in order, retaining only the newest
  pending request. Its password remains in memory/stdin, never argv. Intermediate
  results cannot overwrite the final requested state. Operations have explicit
  NetworkManager timeouts. Homie no longer mistakes its Ethernet interface for
  a Wi-Fi adapter; absent wireless hardware is handled explicitly. `qs ipc -c sensei call wifi state` exposes diagnostics.
- **Spotify lists:** starting a context and immediately appending tracks raced
  context resolution. The pinned go-librespot patch now accepts an ordered
  `queued` array with `/player/play`; context resolution installs that queue in
  one operation. Duplicate tracks remain distinct. Resume errors propagate
  instead of claiming success with no primary stream.
- **Spotify recovery:** successful, non-buffering status writes an atomic private
  checkpoint. Stopped/buffering responses cannot erase it. Explicit Play on a
  stopped player restores its song, position and up to 50 upcoming tracks. A
  failed status read can restart the service once per two minutes under a file
  lock, then wait briefly for login. Only reads are retried: uncertain Next or
  enqueue writes are never replayed. The open music widget keeps checking during
  pause, so it can notice an unavailable service.
- **Claude:** token totals remain local transcript measurements. Account quota
  windows use the newest matching-account status-line receipt from either host,
  never the sum of percentages. Remote-only accounts get their own cards.
  Receipts include source host and timestamp; expired windows are labelled as
  awaiting an update. SSH transfers quota/identity metadata only, not credentials
  or conversation text. Peer reads are cached for 60 seconds and survive offline
  operation using the last receipt.
- **Homie shell:** its updated CodeDropdown referenced an undeployed GuestLibrary.
  Quickshell retained an older UI after failed reloads. The missing component and
  public companion assets are deployed; the shell was refreshed independently
  of applications and input sharing. A successful Den status now clears the old
  scan error rather than leaving a false unavailable message visible.

## Ownership and limits

Claude receipts originate from Claude Code's documented status-line JSON. They
are account-wide windows, but their freshness depends on Claude activity: this
is not an independently polled billing API. Hash matching currently uses the
signed-in email; local token totals are not merged across machines. The optional
quota-only SSH profile has a tracked `.example`; its host pin, authorization and
private key remain local. Arete's dedicated entry forces `sensei-code
claude-quotas`, with LAN restriction and forwarding disabled. No general shell
access was added for that key.

The Spotify checkpoint is a bounded upcoming window, not a permanent copy of an
entire playlist. Recovery does not autoplay or silently reclaim a remote device:
Play is required to restore stopped playback. Spotify outages, expired login and
provider rate limits still need honest error messages; this does not bypass
provider limits. A healthy status endpoint with an unrelated internal playback
bug is not grounds for a restart loop. Rollback binaries are kept privately on
both machines; rebuild with `scripts/setup-headless-spotify.py --build` from the
pinned source plus `patches/go-librespot/queue-status.patch`.

## Verification performed

- 62 Spotify adapter/policy tests, 19 Den continuity tests, 3 Claude quota tests
  and 1 actual-JavaScript Wi-Fi serializer test.
- Patched Go backend built successfully; reverse-apply check confirms the tracked
  patch matches the build checkout. `go test ./daemon ./tracks` compiles those
  packages; this checkout reported no Go test files, so it is not counted above.
- Real Spotify playback on Arete and Homie: atomic three-entry queue (including
  duplicates), pause, resume; Arete Next consumed exactly one entry.
- Arete service deliberately stopped: status recovered it automatically; explicit
  Play restored the saved song and both upcoming entries. Left test playback
  paused. No input-sharing restart was involved.
- Real rapid Wi-Fi disconnect/connect/disconnect/connect through the shell IPC:
  final state connected, no pending request or error; Ethernet stayed available.
- Pinned quota-only SSH from Homie to Arete returned a receipt; Homie displayed a
  remote-account card. No credentials were copied.
- Restic metadata and 10% sampled data check passed. A fixture restored into a
  separate temporary directory matched its SHA256. The scheduled Arete backup
  rerun, including peer-copy, completed successfully.

Read-only sweeps queried 53 Arete and 45 Homie widget-state endpoints with no
failed calls or reported errors after repair. This checks callable endpoints;
it does not claim every button or physical peripheral has been manually tested.
Do not treat a brief music test as proof against every future server failure.

## References

- [Claude Code status-line contract](https://code.claude.com/docs/en/statusline)
- [NetworkManager nmcli reference](https://networkmanager.pages.freedesktop.org/NetworkManager/NetworkManager/nmcli.html)
- [go-librespot source](https://github.com/devgianlu/go-librespot)
