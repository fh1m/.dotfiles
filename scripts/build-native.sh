#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
install -d "$HOME/.local/bin" "$HOME/.local/share/sensei-bluetooth"
cc -O2 -Wall "$repo_dir/src/spotify/transport.c" -o "$HOME/.local/bin/sensei-spotify-transport" $(pkg-config --cflags --libs json-c openssl)
cc -O2 -Wall -shared -fPIC "$repo_dir/src/bluetooth/a2dp-buffer.c" -o "$HOME/.local/share/sensei-bluetooth/a2dp-buffer.so" -ldl -lpthread -lbluetooth
printf 'Native bridges built. The Bluetooth workaround stays inactive until explicitly configured.\n'
