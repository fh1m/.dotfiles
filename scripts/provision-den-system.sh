#!/usr/bin/env bash
# Explicit root-only preparation; no disk, boot, desktop or driver changes.
set -euo pipefail
if [[ $EUID -ne 0 ]]; then printf 'Run this reviewed script through sudo.\n' >&2; exit 1; fi
case ${1:-} in
  homie)
    [[ $(hostname -s) == homie ]] || exit 2
    systemctl enable --now tailscaled
    tailscale set --operator=fh1m
    # NetworkManager already uses systemd-resolved. Use its supported stub path
    # so Tailscale can configure split DNS without replacing a foreign file.
    if [[ -f /run/systemd/resolve/stub-resolv.conf && ! -L /etc/resolv.conf ]]; then
      cp -a /etc/resolv.conf "/etc/resolv.conf.den-backup-$(date +%Y%m%dT%H%M%S)"
      ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    fi
    ufw allow in from 192.168.0.0/24 to any port 22000 proto tcp comment 'Den pinned Syncthing peers'
    ufw allow in on tailscale0 from 100.64.0.0/10 to any port 22 proto tcp comment 'Den private SSH'
    # Sunshine is installed but deliberately not enabled at login.
    pacman -S --needed --noconfirm sunshine
    ;;
  arete)
    [[ $(hostname -s) == arete ]] || exit 2
    tailscale set --operator=fh1m
    python3 "$(dirname "$0")/provision-den-firewall.py" --apply
    if [[ -f /run/systemd/resolve/stub-resolv.conf && ! -L /etc/resolv.conf ]]; then
      cp -a /etc/resolv.conf "/etc/resolv.conf.den-backup-$(date +%Y%m%dT%H%M%S)"
      ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    fi
    pacman -S --needed --noconfirm moonlight-qt
    ;;
  *) printf 'Expected explicit host: homie or arete\n' >&2; exit 2;;
esac
