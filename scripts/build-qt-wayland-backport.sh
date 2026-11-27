#!/usr/bin/env bash
# Build only Qt's Wayland client with QTBUG-141475 corrected. No root/system Qt edits.
# Upstream: qt/qtbase 0d4f9625f6873c82ff463ae77a97b6ec9f81ab4a.
set -euo pipefail

revision=025bdad181de241e81bf853c8a2d7bf3d19261a9
caller=src/plugins/platforms/wayland/qwaylandinputcontext.cpp
caller_sha=afcd291d452636d2ac917061f03029223c3745fc6eb4fbcc1750b4c64f8a7b62
scripts="$(dirname "$(realpath "$0")")"
source_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sensei-qt-wayland-backport/source"
build_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sensei-qt-wayland-backport/build-client-v1"
prefix="$HOME/.local/opt/sensei-qt-wayland"
stage="$prefix.staging"
qt_version="$(/usr/lib/qt6/bin/qtpaths --query QT_VERSION)"
if [ "$qt_version" != 6.12.0 ]; then
    printf 'This reviewed backport targets Qt 6.12.0 only; installed Qt is %s. Do not reuse its private ABI.\n' "$qt_version" >&2
    exit 1
fi
if [ -e "$stage" ]; then
    printf 'Staging directory exists: %s. Inspect it before retrying.\n' "$stage" >&2
    exit 1
fi
qt_libraries=(/usr/lib/libQt6Core.so.6 /usr/lib/libQt6Gui.so.6 /usr/lib/libQt6WaylandClient.so.6)
abi_before="$(sha256sum "${qt_libraries[@]}")"
if [ ! -d "$source_dir/.git" ]; then
    mkdir -p "$(dirname "$source_dir")"
    git init -q "$source_dir"
    git -C "$source_dir" remote add origin https://github.com/qt/qtbase.git
    git -C "$source_dir" sparse-checkout set cmake LICENSES src/plugins/platforms/wayland src/3rdparty/wayland src/tools/qtwaylandscanner
    git -C "$source_dir" fetch --depth 1 origin "$revision"
    git -C "$source_dir" checkout --detach -q FETCH_HEAD
fi
if [ "$(git -C "$source_dir" rev-parse HEAD)" != "$revision" ]; then
    printf 'Unexpected Qt source revision; review before rebuilding.\n' >&2
    exit 1
fi
git -C "$source_dir" diff --cached --quiet
git -C "$source_dir" diff --quiet -- . ":(exclude)$caller"
if [ "$(sha256sum "$source_dir/$caller" | cut -d' ' -f1)" != "$caller_sha" ]; then
    git -C "$source_dir" diff --quiet -- "$caller"
    git -C "$source_dir" apply --check "$scripts/patches/qtbase-textinput-focus.patch"
    git -C "$source_dir" apply "$scripts/patches/qtbase-textinput-focus.patch"
fi
printf '%s  %s\n' "$caller_sha" "$source_dir/$caller" | sha256sum --check --status
# CUDA's /opt/cuda/lib alias can make Qt derive a nonexistent mkspec prefix.
# Resolve this standalone module against the actual system Qt package paths.
cmake -U 'Qt6*_DIR' -U QT_MKSPECS_DIR \
    -S "$scripts/qt-wayland-backport" -B "$build_dir" -G Ninja \
    -DCMAKE_PREFIX_PATH=/usr -DQt6_DIR=/usr/lib/cmake/Qt6 \
    -DCMAKE_BUILD_TYPE=Release -DSENSEI_QT_SOURCE_DIR="$source_dir" \
    -DCMAKE_INSTALL_PREFIX="$stage"
nice -n 15 ionice -c 3 cmake --build "$build_dir" --target WaylandClient -j 2
library="$build_dir/lib/libQt6WaylandClient.so.$qt_version"
python3 - /usr/lib/libQt6WaylandClient.so.6 "$library" <<'PY'
import subprocess
import sys

def exports(path):
    result = subprocess.run(['nm', '-D', '--defined-only', path], check=True, capture_output=True, text=True)
    return {line.split()[-1] for line in result.stdout.splitlines() if len(line.split()) >= 3}

missing = exports(sys.argv[1]) - exports(sys.argv[2])
if missing:
    raise SystemExit('Refusing a client that removes installed ABI exports: ' + ', '.join(sorted(missing)))
dynamic = subprocess.run(['readelf', '-d', sys.argv[2]], check=True, capture_output=True, text=True).stdout
if '(RPATH)' in dynamic or '(RUNPATH)' in dynamic:
    raise SystemExit('Refusing a client with an unexpected runtime search path')
PY
if [ "$abi_before" != "$(sha256sum "${qt_libraries[@]}")" ]; then
    printf 'System Qt changed during the build; refusing to activate mixed inputs.\n' >&2
    exit 1
fi
install -Dm755 "$library" "$stage/lib/libQt6WaylandClient.so.$qt_version"
ln -s "libQt6WaylandClient.so.$qt_version" "$stage/lib/libQt6WaylandClient.so.6"
printf '%s\n' "$qt_version" > "$stage/qt-version"
(cd "$stage" && sha256sum "${qt_libraries[@]}" "lib/libQt6WaylandClient.so.$qt_version" > qt-libraries.sha256)
if [ -e "$prefix" ]; then
    mv "$prefix" "$prefix.previous.$(date +%Y%m%d-%H%M%S)"
fi
mv "$stage" "$prefix"
printf 'Built the scoped Wayland client for Qt %s. Restart only sensei-shell after native validation.\n' "$qt_version"
