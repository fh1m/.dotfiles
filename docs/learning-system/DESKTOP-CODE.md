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
The API does not expose a confirmed subscription-expiration date. OpenCode uses read-only SQLite metadata aggregates with 7-day, 30-day and
all-time views, falling back to CLI statistics on older layouts. Local activity
is separate from provider subscription balances. Claude integration is deferred.

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
never queued into multiple advances. Closed-channel responses never restart the player or replay a playback
mutation. Recovery is explicit in Account. Device-release events cancel queued
local slider/control intent; native status cannot replace released playback.
The startup pause guard expires after five seconds, so a later phone-initiated
start is respected. Native queue preload runs on Playing, never on device release. Media keys and widget controls share this gate. Popup reveal is 160 ms
with a 6 px shift; dismiss is 110 ms. `SENSEI_REDUCED_MOTION=1` removes reveal
motion. No blur or continuously running animation was added.

## Verification and recovery

`python3 -m unittest discover -s tests -p test_desktop_code.py -v`
checks private caching, account states, OpenCode aggregate parsing, eligible
windows, single playback commands and non-replay on service recovery.
The existing 16 learning CLI tests also pass. The desktop suite now has 17 tests,
including closed-channel read safety, remote-device ownership, Go failure states
and a real PTY/FIFO interactive transaction in a disposable fixture.

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

## October 11 polish

The identity is a compact sensing/heading drawing, centered in its hit area with
six pixels of left rail breathing room. The Spotify separator belongs to music,
with 24 pixels before its album art. Weather is static, quieter text rather than
a scrolling ticker. Notification and GPU activity use acknowledgement dots;
opening their panels clears the dot. Tray targets have more spacing. Tab strips
are inset from the window corner cuts and use a pink side marker instead of a
second horizontal border. Popups use their own recorded anchor; bottom-panel
routing falls back to the main display if the ScreenPad is absent.

The zsh prompt keeps directory, branch and environment context on separate lines,
without filled pink backgrounds. Its right side shows exit code, elapsed time and
`tmux` only inside tmux. Timing uses zsh's built-in clock. New shells load it;
existing interactive shells can run `source ~/.config/zsh/prompt.zsh`. A local
50-build comparison measured 4.70 ms versus 1.41 ms for prompt construction before
the final spacing changes; this is not a claim about whole-desktop speed.

### Updates without a terminal

System → Packages handles repository/AUR updates, install/removal, orphan cleanup,
cache cleanup, logs, Flatpak and firmware as distinct actions. `sensei-package-job`
launches an owned user systemd job, streams a bounded log, displays observed phases
and accepts package-manager answers inside the widget. Authentication uses the
existing Zenity password dialog through sudo askpass; passwords never go into
job state. AUR review remains enabled. Stop requests delegate SIGINT, not SIGKILL.
Closing the widget does not terminate a transaction. Reopen it to answer prompts;
notifications announce confirmation requests and completion. Concurrent jobs are
rejected. No overall completion percentage is invented.

Private state and history live under `~/.local/state/sensei-packages` (0700/0600).
A read-only transaction-log job ran through the real user unit and persisted its
result. PTY confirmations were tested using a disposable command. A privileged
full upgrade, authentication and firmware flash were not performed as validation.
No packages or new dependencies were installed; Zenity and libnotify were already
present. This is a frontend to the existing managers, not transactional rollback
for package installation. Inspect the transaction log if an update fails.

### OpenCode Go

The OpenCode tab separates aggregate local usage from the official Go usage
endpoint's rolling/weekly/monthly windows and exact reset dates. It reads only
the configured Go API key in memory, sends it over HTTPS to the fixed endpoint,
rejects redirects and caches allowlisted quota fields privately. No browser cookie
extraction is used. Refresh runs only while this tab is visible. Previous quota
windows remain visible but marked stale after a refresh failure.

An initial request received HTTP 403. Repeating with OpenCode's client User-Agent
succeeded. The configured Go key now returns all three windows, including a spent
monthly allowance and its reset date; this is quota exhaustion, not subscription
expiration. Network/entitlement failures still preserve last-good data with a
verification state. Headers and API keys are never printed or committed.

