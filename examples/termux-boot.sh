#!/data/data/com.termux/files/usr/bin/sh
# Save as ~/.termux/boot/40-sensei-services on the PHONE; open Termux:Boot once.
pgrep -x sshd >/dev/null || sshd
pgrep -x syncthing >/dev/null || GOMAXPROCS=2 syncthing serve --no-browser --no-restart --gui-address=127.0.0.1:8384 >> "$HOME/.syncthing-boot.log" 2>&1 &
# No unconditional wake lock. Android may still defer work while asleep.
