#!/usr/bin/env bash
# Rebuild the archived Noctalia Quickshell fork against this machine's Qt.
# The packaged binary remains available; wrayth-shell checks the Qt stamp.
set -euo pipefail

revision=606adedbfea92caba306730edd0f6adba4acf310
source_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sensei-noctalia-qs/source"
build_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sensei-noctalia-qs/build"
prefix="$HOME/.local/opt/sensei-quickshell"
stage="$prefix.staging"
if [ -e "$stage" ]; then
    printf 'Staging directory exists: %s. Inspect it before retrying.\n' "$stage" >&2
    exit 1
fi

if [ ! -d "$source_dir/.git" ]; then
    mkdir -p "$(dirname "$source_dir")"
    git init -q "$source_dir"
    git -C "$source_dir" remote add origin https://github.com/noctalia-dev/noctalia-qs.git
    git -C "$source_dir" fetch --depth 1 origin "$revision"
    git -C "$source_dir" checkout --detach -q FETCH_HEAD
fi
if [ "$(git -C "$source_dir" rev-parse HEAD)" != "$revision" ]; then
    printf 'Unexpected upstream revision; review before rebuilding.\n' >&2
    exit 1
fi

cmake -S "$source_dir" -B "$build_dir" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$stage" \
    -DCRASH_HANDLER=OFF -DUSE_JEMALLOC=ON \
    -DDISTRIBUTOR='Sensei local Qt rebuild'
nice -n 10 ionice -c 3 cmake --build "$build_dir" -j 2
cmake --install "$build_dir"
test -x "$stage/bin/qs"
# Upstream installs qs as an absolute symlink into the staging prefix. Make it
# relative before moving the tree, otherwise the installed command breaks.
ln -sfn quickshell "$stage/bin/qs"
/usr/lib/qt6/bin/qtpaths --query QT_VERSION > "$stage/qt-version"

if [ -e "$prefix" ]; then
    mv "$prefix" "$prefix.previous.$(date +%Y%m%d-%H%M%S)"
fi
mv "$stage" "$prefix"
printf 'Built %s against Qt %s; restart wrayth-shell to use it.\n' \
    "$revision" "$(cat "$prefix/qt-version")"
