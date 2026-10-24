# Noesis: the planning control centre

Built 23–24 October 2026. The private workspace is the management surface; local Noesis/Obsidian remains the place for handwriting, reasoning and durable learning evidence. There are no private workspace IDs, credentials, marks or learner notes in this document.

## What changed

The old landing page has been replaced by dedicated Today, University, Learn, Research, Practice, Projects & Lab, Library, Life & Opportunities, Review & Reflect and Control Room workspaces. Fourteen focused subpages handle courses, assessments, attendance, degree advising, administration, online-course units, prerequisite repair, paper reading, reproductions, experiments, applications, weekly review and system operation.

The interface uses actual linked Notion database views, including boards, galleries, calendars, filtered tables and a single workload chart. Nine original imagegen covers and eleven small custom magenta glyphs form one visual family. Every workspace page has an appropriate cover. A native task-capture button sits on Today. A standalone focus instrument was also prototyped, but the Notion attachment renderer showed a blank frame during visual acceptance, so it was removed from Today. Its reusable HTML remains in the asset directory; it is not counted as a functioning deployed widget.

## Records and ownership

| Source | Purpose |
|---|---|
| Goals/Paths | Capability-oriented plans; academic and exploratory |
| Terms | Actual trimester planning contexts |
| Course Enrollments | Sections, instructor, syllabus, notebook and explicit enrollment state |
| Tasks | One action ledger; Context distinguishes university, learning, research, projects, administration and life |
| Schedule | Classes, deadlines, exams, personal commitments and chosen work blocks |
| Resource Records | Sources, chapters and lectures; why, exact position, next action and separate reproduction state |
| Project Records | Outcomes, next actions, code repositories and evidence |
| Problem Records | Current blocker, source, retry and learner-confirmed summary state |
| Session Records | Separate dated attempts, reading, experiments, derivations and retrieval; assistance and outcome remain explicit |
| Assessment Records | Official weight, maximum, observed score, submission state and evidence |
| Attendance Records | Actual sessions, including unknown, cancelled and excused |
| Opportunity Records | Scholarships, internships, competitions and applications |
| Curriculum Catalogue | 122 published UIU catalogue entries, not registered courses |

The original five collection identities and sync-owned property names were retained underneath the new interface to avoid breaking desktop bindings or losing records. All canonical databases now live under Control Room → Data Sources. User-facing work happens in linked views. A record is edited once and appears in the appropriate workspaces.

Resource completion, assessment results, study activity, assisted success, independent performance and delayed retention remain distinct. Session history is append-only by workflow convention; Notion's normal editing controls do not enforce immutable storage. Grade Contribution is earned percentage points for a single assessment, not a final grade or CGPA. An explicit Score recorded checkbox distinguishes zero from unknown. Do not sum scores across courses.

## UIU information

The selected source snapshot is the official BSCSE course plan effective Summer 2026 onward. It includes 122 distinct catalogue codes; these include elective alternatives, so adding all catalogue credits does not calculate the 141-credit degree requirement. Four published discrepancies remain flagged. Actual enrollments, marks, waivers, timetable and attendance remain unknown until entered with evidence.

Only source-supported institutional dates were seeded: the October 24–26 new-student advising/registration window and October 27 class start. One planned check action asks the learner to confirm registered sections. Nothing asserts that registration or a particular course has been completed.

## Desktop client and fonts

`sensei-notion` configures a local styling layer for the installed `notion-app-electron` application with Iosevka and a Zed Mono fallback. It preserves the installed app, its user-data directory, sandbox and authentication. It does not modify the package archive, copy credentials, expose a debugging port or inject into external sign-in providers. The installed package version is used for compatibility checks. Styling is restricted to Notion HTTPS/custom-protocol origins and the installed application's own bundled file resources. Ordinary Notion browser/mobile clients retain native font choices; Mono is the portable page fallback. Wide layouts were set through Notion's UI. The browser appearance is visually verified; this pass did not obtain a typography receipt from a fully loaded authenticated desktop-client window, so do not describe the custom desktop font as visually verified.

The launcher gives the client a separate systemd application scope with MemoryHigh=1536M, MemoryMax=3G and MemorySwapMax=1G when a user bus is available. `NOESIS_NOTION_THEME=0 sensei-notion` bypasses the local theme; `/usr/bin/notion-app` is the original launcher. The generic dotfiles installer deploys the local files. No separate background theme daemon is introduced.

## Recovery and connection limits

A private before-state backup and a created-record/cover manifest are stored under `~/.local/state/noesis-notion-redesign/2026-10-23/`, mode restricted to the user. Public covers use immutable Git commit URLs; private records are never published with them.

The Notion chat connector is authenticated. Unattended desktop synchronization still requires its own scoped Notion connection token in Noesis → Plan → Connection; app sign-in does not provide that token. No claim of continuous two-way desktop sync is made here. Preserve collection IDs and the original adapter-owned properties when extending this interface.

Notion export cannot recreate all database relations and is not the only backup. Keep private local learning backups and export planning records periodically. Do not upload grades, transcripts or credentials to the public dotfiles repository.

## File chooser

Chrome's terminal file chooser was selected by explicit `FileChooser=kitty` portal overrides. Hyprland and GNOME overrides now route only FileChooser to KDE, with GTK fallback. Hyprland screencasting/screenshot and secret-service routing stay intact. KDE's chooser enables previews, inline thumbnails and detailed navigation, using the existing Qt6 theme. The portal is on demand; installing its dependencies does not launch the Plasma desktop.

Rollback: restore the private portal backup, or change FileChooser back, then restart the user portal. Remove the local Notion desktop override to restore the packaged launcher. Remove the theme files if no longer wanted. Content and collections do not depend on the CSS.

## Validation boundary

Verified via connector readback: 25 covered workspace pages; 45 linked management views plus 13 canonical collections; all malformed literal colour instructions removed; 122 unique catalogue codes; four discrepancies; native view filters and chart configuration; institutional calendar entries; stable original record identities. The task-capture button created exactly one page in the shared task source; that record was retained as the real pending desktop-connection setup action. The custom HTML focus embed failed visual acceptance and was removed. The local theme tests cover package-version preservation and strict origin matching. Native Mono selection and cover appearance were inspected in Chrome; the custom desktop font layer needs an authenticated loaded Notion window before a runtime typography receipt can be observed.

The KDE file portal accepted an OpenFile request using the cover directory. Preview, inline-thumbnail and detail-view preferences persisted after the dialog closed. Reapply these without overwriting other KDE preferences with `python3 scripts/setup-file-previews.py --apply` after installing the package manifest. Its dry run is the default.

Validation commands: `python3 -m unittest discover -s tests -p test_noesis_planning.py`; `node scripts/test-notion-theme.cjs`; `shellcheck home/.local/bin/sensei-notion`; `git diff --check`.

The October 23 logout was explicitly recorded as systemd-oomd killing the desktop session after RAM and swap exceeded 90%, not a compositor coredump. Seven orphaned ROS nodes were terminated while leaving the current launch intact. The existing development container was bounded at 4 GiB RAM, 6 GiB RAM+swap and six CPUs, with its previous settings backed up. Container recreation must carry those limits forward; this is not proof that every possible memory-pressure failure is permanently eliminated. Do not disable the OOM safeguards or claim a graphics driver repair from this evidence.
