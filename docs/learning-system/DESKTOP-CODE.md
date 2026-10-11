# Code desk and desktop stabilization

The identity artwork opens **Code / Agents**. Middle click (or Shift-click) keeps
operator tools; right click opens XKCD. Ctrl+1 / Ctrl+2 selects Code / Agents,
Ctrl+K searches projects and Ctrl+R refreshes. All network actions here browse;
no pull request, issue or repository is edited.

GitHub uses the active `gh` account, five-minute private cache, contribution map,
pinned/recent repositories, open PRs, requested reviews, issues, recent commits
and selected-repository CI. Local project matches open through `sensei-dev`,
preserving its container and tmux workflow. Repository/activity pages load on
request. Commit history is repository activity, not claimed personal authorship.

Agents has independent Codex and OpenCode tabs. Codex uses its supported local
app-server account/rate-limit RPCs; no inference request or auth-file copying.
It shows reported plan, remaining windows, exact reset dates, credits and resets.
Exhausted usage, Free plan, missing sign-in and refresh failure are distinct.
A Free plan offers renewal of paid access, but is not proof of billing expiry.
The API does not expose a confirmed subscription-expiration date. OpenCode v1
provides aggregate local seven-day sessions, messages, cost and tokens; these
are not provider subscription balances. Claude integration is deferred.

Codex polling/notifications exist only while its tab is open. Closing the panel
terminates owned adapters and child app-server processes. GitHub cache lives in
`~/.cache/sensei-code` (directory 0700, files 0600); private snapshots and account
state never belong in this repository. Network failures preserve displayed data.

## Desktop behavior

Three ordinary tiled windows trigger native grouping. Two stay tiled. Floating,
pinned, fullscreen, special-workspace and utility windows are excluded.
Super+Alt+G toggles groups; Super+Alt+U detaches and pauses automatic grouping
for that workspace. Super+Alt+Shift+G resumes. Native drag-out also pauses auto
regrouping. Quickshell decorates each visible group; native titles remain a
fallback if the shell is unavailable. Group strips stay inside window bounds.

Spotify Next/Previous send one native command. Pending/loading skips are gated,
never queued into multiple advances. A service recovery never replays a playback
mutation. Media keys and widget controls share this gate. Popup reveal is 160 ms
with a 6 px shift; dismiss is 110 ms. `SENSEI_REDUCED_MOTION=1` removes reveal
motion. No blur or continuously running animation was added.

## Verification and recovery

`python3 -m unittest discover -s tests -p test_desktop_code.py -v`
checks private caching, account states, OpenCode aggregate parsing, eligible
windows, single playback commands and non-replay on service recovery.
The existing 16 learning CLI tests also pass.

Live checks on this laptop: six rapid skip inputs advanced one track; a later
independent skip advanced one more. The third eligible test window grouped;
manual detach/resume and focus outside the group were exercised. Calendar,
system, clipboard, music and code reveals showed intermediate opacity. Noesis
opened on the main display. Both provider pages were visually inspected; closing
Codex stopped its adapter/server. Hyprland reported no configuration errors.
These are interaction tests, not a claim about acoustic playback or physically
disconnected-monitor behavior.

Pre-change deployed files/native transport are retained under
`~/.local/state/dotfiles-backups/desktop-code-20261011-145519`. Files added later
can be restored from the parent Git commit; deploy only this slice rather than
running a whole installer over unrelated live edits. Noesis private content was
not modified. Old inactive `/tmp/noesis-*` synthetic test fixtures were retained
in `~/.cache/fh1m-desktop-build/retained-test-fixtures`, freeing about 7.5 GiB of
tmpfs; nothing was deleted.

Interfaces verified against [Codex app-server](https://developers.openai.com/codex/app-server)
and [OpenCode CLI](https://dev.opencode.ai/docs/cli/). Installed OpenCode v1 lacks
the newer JSON stats option; the adapter parses only allowlisted aggregate rows.
