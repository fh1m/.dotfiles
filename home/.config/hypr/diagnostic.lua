-- Minimal session to distinguish compositor problems from shell problems.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("/home/fh1m/.local/bin/sensei-terminal"))
hl.bind("SUPER + SHIFT + M", hl.dsp.exit())
hl.on("hyprland.start", function()
    hl.exec_cmd("/home/fh1m/.local/bin/sensei-terminal")
end)
