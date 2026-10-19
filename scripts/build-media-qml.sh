#!/usr/bin/env bash
# Build the small public-API MpvQt adapter, not mpv or Qt themselves.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
build="${XDG_CACHE_HOME:-$HOME/.cache}/sensei-build/media-qml"
target="$HOME/.local/lib/qt6/qml/Sensei/Media"
cmake -S "$repo/integrations/media" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build "$build" --parallel 2
mkdir -p "$target"
for name in libsenseimedia.so libsenseimediaplugin.so qmldir senseimedia.qmltypes; do
 install -m 644 "$build/Sensei/Media/$name" "$target/$name.new"
 mv -f -- "$target/$name.new" "$target/$name"
done
printf 'Installed native media module in %s\n' "$target"
