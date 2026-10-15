# Noesis V1 acceptance — updated 2026-10-11

**V1 is not release-complete.** This is the current acceptance report, not a claim
that passing model tests establish learning efficacy. The existing PLAN.md remains
the historical phase ledger. [v1-roadmap.md](v1-roadmap.md) is the current execution
burn-down; [m1-hosting-evidence.md](m1-hosting-evidence.md) records the original staged independent
host checks. The subsequent scoped live deployment and learning-engine evidence
are recorded in [frontier-evidence.md](frontier-evidence.md). The bounded fault, storage-conflict, long-history and portability gates are recorded in [release-hardening.md](release-hardening.md). The real learner trial and remaining desktop/UX acceptance remain release gates; [UX finalization](ux-finalization.md) records the first reviewed implementation slice. [Zotero startup evidence](zotero-startup-evidence.md) records the reproduced and fixed populated restore regression. Configured off-device protection is deferred by the owner to
post-V1; it is not a core release completion gate.

| Milestone | Accepted and reproduced | Status / blocking V1 | Ready for learner use |
|---|---|---|---|
| P0 correctness/recovery | Safe writes, receipts, concurrent source replacement, interrupted link retry; encrypted local restoration and native Sioyek position recovery. | Partial. Populated native Zotero encrypted restoration now passes with the guarded local 10.0.6 compatibility fix. Bounded publication, concurrent retry, forced-termination, interrupted restore and tampered-snapshot cases pass; see release-hardening.md. No automatic pruning protects the sole verified copy. | Core writes yes; reader recovery requires the recorded caveats. |
| P1 identity/ownership | Owner-aware cross-vault search/continuation, global relevance, generation/cache-bound cursors, moved references, duplicate refusal, explicit replacement/fork; native local prerequisite creation. | Native disappearance/return, changed-owner refusal, replacement and independent fork pass. Cross-vault blocking educational gates are deliberately outside V1; nonblocking reusable connections remain supported, with exact owner navigation. | Yes for supported owner-aware navigation and local contextual gates. |
| P2 research | Genuine PDF and populated Zotero annotation revisions; unchanged learner prose; annotation → question/reconstruction → committed authored implementation → executed attention Eq. 1 checks; paper move preserves links. | Partial. Native annotation-specific handoff is validated against the isolated installed 10.0.6 reader; the populated native encrypted restore rerun passes with the guarded compatibility fix. Full trained-Transformer reproduction is outside this product release's acceptance scope. | Import/reading/evidence route yes; exact supported annotation/page navigation verified; historical/deleted annotations use an explicit page fallback. |
| P3 courses | Modules, six lectures, readings, two assignments, project; immutable ordering/material replacement; native prerequisite/assessment/readiness/return; exact place and results survive cache loss/restart. Modules do not inflate consumption. | Connected course fixture accepted. Complete source-reader/outline combination and returning-learner inspection remain partial. | Yes for the accepted course workflow. |
| P4 practice/evidence | Failed, assisted, independent and changed-task transfer histories; reference protection; selected plan distinct from performed assessment; learner criterion decisions. Ctrl+Enter reduces attempt/save friction. | Native 1,001-event pagination and protected returning-learner recovery pass. Controlled-time or early fixture checks do not prove human delayed retention. | Yes for recording honest attempts and explicit checks. |
| P5 experiments | Executed generated-data calibration, code/configuration, CSV/PNG, contradicted prediction, units, comparison, next test; native figure loading/scrolling; unavailable and foreign artifacts tested. | Software experiment slice accepted. Owned drawing, explicit terminal capture and native Obsidian/editor round trips are verified in core-learning-evidence.md; sustained owner use remains open. No hardware or full-paper reproduction claim. | Yes for scoped experiment records and artifacts. |
| P6 desktop | Native lesson/course/paper/Lab fixture states, keyboard actions, restoration, existing window modes/companion; inspected actual native screenshots. Quickshell retained. | Partial. Prior native visual matrix is retained; twenty-cycle and five-minute idle acceptance passes. Adapter-unavailable ScreenPad recovery passes. Physical input timing, hardware unplug and owner review remain. | Ready for local learner trial; not certified across every monitor state. |
| P7 guidance | Completed material excluded from Continue; explained next actions; a gate clears only after explicit lesson-scoped learner readiness and can be reopened. | Native pin/high/quiet dispositions and restart persistence pass; quiet preserves Continue without creating competence events. Sophisticated recommendation models are post-V1. | Basic transparent suggestions yes. |
| P8 hardening | Earlier 107 core + 16 compatibility acceptance remains authoritative; current additions pass 165 core tests and 16 compatibility tests; native evidence is recorded in core-learning-evidence.md. Temporary-home installation; earlier 10k and Distrobox evidence retained; private-data boundaries and native cache-loss restart. | Supported Linux/Distrobox portability, isolated installation/rollback, twenty open/hide cycles and five-minute idle pass. Human trial remains. Independent-host registration and scoped live rollout are verified. Off-device configuration is deferred by owner to post-V1. | Local use yes; laptop-loss protection is not configured. |

