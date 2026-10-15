#!/usr/bin/env bash
# Local, public-Qt-API workaround for QTBUG-146671; no system libraries replaced.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
build_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sensei-context-guard"
prefix="$HOME/.local/share/sensei-qt-plugins"
cmake -S "$repo_dir/src/qt-context-guard" -B "$build_dir" -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build "$build_dir" -j 2
ctest --test-dir "$build_dir" --output-on-failure
install -d "$prefix/generic"
install -m 0755 "$build_dir/generic/libsensei_context_guard.so" "$prefix/generic/libsensei_context_guard.so.next"
mv "$prefix/generic/libsensei_context_guard.so.next" "$prefix/generic/libsensei_context_guard.so"
/usr/lib/qt6/bin/qtpaths --query QT_VERSION > "$prefix/qt-version.next"
mv "$prefix/qt-version.next" "$prefix/qt-version"
printf 'Context guard installed for Qt %s. Restart the shell to load it.\n' "$(cat "$prefix/qt-version")"
