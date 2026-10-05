-- Personal setup layered on top of Wrayth.
-- Wrayth keeps ownership of its launcher, deck, lock, power, workspace-number,
-- volume, and brightness shortcuts.

local mod = "SUPER"
local terminal = "/home/fh1m/.local/bin/sensei-terminal"

-- Preserve the original monitor arrangement and session environment.
hl.monitor({
    output = "eDP-1",
    mode = "preferred",
    position = "0x0",
    scale = 2,
})
hl.monitor({
    output = "DP-2",
    mode = "3840x1100@60.02",
    position = "0x1080",
    scale = 2,
})

-- UX581GV: a predictable starting workspace on each built-in panel.
hl.workspace_rule({ workspace = "1", monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "6", monitor = "DP-2", default = true })

-- Original GNOME workspace names, with numeric IDs retained for shortcuts.
local workspace_names = { "Terminal", "Web", "Code", "Sim", "Work", "Misc" }
for id, name in ipairs(workspace_names) do
    hl.workspace_rule({ workspace = tostring(id), default_name = name, persistent = true, monitor = id == 6 and "DP-2" or "eDP-1" })
end

-- Keep the motion, but do not spend Intel render time on blur or shadows.
hl.config({
    animations = { enabled = true },
    decoration = { blur = { enabled = false }, shadow = { enabled = false } }, general = { border_size = 2 }, input = { touchpad = { natural_scroll = true }, follow_mouse = 0 },
    group = {
        auto_group = false,
        drag_into_group = 1,
        merge_groups_on_drag = true,
        merge_groups_on_groupbar = true,
        groupbar = {
            enabled = true,
            blur = false,
            gradients = false,
            font_family = "JetBrainsMono Nerd Font Propo",
            font_size = 11,
            font_weight_active = 600,
            font_weight_inactive = 400,
            height = 23,
            indicator_height = 2,
            text_padding = 9,
            text_color = "rgba(eeeeeeff)",
            text_color_inactive = "rgba(999999ff)",
            col = { active = "rgba(111114ff)", inactive = "rgba(08080aff)", locked_active = "rgba(191219ff)", locked_inactive = "rgba(08080aff)" },
        },
    },
})

-- Native Hyprland tabs: drag a window onto a group, or use the keys below.
-- Group titles and the two-pixel active marker provide a visible focus cue.
hl.bind("SUPER + ALT + G", hl.dsp.group.toggle())
hl.bind("SUPER + ALT + H", hl.dsp.window.move({ into_or_create_group = "l" }))
hl.bind("SUPER + ALT + L", hl.dsp.window.move({ into_or_create_group = "r" }))
hl.bind("SUPER + ALT + J", hl.dsp.group.next())
hl.bind("SUPER + ALT + K", hl.dsp.group.prev())
hl.bind("SUPER + ALT + U", hl.dsp.window.move({ out_of_group = true }))

hl.bind(mod .. " + SHIFT + up", hl.dsp.window.move({ monitor = "eDP-1" }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.window.move({ monitor = "DP-2" }))

hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_CURSOR_SIZE", "24")
hl.env("MOZ_DISABLE_RDD_SANDBOX", "1")
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
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("grimblast --freeze save area - | tesseract stdin stdout | wl-copy"))
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
    hl.exec_cmd("asusctl backlight --screenpad-brightness 100")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.dispatch(hl.dsp.cursor.move({ x = 960, y = 540 }))
end)

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("SHIFT + SUPER + bracketright", hl.dsp.exec_cmd("bash -c 'cur=$(cat /sys/class/backlight/asus_screenpad/brightness); max=$(cat /sys/class/backlight/asus_screenpad/max_brightness); pct=$((cur * 100 / max + 10)); [ \"$pct\" -gt 100 ] && pct=100; asusctl backlight --screenpad-brightness \"$pct\"'"))
hl.bind("SHIFT + SUPER + bracketleft", hl.dsp.exec_cmd("bash -c 'cur=$(cat /sys/class/backlight/asus_screenpad/brightness); max=$(cat /sys/class/backlight/asus_screenpad/max_brightness); pct=$((cur * 100 / max - 10)); [ \"$pct\" -lt 0 ] && pct=0; asusctl backlight --screenpad-brightness \"$pct\"'"))

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

