#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
export CARGO_BUILD_JOBS="${CARGO_BUILD_JOBS:-2}"
cargo build --locked --release --manifest-path "$repo_dir/vendor/spotify-player/Cargo.toml" --no-default-features --features daemon,pulseaudio-backend,media-control
install -d "$HOME/.local/share/sensei-spotify-client/bin"
install -m755 "$repo_dir/vendor/spotify-player/target/release/spotify_player" "$HOME/.local/share/sensei-spotify-client/bin/spotify_player"
printf 'Player built. Configure your Spotify client ID, then run sensei-spotify-login.\n'
