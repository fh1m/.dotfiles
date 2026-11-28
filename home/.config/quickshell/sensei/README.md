# Digital Den shell

The active Quickshell config is `sensei`. Shared code lives here; the desktop-specific overlay is under `profiles/pc/home/` in the repository. Use the repository’s `scripts/install.py` with the appropriate hardware profile. See the [installation guide](../../../../docs/installation.md) and [Digital Den guide](../../../../docs/digital-den/README.md).

A display uses its saved wallpaper selection. External displays follow their host’s primary display. An unconfigured display uses the neutral desktop surface rather than bundled artwork. The profile editor can generate an original signal-field wallpaper locally. Installing does not overwrite existing wallpaper preferences; retired stock files are identified by digest and moved to the installation backup.

The clipboard opens on its saved filter and loads history without requiring a tab change. The Network panel shows host traffic and interface state first; link tests and DNS run on demand. Select Technical details for the raw route, resolver and socket snapshot.

See [Credits and provenance](../../../../THIRD_PARTY.md) for the original shell and license notices.
