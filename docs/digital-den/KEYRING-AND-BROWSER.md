# Chrome loads forever, but the network works

Homie, 2026-10-20: Ethernet, gateway, public-IP traffic, DNS, and HTTPS to
Google, GitHub, YouTube, Spotify and Desktop Commander all passed. Chrome's
normal profile and disposable profiles stayed on blank/loading pages.

The actual blocker was a locked GNOME login keyring. Chrome waits for encrypted
cookie storage. A disposable profile using a basic password store loaded
immediately, identifying the blocked dependency; this diagnostic setting was
never applied to the real profile. Local data URLs also rendered, so the
renderer itself was not generally broken. Early renderer-stall language was
an observation of the wait, not its cause.

The active secret-service daemon uses `/run/user/1000/keyring`. An unlock attempt
without selecting that control directory reached another daemon instance.
Unlocking the active daemon restored Chrome immediately. A subsequent headless
probe with **gnome-libsecret** loaded the real Desktop Commander sign-in page.
The existing profile, cookies, keyring files and encryption were preserved.
Desktop Commander completed device verification and reported Homie online.

## Avoid a second prompt at login

Homie's greetd PAM stack lacked GNOME Keyring hooks. The repair adds only:

```text
auth       optional     pam_gnome_keyring.so
session    optional     pam_gnome_keyring.so auto_start
```

Required/requisite authentication and account rules remain unchanged. The
login password must match the login-keyring password; this match was confirmed
by unlocking the active daemon. Automatic login without entering a password
cannot provide an unlock secret. No password is stored in scripts or dotfiles.

Reproduce on a greetd machine with gnome-keyring installed:

```sh
python3 scripts/setup-keyring-login.py         # preview
sudo python3 scripts/setup-keyring-login.py --apply
```

The script backs up the existing PAM file and is idempotent. It affects future
logins; no current session, display manager or browser is restarted by setup.
Undo by restoring the specific `/etc/pam.d/greetd.before-keyring-*` backup.

Check without reading any saved secret:

```sh
busctl --user get-property org.freedesktop.secrets \
  /org/freedesktop/secrets/collection/login \
  org.freedesktop.Secret.Collection Locked
```

Expected after password login: `b false`. Next-login automatic unlocking remains
a physical acceptance step; the current session was unlocked and verified.
Do not delete a keyring, clear a browser profile, disable the browser sandbox,
or permanently switch to basic/plaintext password storage to fix this symptom.

References: [GNOME PAM integration](https://wiki.gnome.org/Projects/GnomeKeyring/Pam),
[Arch's greetd/keyring configuration](https://wiki.archlinux.org/title/GNOME/Keyring).
