-- Noesis integration; sourced by custom-setup.lua. No blur or idle work.
hl.bind("SUPER + CTRL + O", hl.dsp.exec_cmd("@HOME@/.local/bin/noesis window"))
hl.window_rule({
 name = "oasis-neovim-surface",
 match = { class = "^Alacritty$", title = ".* · Neovim$" },
 opacity = 0.94,
 no_blur = true,
})

-- A normal persistent application window, always initially on the main panel.
hl.window_rule({
 name = "noesis-learning-window",
 match = { title = "^Noesis — Learning workspace$" },
 tile = true, no_blur = true,
})
