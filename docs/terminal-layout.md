# Terminal status layout

Tmux uses two bottom rows: a blank spacer, then the clickable session/window rail. The former default `P:` pane-list row was unintended and is removed.

`home/.config/tmux/sensei-layout.conf` owns row layout. `.tmux.conf` sources it after the generated color theme, so palette regeneration cannot restore the default second row. Colors and window labels still come from the existing theme/template.

Apply a layout change to existing clients without closing their sessions:

```sh
tmux source-file ~/.config/tmux/sensei-layout.conf
tmux refresh-client -S
```

Live status-option readback and a screenshot verified the blank first row, styled second row and absence of the default pane-list text. Existing tmux clients and sessions were retained.
