#!/usr/bin/env bash
# Optional fallback for an adapter that does not pass DDC/CI. Builds the small
# upstream gamma relay; no compositor patches or full-screen dimming surfaces.
set -euo pipefail
revision=9874e4a273a01f60e578a896183d67aa7a23572c
source_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sensei-build/wl-gammarelay-rs"
if [ ! -d "$source_dir/.git" ]; then
 git clone https://github.com/MaxVerevkin/wl-gammarelay-rs.git "$source_dir"
fi
git -C "$source_dir" fetch origin "$revision"
git -C "$source_dir" checkout --detach "$revision"
cargo install --path "$source_dir" --locked --jobs 2 --root "$HOME/.local"
printf 'Gamma relay built. Install dotfiles, then enable sensei-display-dimming.service only on a machine that needs it.\n'