-- UX581GV dedicated buttons, captured directly from ASUS WMI events.
local zenbook = os.getenv("HOME") .. "/.local/bin/zenbook-controls "
for _, key in ipairs({ "code:490", "code:193", "code:194", "XF86Launch8", "XF86Launch6", "XF86Launch7", "XF86TouchpadToggle", "XF86TouchpadOn", "XF86TouchpadOff", "XF86KbdBrightnessUp", "XF86KbdBrightnessDown", "XF86KbdLightOnOff", "XF86AudioMicMute", "XF86ScreenSaver", "XF86Screensaver", "XF86Display", "XF86Launch1", "XF86RFKill", "XF86WLAN", "XF86Calculator", "XF86SelectiveScreenshot", "XF86WebCam", "SUPER + F3", "SUPER + F4", "SUPER + F5", "SUPER + F6", "SUPER + F7", "SUPER + F8", "SUPER + F9", "SUPER + F10", "SUPER + F11", "SUPER + F12" }) do hl.unbind(key) end
-- Apply named symbols only to the ASUS hotkey device; normal keyboards stay unchanged.
hl.device({ name = "asus-wmi-hotkeys", kb_file = os.getenv("HOME") .. "/.config/hypr/zenbook-hotkeys.xkb" })
local asus_key = { device = { inclusive = true, list = { "asus-wmi-hotkeys" } } }
hl.bind("XF86Launch8", hl.dsp.exec_cmd(zenbook .. "fan"), asus_key)
hl.bind("XF86Launch6", hl.dsp.exec_cmd(zenbook .. "swap"), asus_key)
hl.bind("XF86Launch7", hl.dsp.exec_cmd(zenbook .. "screenpad"), asus_key)
hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd(zenbook .. "touchpad"))
hl.bind("XF86TouchpadOn", hl.dsp.exec_cmd(zenbook .. "touchpad on"))
hl.bind("XF86TouchpadOff", hl.dsp.exec_cmd(zenbook .. "touchpad off"))
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd(zenbook .. "keyboard up"), { locked = true })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(zenbook .. "keyboard down"), { locked = true })
hl.bind("XF86KbdLightOnOff", hl.dsp.exec_cmd(zenbook .. "keyboard cycle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86ScreenSaver", hl.dsp.exec_cmd("qs -c wrayth ipc call lock lock"))
hl.bind("XF86Screensaver", hl.dsp.exec_cmd("qs -c wrayth ipc call lock lock"))
hl.bind("XF86Display", hl.dsp.exec_cmd("qs -c wrayth ipc call system page 1"))
hl.bind("XF86Launch1", hl.dsp.exec_cmd("qs -c wrayth ipc call system page 0"))
hl.bind("XF86RFKill", hl.dsp.exec_cmd(zenbook .. "airplane"))
hl.bind("XF86WLAN", hl.dsp.exec_cmd(zenbook .. "wifi"))
hl.bind("XF86Calculator", hl.dsp.exec_cmd("gnome-calculator"))
hl.bind("XF86WebCam", hl.dsp.exec_cmd(zenbook .. "camera"))
hl.bind("XF86SelectiveScreenshot", hl.dsp.exec_cmd(capture .. "screenshot area"))
-- Extra functions on Super+Fn preserve the application's plain F1-F12 keys.
hl.bind("SUPER + F3", hl.dsp.exec_cmd("qs -c wrayth ipc call system page 0"))
hl.bind("SUPER + F4", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("SUPER + F5", hl.dsp.exec_cmd(zenbook .. "profile"))
hl.bind("SUPER + F6", hl.dsp.exec_cmd(zenbook .. "touchpad"))
hl.bind("SUPER + F7", hl.dsp.exec_cmd(zenbook .. "keyboard cycle"))
hl.bind("SUPER + F8", hl.dsp.exec_cmd(zenbook .. "swap"))
hl.bind("SUPER + F9", hl.dsp.exec_cmd("qs -c wrayth ipc call idle hold toggle"))
hl.bind("SUPER + F10", hl.dsp.exec_cmd(zenbook .. "camera"))
hl.bind("SUPER + F11", hl.dsp.exec_cmd(capture .. "record output"))
hl.bind("SUPER + F12", hl.dsp.exec_cmd("qs -c wrayth ipc call system page 2"))
-- Preserve personal touchpad/scroll/animation choices across config reloads.
hl.exec_cmd(zenbook .. "restore")

-- Persistent clipboard archive and ScreenPad tools.
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
hl.window_rule({ name = "sensei-terminal-render-headroom", match = { class = "^(kitty|Alacritty)$" }, no_blur = true })
hl.layer_rule({ name = "sensei-bar-render-headroom", match = { namespace = "^wrayth-bar$" }, blur = false })
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
hl.layer_rule({ name = "sensei-navigation-stable", match = { namespace = "^sensei-navigation$" }, blur = false, no_anim = true })

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
hl.layer_rule({ name = "sensei-popup-soft-reveal", match = { namespace = "^wrayth-popup$" }, blur = false, no_anim = true })

-- Give the Intel display renderer better scheduling; allow scanout where eligible.
hl.config({ render = { new_render_scheduling = true, direct_scanout = 2 } })
