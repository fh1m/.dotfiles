-- Oasis integration; sourced by custom-setup.lua. No blur or idle work.
hl.bind("SUPER + CTRL + O", hl.dsp.exec_cmd("@HOME@/.local/bin/oasis frontier"))
hl.window_rule({
 name = "oasis-neovim-surface",
 match = { class = "^Alacritty$", title = ".* · Neovim$" },
 opacity = 0.94,
 no_blur = true,
})
