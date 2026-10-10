# Zotero 10.0.6 startup and restoration fix

The installed native application now passes the populated encrypted restore harness. This closes the reproduced startup regression for this inspected application build; it does not certify every reader-navigation or recovery fault case.

## Reproduced cause

The unchanged-data and restored populated profiles contained the expected creator and item-creator rows. SQLite integrity and foreign-key checks passed. With Zotero's documented `-ZoteroDebugText` startup diagnostics, an early local API request called `library.waitForDataLoad()` before the asynchronous creator-cache initialization completed. Item loading raised `Creator 1 not found`; subsequent requests waited on that unsuccessful library load. Increasing timeouts would not repair initialization order.

Diagnostics retained locally under `/var/tmp/noesis-zotero-acceptance-6csml5g0` and `/var/tmp/noesis-zotero-acceptance-ekdrtr12`. These are disposable generated libraries, not personal profiles. The diagnostic flag is documented in [Zotero's debug-output guide](https://www.zotero.org/support/debug_output).

## Small compatibility change

The base `_initInternal()` in `chrome/content/zotero/xpcom/server/server_localAPI.js` now awaits `Zotero.initializationPromise` before accessing a library. No database, profile preference, attachment or personal annotation was modified. Noesis continues to import through read-only GET requests.

`scripts/patch-zotero-startup.py` defaults to dry run, pins the inspected entry SHA-256 and application version, refuses to patch a running installation, saves the original archive, and supports hash-guarded rollback. It refuses unfamiliar vendor source. This is a local compatibility patch, not an official upstream release; vendor updates require revalidation.

The staged application passed the populated native encrypted-restoration harness at `/var/tmp/noesis-zotero-acceptance-qetz63bo`. The installed application then independently passed the same harness at `/var/tmp/noesis-zotero-acceptance-6u8ju2eh`: genuine PDF, native annotation edits/deletion, three retained projections, stable resource identity, unchanged learner prose, moved relationships, executed attention-equation checks and restored annotation/page label/question/PDF bytes.

Installed original archive SHA-256: `7dcb175dfbab43729548ee3357c121825a646929ba3cf12fbcf41a29a0753447`.
Installed patched archive SHA-256: `f9faef833beb52e0c60af6fa2adbc86994d3a2574c87e19c9638e5b5c8676375`.
Local rollback manifest: `/home/fh1m/.local/state/noesis-zotero-compat/20261010-200132-151808/manifest.json`.

A separate disposable application-copy check passed dry run, application, idempotence and byte-exact rollback. The personal Zotero session was never killed or reused.

## Import improvement and remaining gates

Minimal managed vaults need no legacy `types` map: bibliography imports now use the supported `Notes` fallback. Source-supplied ISO dates and publication names are retained without invented metadata. The empty-vault native bibliography journey is separate from PDF attachment/annotation-specific navigation.

Native annotation selection and precise page return remain acceptance gates. The broader interruption/storage/fault matrix and real learner trial also remain open. Local restoration success is not off-device protection; off-device configuration is deferred by the owner. Code execution is not demonstrated learner understanding.

## Actual personal-profile connection

The personal profile had the local API disabled by the vendor default. While Zotero was closed, only that preference was enabled, with a private preference backup at `/home/fh1m/.local/state/noesis-zotero-compat/local-api-20261010-201902/manifest.json`. The installed native application then started successfully and both root API and populated-item GET requests passed. No personal library writes were performed. Zotero was left open for the owner. Enabling the local API does not authorize Noesis to write bibliography data; its adapter remains GET-only.