The widget has separate **Connect account**, **Refresh usage** and **Billing /
renewal** actions. Connect implements OpenCode's device authorization flow:
show the user code, open the official verification page, poll until approved,
then refresh usage automatically. It does not merely open a workspace page.
The panel's access/refresh tokens are stored only in
`~/.local/state/sensei-code/opencode-console.json` (0600, parent 0700).
They do not replace CLI providers. Disconnect removes only this panel connection.
Closing the panel cancels an unfinished authorization. The Personal workspace
is preferred; otherwise the first workspace by name follows the CLI's convention.
Connected Console quota uses its `/api/go/status` meters, with the Go API key
endpoint as fallback. These Console routes are upgrade-sensitive; unsupported
responses fail safely. The public device-code endpoint and browser origin were
verified; full browser authorization needs the user's approval and was validated
with disposable fixtures rather than completing someone else's sign-in.

Free-model activity comes from aggregate `message` metadata in the local database,
not transcripts. A model is classified free from an explicit `-free` identity or
the installed catalog's zero input/output prices, never solely from a zero charge.
The panel shows responses, input/output tokens and per-model rows. Catalog-removed
models retain their usage without an invented free/paid classification. A provider
remaining free allowance is not inferred: no supported quota endpoint exposes it
here. Period selectors make recent inactivity distinct from lifetime usage.

The corrected billing button opens `https://opencode.ai/console/` (HTTP 200),
replacing obsolete `/workspace` (404). No billing purchase is automated.

