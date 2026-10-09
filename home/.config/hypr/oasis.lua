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

-- Sequential workspaces, applied after custom-setup's earlier defaults.
local noesis_workspace_names = { "Terminal", "Web", "Code", "Study", "Sim", "Work", "Misc" }
for id, name in ipairs(noesis_workspace_names) do
    hl.workspace_rule({ workspace = tostring(id), default_name = name, persistent = true,
        monitor = id == 7 and "DP-2" or "eDP-1", default = id == 1 or id == 7 })
    hl.unbind("SUPER + " .. id)
    hl.unbind("SUPER + SHIFT + " .. id)
    hl.bind("SUPER + " .. id, hl.dsp.focus({ workspace = tostring(id) }))
    hl.bind("SUPER + SHIFT + " .. id, hl.dsp.window.move({ workspace = tostring(id) }))
end
