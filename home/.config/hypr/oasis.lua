-- Noesis integration; sourced by custom-setup.lua. No blur or idle work.
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
