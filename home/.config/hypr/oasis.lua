-- Noesis integration; sourced by custom-setup.lua. No blur or idle work.
-- Scoped live reapplication must not duplicate shortcut handlers.
hl.unbind("SUPER + CTRL + O")
hl.unbind("SUPER + 7")
hl.unbind("SUPER + SHIFT + 7")
hl.bind("SUPER + CTRL + O", hl.dsp.exec_cmd("@HOME@/.local/bin/noesis window"))
hl.window_rule({
 name = "oasis-neovim-surface",
 match = { class = "^Alacritty$", title = ".* · Neovim$" },
 opacity = 0.94,
 no_blur = true,
})

-- Placement is chosen by Noesis; existing specialist windows retain their workspaces.
hl.window_rule({
 name = "noesis-learning-window",
 match = { class = "^org.fh1m.Noesis$" },
 tile = true, no_blur = true,
})

-- Study is shown between Code and Sim; existing workspace IDs stay stable.
hl.workspace_rule({ workspace = "7", default_name = "Study", persistent = true, monitor = "eDP-1" })
hl.bind("SUPER + 7", hl.dsp.focus({ workspace = "7" }))
hl.bind("SUPER + SHIFT + 7", hl.dsp.window.move({ workspace = "7" }))
