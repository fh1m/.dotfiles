-- Personal setup layered on top of Wrayth.
-- Wrayth keeps ownership of its launcher, deck, lock, power, workspace-number,
-- volume, and brightness shortcuts.

local mod = "SUPER"
local terminal = "/home/fh1m/.local/bin/sensei-terminal"

-- Single NVIDIA desktop; monitor mode is separately validated before persistence.
local workspace_names = { "Terminal", "Web", "Code", "Sim", "Work", "Misc" }
for id, name in ipairs(workspace_names) do
    hl.workspace_rule({ workspace = tostring(id), default_name = name, persistent = true })
end

-- Keep the motion, but do not spend GPU render time on blur or shadows.
hl.config({
    animations = { enabled = true },
    decoration = { blur = { enabled = true, size = 6, passes = 2, new_optimizations = true }, shadow = { enabled = true, range = 18, render_power = 3, color = "rgba(00000066)" } }, general = { border_size = 2 }, input = { touchpad = { natural_scroll = true }, follow_mouse = 0 },
    group = {
        auto_group = false,
        drag_into_group = 1,
        merge_groups_on_drag = true,
        merge_groups_on_groupbar = true,
        col = { border_active = "rgba(f23d70ff)", border_inactive = "rgba(39342fff)", border_locked_active = "rgba(f23d70ff)", border_locked_inactive = "rgba(39342fff)" },
        groupbar = {
            enabled = true,
            blur = false,
            gradients = true,
            render_titles = false,
            font_family = "JetBrainsMono Nerd Font Propo",
            font_size = 12,
            font_weight_active = 700,
            font_weight_inactive = 600,
            height = 30,
            gaps_out = 0,
            indicator_height = 0,
            indicator_gap = 0,
            rounding = 20,
            rounding_power = 1.0,
            round_only_edges = true,
            gradient_rounding = 20,
            gradient_rounding_power = 1.0,
            gradient_round_only_edges = true,
            text_padding = 18,
            text_color = "rgba(e8e2daff)",
            text_color_inactive = "rgba(77716aff)",
            col = { active = "rgba(09080700)", inactive = "rgba(09080700)", locked_active = "rgba(09080700)", locked_inactive = "rgba(09080700)" },
        },
    },
})

-- These group border keys need their full dotted names in Hyprland's Lua API.
hl.config({ ["group.col.border_active"] = "rgba(f23d70ff)", ["group.col.border_inactive"] = "rgba(39342fff)", ["group.col.border_locked_active"] = "rgba(f23d70ff)", ["group.col.border_locked_inactive"] = "rgba(39342fff)" })

-- Native Hyprland tabs: drag a window onto a group, or use the keys below.
-- Group titles and the two-pixel active marker provide a visible focus cue.
hl.bind("SUPER + ALT + G", hl.dsp.group.toggle())
hl.bind("SUPER + ALT + H", hl.dsp.window.move({ into_group = "l" }))
hl.bind("SUPER + ALT + L", hl.dsp.window.move({ into_group = "r" }))
hl.bind("SUPER + ALT + J", hl.dsp.group.next())
hl.bind("SUPER + ALT + K", hl.dsp.group.prev())
hl.bind("SUPER + ALT + U", hl.dsp.window.move({ out_of_group = true }))


hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_CURSOR_SIZE", "24")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("TERMINAL", "/home/fh1m/.local/bin/sensei-terminal")
hl.env("PATH", os.getenv("HOME") .. "/.local/bin:" .. (os.getenv("PATH") or "/usr/local/bin:/usr/bin"))
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind("ALT + RETURN", hl.dsp.exec_cmd("/home/fh1m/.local/bin/sensei-terminal"))
hl.bind("ALT + W", hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind("ALT + F", hl.dsp.exec_cmd("nautilus"))
hl.bind(mod .. " + W", hl.dsp.exec_cmd("qs -c wrayth ipc call picker toggle"))
hl.bind(mod .. " + A", hl.dsp.exec_cmd("qs -c wrayth ipc call switcher overview"))
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("slurp | xargs -I{} grim -g {} - | tesseract stdin stdout | wl-copy"))
hl.bind(mod .. " + Y", hl.dsp.window.pin())
hl.unbind("CTRL + SPACE")
hl.bind("CTRL + SPACE", hl.dsp.exec_cmd("qs -c wrayth ipc call spotify action toggle"))
hl.bind("ALT + TAB", hl.dsp.exec_cmd("qs -c wrayth ipc call switcher cycle apps 1"))
hl.bind("ALT + SHIFT + TAB", hl.dsp.exec_cmd("qs -c wrayth ipc call switcher cycle apps -1"))