## Reproduced learning day

Run `python3 scripts/check-noesis-learning-day.py` on the native desktop. It uses a
separate HOME, synthetic records and authored code, and cleans up its own shell.
Existing NumPy and Matplotlib are acceptance dependencies, not new Noesis services.

Morning resumes a CS NAND reconstruction across vaults. Midday follows the
mathematics lesson, prerequisite, explicit readiness and assignment. Afternoon
opens a real paper's source/implementation contexts and an authored numerical
verification. Evening inspects actual generated measurements and a rendered local
figure. Native restart/cache deletion recover the mathematics context. Original
notes are byte-identical. Specialist PDF and native Zotero API/annotation tests are
separate gates, not silently inferred from this day fixture.

The latest run used 84 non-text key actions and 362 typed characters, including
search and declarations; fixture setup is excluded. Prerequisite assessment and
return used 14 actions versus 17 through menus. Navigation alone takes two.
Context recovery took 0.597 seconds. These are controlled automated observations,
not human task time, a usability study or demonstrated learner competence.

See [native screenshots and test details](validation.md#connected-learning-cycle--2026-10-09).

## Explicit remaining gates

The bounded software hardening matrix is now recorded in [release-hardening.md](release-hardening.md), including native vault recovery, long history, Zed, Zotero version boundaries, local fault injection and Linux portability. Retain the version/hash guard and rollback. Supported Zotero 10.0.5/10.0.6 restore passes; 9.0.6 requires the explicit export fallback.

Remaining observations: owner 20–30-minute learner trial, physical ScreenPad unplug/reconnect, physical input latency and longer-term learning outcomes. Automated lifecycle and adapter-unavailability tests do not substitute for these. Unsupported external tool features use the canonical guide's manual fallback.

Configured off-device protection is deferred by the owner to post-V1. The
[encrypted preservation strategy](migration-recovery.md#off-device-protection-remains-unconfigured)
remains documented; local recovery is not laptop-loss protection.

Post-V1: sophisticated recommendation models, optional MLflow/DVC services,
advanced spaced-repetition integration, external dashboards and global blocking
cross-vault educational policy. No data-safety or honest-history requirement is
silently deferred. No framework rewrite or speculative dependency is needed.

## Practical starting guide

- **Begin a path:** Today → Start something → learning path, then add the material
  and capabilities that matter. Existing vaults stay separate.
- **Follow a course:** Learn → add/import a reviewable outline → module → lesson.
  Save the exact place; use the prerequisite/exercise rows and Alt+Left to return.
- **Read a paper:** Research → import Zotero or save its source → open its specialist
  reader. Preserve questions and interpretation separately from imported annotations.
- **Solve a problem:** Practice → start attempt → reason before revealing → declare
  assistance and outcome → save. Create a distinct retry or changed problem.
- **Record an experiment:** Lab → connect an implementation/run → preserve the
  prediction → execute deliberately → connect data/figures → compare and choose
  the next test. Code execution is not an automatic hypothesis success.
- **Resume:** Today Continue or authorized-vault search opens the owning context.
  Positions, drafts and immutable histories survive restart and index rebuilding.
- **Recover:** Follow migration-recovery.md: restore into a new location, verify,
  then explicitly replace the registered location or fork its identity. Never
  overwrite a running reader database or the only verified recovery copy.


## Learning-engine continuation

The native investigation, formatted reading/reasoning, source-linked failure question,
contextual prerequisite descent and explicit delayed-retention form are implemented.
Actual source/data contracts and tests are described in [frontier-evidence.md](frontier-evidence.md).
Mongla's PID/control journey uses inspected pinned repository source; no vehicle code
was run and no underwater result or owner competence was inferred. Later milestones
remain in scope: genuine detector/DSA/bottom-up journeys, full specialist-tool returns,
safe ScreenPad support pinning, reliability cases and the owner's real learner trial.
Controlled-clock retention is software validation, not human delayed retention.

### Convolution reference slice

The bounded native prediction/manipulation → Git implementation → actual NumPy
comparison → honest changed-case failure → linked question → optional prerequisite
→ exact restart/return journey is implemented. Actual isolated Obsidian and editor
handoffs are exercised; generated figures display in Lab and ScreenPad. This closes
one reference lesson's software journey, not YOLO, DSA, Mongla or the entire P0–P8
release. The populated Zotero restore regression is fixed for the guarded 10.0.6 build; see zotero-startup-evidence.md. Owner learner
understanding, delayed retention and sustained usability require personal testing.
Off-device configuration remains explicitly deferred by owner.

### Dijkstra software slice

The [Dijkstra acceptance](dijkstra-evidence.md) now demonstrates the shared
Practice/Frontier/Git/Lab learning thread in a second domain, with real executions,
assistance-preserving transfer and restart. It does not close P0–P8, certify the
owner's learning, resolve Zotero restoration, or implement YOLO/ADRC. Human
usability and unfamiliar independent transfer remain owner-trial acceptance.
Off-device backup configuration remains explicitly deferred by owner.