Sources: [Go usage implementation](https://github.com/anomalyco/opencode/blob/dev/packages/console/app/src/routes/zen/go/v1/usage.ts),
[reported entitlement failure](https://github.com/anomalyco/opencode/issues/49020),
[official Console](https://dev.opencode.ai/v2/docs/console/).

Scoped live backups are in
`~/.local/state/dotfiles-backups/desktop-polish-20261011`; Git parent `5c2059d`
retains the prior source. The rebuilt Spotify binary was activated while playback
was paused. Phone-controlled acoustic playback has not been independently tested;
the confirmed restart loop and unbounded startup pause mechanisms were repaired,
and their safety paths were exercised without changing songs on a remote device.
Private screenshots were inspected locally and were not added to the public repo.

## October 11 interaction follow-up

New terminals now own independent numbered `dev_NNN` sessions. App focus never
creates another terminal just because it is already focused; Shift explicitly
creates another. Existing sessions and processes are preserved. See the
[terminal workflow](../terminal-workflow.md) for bindings and primary references.

The update question bridge recognizes default/yes/no/provider/exclusion prompts,
including prompts split across output chunks. The widget shows the latest question,
automatically follows transaction output, and accepts default and text responses.
Authentication releases popup focus for the graphical password dialog. Actual
privileged upgrades were not run for validation: a disposable PTY transaction and
fake password helper exercised output/input and focus release without passwords
or package changes.

Badge artwork is smaller and centered; hover tooltips are removed. The Spotify
separator remains neutral. GPU activity breathes under the shell's existing motion
policy. Brightness shows a proportional filled sun; Bluetooth distinguishes linked
and unlinked states. Tabs have an inset, thin ruled silhouette, app icons, active
color/fill and native arrow navigation. The focused monitor owns workspace selection,
so selecting ScreenPad Misc now updates the rail instead of retaining Terminal.
Old companion projections expire after fifteen minutes without a publisher update;
the vault content and main Noesis window are untouched.

Battery sits beside System on the top bar and anchors its panel there. AC uses a
plug mark and gentle pulse under the existing motion policy; battery mode shows
proportional fill. The panel includes energy, flow, health, design capacity, voltage,
charge ceiling, reported cycles, bounded real samples, available profiles, charge
ceilings and one-shot full charging. Existing 60% policy remains unchanged. System
has a bounded scroll area, keeping long package output and controls reachable.

Validation: 23 desktop regressions and 16 learning regressions; independent concurrent
sessions tested on a disposable tmux socket, persistence after closed sessions,
focus-not-launch behavior, graphical password focus lifecycle, battery unit conversion,
package prompt forms, live clean QML reload and Alacritty config launch. Both displays,
battery panel and tab composition were visually inspected privately. Live repeated
focus actions created no sessions. `dev_001` and `dev_002` have no session group.
Misc reported DP-2/workspace 7/slot 6 through read-only IPC. Charging writes were not
used as tests. Scoped rollback copies are in
`~/.local/state/dotfiles-backups/desktop-followup-20261011`.

### Alignment and glance view

Battery now follows the same folded/expanded control contract as its neighbors:
percentage below the compact icon, or under the Battery label when expanded.
Noesis moved to the lower bar's machine side; drawer handles moved to the
opposite ends. Active workspace rules span the entire icon-and-label area;
the Noesis open-state rule spans its control. Tab counts are vertically centered
and the inset tab outline is visible at a restrained pink intensity.

Code's first tab combines a compact Operator tools banner with the GitHub overview.
Agents remains the next tab. The banner reads existing machine telemetry every
three seconds only while its Code view is open; missing values show unavailable
rather than zero. Contribution-day details are click-driven, without hover tooltips.
The separate operator deck remains available through middle-click. Existing tools
are reused; there is no second stats backend or new dependency.

Checked folded and expanded bars on both displays, the combined Code panel, its
live CPU/RAM values, tab count and outline. Live QML reload succeeds. Rail IPC
`bar-controls-<output>` exposes expand/state for reproducible layout checks.
Follow-up rollback copies: `~/.local/state/dotfiles-backups/desktop-followup-20261011-alignment`.

### Stats-first refinement

The Operator banner is now a read-only glance strip: CPU/load, available memory,
NVIDIA activity, temperature/fan state, AC/battery/profile and uptime/process count.
Network rates, USB boards, simulators and saved clips form a secondary line.
Buttons remain in the separate middle-click operator deck. Labels, values and
context use distinct sizes and spacing; missing telemetry remains unavailable.
The top expansion handle is back on the left edge of its controls. Expanded
Noesis selection follows the actual label width, with secondary text constrained
and elided before its menu handle. Folded selection centers under the icon.
ScreenPad brightness uses a crisp dual-panel mark with a proportional lower-display
fill. Live QML reload and the complete Code composition were visually checked;
backups are in `~/.local/state/dotfiles-backups/operator-stats-20261011`.

### Workspace placement and connected batteries

Initial app placement is maintained in `home/.config/hypr/workspace-apps.lua`:
Terminal (terminal emulators), Web (browsers), Code (editors/IDEs), Study
(Noesis, Obsidian, Notion, Zotero, PDF readers), Sim (simulation/CAD/electronics),
Work (files, communication, office/design), Misc (media and unmatched apps).
Rules apply on opening; manual moves remain intact. Authentication dialogs and
the special terminal deck are excluded. Existing windows are not rearranged.

Two ordinary tiled windows can remain independent. Opening or moving a third
into the workspace groups its eligible windows into native tabs. Floating,
pinned, fullscreen and special-deck windows are excluded. Manual detachment
pauses automatic grouping until another eligible window arrives or grouping is
explicitly resumed. All workspace labels have full underlines, with quieter
inactive colors. Urgent-window events add a pink workspace dot; focusing or
closing the requesting window acknowledges it. The GPU activity dot is removed;
its existing activity breathing remains.

Battery & power combines KDE Connect phone charge, connected BlueZ devices and
UPower peripheral reports. Reports are deduplicated, unavailable charge stays
absent, and disconnected Bluetooth/phone devices disappear. Details opens the
existing phone/device/hardware controls; remote charging controls are not
invented. The peripheral list scrolls within a bounded panel. No new daemon or
package is required. UPower's presence flag only applies to battery packs:
[UPowerDevice contract](https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.UPower/UPowerDevice/).

Validated on this laptop: Code placement with disposable windows, two independent
tiles followed by a three-member automatic group; live phone/headset/keyboard
reports and panel layout; clean Hyprland/QML reload. Regression fixtures cover
routing, unknown/zero battery readings, provider duplication, disconnection and
attention acknowledgement. Urgency was tested as state logic, not by inducing a
real application's attention request. Scoped recovery copies live under
`~/.local/state/dotfiles-backups/workspaces-devices-20261011`.