hl.bind(mod .. " + SHIFT + G", function()
    hl.config({ general = { gaps_out = 5, gaps_in = 3 } })
end)
hl.bind(mod .. " + G", function()
    hl.config({ general = { gaps_out = 0, gaps_in = 0 } })
end)

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd DISPLAY XAUTHORITY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE; systemctl --user restart clipboard-vault.service; gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
end)

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind(mod .. " + MINUS", hl.dsp.window.move({ workspace = "special:special" }))
hl.bind(mod .. " + EQUAL", hl.dsp.workspace.toggle_special("special"))
hl.bind(mod .. " + F1", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(mod .. " + ALT + SHIFT + F1", hl.dsp.window.move({ workspace = "special:scratchpad" }))

hl.window_rule({
    name = "personal-floating-dialogs",
    match = {
        class = "^(org.pulseaudio.pavucontrol|blueman-manager|zenity)$",
    },
    float = true,
})

hl.window_rule({
    name = "personal-opacity",
    match = {
        class = "^(thunar|nemo|discord|armcord|webcord)$",
    },
    opacity = 0.95,
})

hl.window_rule({
    name = "personal-browser-no-blur",
    match = { class = "^org.mozilla.firefox$" },
    no_blur = true,
})

-- Fast captures and an accessible shortcut reference.
for _, key in ipairs({ "Print", "SHIFT + Print", "ALT + Print", "CTRL + Print", "SUPER + Print", "SUPER + SHIFT + Print", "SUPER + F2" }) do hl.unbind(key) end
local capture = os.getenv("HOME") .. "/.local/bin/desktop-capture "
hl.bind("Print", hl.dsp.exec_cmd(capture .. "screenshot area"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(capture .. "screenshot output"))
hl.bind("ALT + Print", hl.dsp.exec_cmd(capture .. "screenshot active"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd(capture .. "screenshot screen"))
hl.bind("SUPER + Print", hl.dsp.exec_cmd(capture .. "record output"))
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd(capture .. "record area"))
hl.bind("SUPER + F2", hl.dsp.exec_cmd("qs -c wrayth ipc call shortcuts toggle"))
-- US keyboard: Shift+/ prints ?, so this is Ctrl+Shift+?.
hl.unbind("CTRL + SHIFT + slash")
hl.bind("CTRL + SHIFT + slash", hl.dsp.exec_cmd("qs -c wrayth ipc call shortcuts toggle"))

-- Six regular workspaces; remove the copied extra numeric shortcuts.
for _, key in ipairs({ "7", "8", "9", "0" }) do
    hl.unbind("SUPER + " .. key)
    hl.unbind("SUPER + SHIFT + " .. key)
end

-- Desktop function shortcuts leave ordinary F1-F12 available to apps.
hl.bind("SUPER + F3", hl.dsp.exec_cmd("qs -c wrayth ipc call system page 0"))
hl.bind("SUPER + F4", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("SUPER + F9", hl.dsp.exec_cmd("qs -c wrayth ipc call idle hold toggle"))
hl.bind("SUPER + F11", hl.dsp.exec_cmd(capture .. "record output"))
hl.bind("SUPER + F12", hl.dsp.exec_cmd("qs -c wrayth ipc call system page 2"))

-- Persistent clipboard archive and desktop tools.
hl.unbind("SUPER + SHIFT + V")
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("qs -c wrayth ipc call dropdown open clipboard"))
hl.unbind("SUPER + SHIFT + M")
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("qs -c wrayth ipc call dropdown open monitor"))

-- Image chooser is a normal floating window, independent of layer popup focus.
hl.window_rule({ name = "sensei-image-chooser", match = { class = "zenity" }, float = true, center = true })

-- Preview without changing application focus until a selection is committed.
hl.bind("SUPER + Tab", hl.dsp.exec_cmd("qs -c wrayth ipc call switcher cycle workspaces 1"))
hl.bind("SUPER + SHIFT + Tab", hl.dsp.exec_cmd("qs -c wrayth ipc call switcher cycle workspaces -1"))
hl.bind("ALT + grave", hl.dsp.exec_cmd("qs -c wrayth ipc call switcher cycle same 1"))
hl.bind("ALT + SHIFT + grave", hl.dsp.exec_cmd("qs -c wrayth ipc call switcher cycle same -1"))

-- Keep the former hot surfaces explicit even if another theme enables blur.
hl.layer_rule({ name = "sensei-bar-render-headroom", match = { namespace = "^wrayth-bar$" }, blur = true })
-- Native image/calendar choosers stay above ordinary apps.
hl.window_rule({ name = "sensei-native-chooser", match = { class = "^(zenity|org\\.gnome\\.Zenity)$" }, float = true, center = true })
-- Smooth geometry transitions; whole-application opacity fades are disabled.
hl.curve("senseiGlide", { type = "bezier", points = {{0.25, 0.0}, {0.20, 1.0}} })
hl.curve("senseiSettle", { type = "bezier", points = {{0.22, 0.0}, {0.18, 1.0}} })
hl.animation({ leaf = "windows", enabled = true, speed = 4.0, bezier = "senseiGlide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.0, bezier = "senseiSettle", style = "popin 94%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.4, bezier = "senseiGlide", style = "popin" })
hl.animation({ leaf = "fadeIn", enabled = false, speed = 4.0, bezier = "senseiGlide" })
hl.animation({ leaf = "fadeOut", enabled = false, speed = 3.4, bezier = "senseiGlide" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.0, bezier = "senseiSettle" })
for _, leaf in ipairs({"workspaces", "workspacesIn", "workspacesOut"}) do
    hl.animation({ leaf = leaf, enabled = true, speed = 3.4, bezier = "senseiGlide", style = "slide" })
end
hl.layer_rule({ name = "sensei-popup-single-motion", match = { namespace = "^wrayth-popup$" }, no_anim = true })
hl.layer_rule({ name = "sensei-navigation-stable", match = { namespace = "^sensei-navigation$" }, blur = true, no_anim = true })

-- Keep application opacity steady when focus changes during workspace motion.
hl.animation({ leaf = "fadeSwitch", enabled = false, speed = 1, bezier = "senseiGlide" })

-- Sensei: focus an existing app across workspaces; Shift explicitly opens another.
local app_helper = os.getenv("HOME") .. "/.local/bin/sensei-app "
for _, spec in ipairs({
    {"SUPER + RETURN", "terminal"}, {"ALT + RETURN", "terminal"},
    {"SUPER + Q", "terminal"}, {"ALT + W", "web"}, {"ALT + F", "files"},
    {"SUPER + P", "calculator"}, {"XF86Calculator", "calculator"},
}) do
    hl.unbind(spec[1]); hl.unbind("SHIFT + " .. spec[1])
    hl.bind(spec[1], hl.dsp.exec_cmd(app_helper .. spec[2] .. " focus-or-launch"))
    hl.bind("SHIFT + " .. spec[1], hl.dsp.exec_cmd(app_helper .. spec[2] .. " new-window"))
end
hl.unbind("SUPER + CTRL + P")
hl.bind("SUPER + CTRL + P", hl.dsp.exec_cmd("qs -c wrayth ipc call power toggle"))

-- Global soundtrack controls, independent of the focused application.
for _, spec in ipairs({{"LEFT", "previous"}, {"RIGHT", "next"}, {"UP", "volume-up"}, {"DOWN", "volume-down"}}) do
    hl.unbind("CTRL + " .. spec[1])
    hl.bind("CTRL + " .. spec[1], hl.dsp.exec_cmd("qs -c wrayth ipc call spotify action " .. spec[2]))
end

-- Popup content owns its motion; keep its compositor surface free of blur.
hl.layer_rule({ name = "sensei-popup-soft-reveal", match = { namespace = "^wrayth-popup$" }, blur = true, no_anim = true })

-- Give the display renderer better scheduling; allow scanout where eligible.

-- Verified LG Full HD desktop mode; generic monitors retain preferred mode.
hl.monitor({output="DP-3",mode="1920x1080@74.97",position="0x0",scale=1,transform=3})

-- Den input: genuine Deskflow portal shortcuts; independent local stop.
hl.bind("CTRL + ALT + F11", hl.dsp.global("org.deskflow.deskflow:deskflow-hotkey-00000006-0000efc8"), { allow_input_capture = true })
hl.bind("CTRL + ALT + F12", hl.dsp.global("org.deskflow.deskflow:deskflow-hotkey-00000006-0000efc9"), { allow_input_capture = true })
hl.bind("CTRL + ALT + PAUSE", function()
    hl.dispatch(hl.dsp.release_input_capture())
    hl.dispatch(hl.dsp.exec_cmd("/home/fh1m/.local/bin/sensei-den-input stop"))
end, { allow_input_capture = true })
