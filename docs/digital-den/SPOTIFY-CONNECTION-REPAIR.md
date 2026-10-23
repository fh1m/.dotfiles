# Spotify sign-in and idle recovery — 2026-10-23

## Causes verified

1. `/auth/code` returns HTTP 204 when no pairing is pending. A valid, already
   linked account therefore produced a successful no-op, and the UI discarded
   its explanation. This is not evidence that credentials expired.
2. Clicking Sign in before the first status response selected the obsolete
   terminal/developer login path because the backend was still unknown.
3. The native player crashed with `math/big: buffer too small to fit value`.
   Its base62 decoder accepted numbers larger than a 128-bit Spotify ID before
   calling `FillBytes(16)`, which panics on overflow.
4. A headless status test wrote a synthetic track into the real resume cache.
   The test class now always uses a temporary STORE. Invalid fixture records
   were preserved privately and removed from the active resume path. Do not run
   older versions of these tests against a daily-driver home directory.
5. An idle/stopped receiver returned no track; the presentation discarded the
   last artwork even though the saved login and playback still existed.

## Repairs

- Connected-account action opens Spotify Account and explains that it is linked.
- Pending pairing opens only validated Spotify HTTPS URLs, displays its code and
  message, and polls until connection is acknowledged. Browser failures have a
  fallback account-link button instead of silent success.
- Sign in always uses the selected adapter, even before initial status arrives.
- Startup/reconnection is not labelled logout. Cached credentials are retained;
  no account reset or credential copying is performed.
- Last real track/artwork survive idle and transient reconnects. Playback is not
  falsely reported as running. Resume restores position and queue atomically.
- Python validates the numeric ID range; the pinned native decoder also returns
  an error instead of panicking. `id-overflow.patch` includes a Go regression
  test. The build installer applies it with the existing queue/status patch.
- Controller button is invisible, with no allocated width, when inventory is
  empty. The existing inventory poll discovers subsequent connections.

## Acceptance

Arete's real saved account authenticated without another login. A real liked-song
playback decoded Vorbis at **320 kb/s, 44.1 kHz**. The Account UI shows requested
quality separately from measured stream quality; it does not infer billing tier
from a checkbox. Library returned 50 rows from 575 liked tracks.

A controlled player restart retained artwork. A subsequent Play restored the
same real track, its position and both queued tracks, again at 320 kb/s. The
Account action opened the browser and returned a visible connected message.
Pending fresh pairing, untrusted URLs, startup, outages and idle metadata have
regression tests. No destructive sign-out was needed to test an already valid
account. This is not a guarantee against all future Spotify/network changes.

No lossless or offline-download capability is claimed. Official Spotify Account
remains authoritative for subscription details. Playback restrictions still
apply, including one active Connect receiver for the same account.

Private Arete deployment backup:
`~/.local/state/den-repairs/spotify-login-20261023-220403/`.
Native binary rollback: `~/.local/opt/go-librespot/go-librespot.previous`.
Keep credentials and invalid-cache quarantine outside Git.

Sources:
- https://github.com/devgianlu/go-librespot/blob/master/api-spec.yml
- https://github.com/devgianlu/go-librespot/blob/master/README.md
- https://github.com/devgianlu/go-librespot/blob/master/ids.go
