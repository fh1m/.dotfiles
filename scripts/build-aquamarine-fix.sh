#!/usr/bin/env bash
# Private, version-pinned correction. No root files or installed packages change.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
version=$(pkg-config --modversion aquamarine)
[[ "$version" == 0.15.1 ]] || { echo "This patch is only for Aquamarine 0.15.1; installed: $version" >&2; exit 1; }
source_dir="${SENSEI_AQ_SOURCE:-${XDG_CACHE_HOME:-$HOME/.cache}/sensei-build/aquamarine-0.15.1}"
prefix="$HOME/.local/opt/sensei-aquamarine"
build_prefix="$HOME/.local/opt/sensei-aquamarine-builds/0.15.1-$(date +%Y%m%d-%H%M%S)-$$"
if [[ ! -d "$source_dir/.git" ]]; then
    mkdir -p "$(dirname -- "$source_dir")"
    git clone --depth 1 --branch v0.15.1 https://github.com/hyprwm/aquamarine.git "$source_dir"
fi
[[ $(git -C "$source_dir" rev-parse HEAD) == f31c47a1b9d300847d8fc3108ad959448103dfc1 ]] || { echo 'Unexpected source revision' >&2; exit 1; }
patch="$repo/patches/aquamarine/0.15.1-implicit-dmabuf.patch"
for file in src/backend/drm/DRM.cpp src/backend/drm/Renderer.cpp; do
    if git -C "$source_dir" apply --include="$file" --check "$patch" 2>/dev/null; then
        git -C "$source_dir" apply --include="$file" "$patch"
    else
        git -C "$source_dir" apply --include="$file" --reverse --check "$patch"
    fi
done
cmake -S "$source_dir" -B "$source_dir/build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$build_prefix" -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_TESTING=ON
cmake --build "$source_dir/build" --parallel 2
ctest --test-dir "$source_dir/build" --output-on-failure
cmake --install "$source_dir/build"
pacman -Q aquamarine hyprutils > "$build_prefix/abi-packages.tmp"
mv "$build_prefix/abi-packages.tmp" "$build_prefix/abi-packages"
LD_LIBRARY_PATH="$build_prefix/lib" /usr/bin/Hyprland --version
# Activate only after successful tests/install. Never overwrite a mapped library.
if [[ -d "$prefix" && ! -L "$prefix" ]]; then
    mv "$prefix" "$build_prefix-previous"
fi
ln -s "$build_prefix" "$prefix.next-$$"
mv -Tf "$prefix.next-$$" "$prefix"
printf 'Private build ready. A new compositor session is needed to load it.\n'
