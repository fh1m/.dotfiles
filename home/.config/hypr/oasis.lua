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
    hl.workspace_rule({ workspace = tostring(id), default_name = name, persistent = false,
        monitor = "eDP-1" })
    hl.unbind("SUPER + " .. id)
    hl.unbind("SUPER + SHIFT + " .. id)
    hl.bind("SUPER + " .. id, hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/sensei-displays workspace " .. id))
    hl.bind("SUPER + SHIFT + " .. id, hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/sensei-displays move " .. id))
end

-- Physical halves of the same logical workspaces; never expose these IDs in UI.
for id = 1, 7 do
    hl.workspace_rule({ workspace = tostring(100 + id), default_name = noesis_workspace_names[id] .. " · Lower",
        monitor = "HDMI-A-1", persistent = false })
end

-- Upper USB-C screen is the third half of the same seven logical desktops.
for id = 1, 7 do
    hl.workspace_rule({ workspace = tostring(200 + id), default_name = noesis_workspace_names[id] .. " · Upper",
        monitor = "DP-1", persistent = false })
end

-- ScreenPad is a utility surface, independent of the seven subject groups.
hl.workspace_rule({ workspace = "90", default_name = "Utility", monitor = "DP-2", persistent = true, default = true })
