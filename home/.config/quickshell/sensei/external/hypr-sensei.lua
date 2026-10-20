-- sensei -- standalone Hyprland integration.
--
-- Everything Hyprland needs to run the sensei shell: the layer and window
-- rules, the animation curve and decoration the shell was designed against,
-- the start-up hook, and a set of keybinds. **It depends on nothing defined
-- anywhere else** -- no curve, variable, colour, monitor name or script outside
-- this file and sensei's own checkout -- so it loads on a bare Hyprland config
-- with zero errors (checked with `Hyprland --verify-config`).
--
-- install.sh places it at ~/.config/hypr/hypr-sensei.lua and loads it for you
-- -- either inside the complete config it installs, or by adding one line,
-- `require("hypr-sensei")`, to the end of your own hyprland.lua. Nothing needs
-- to be edited by hand. `./install.sh --uninstall` takes it out again.
--
-- It uses Hyprland's Lua config provider (the `hl` global, Hyprland 0.56+).
--
-- **Its keys replace any earlier bind on the same key.** Hyprland runs every
-- action bound to a key, so a key bound here and in your own config would do
-- both (Super + E opening a file manager *and* the deck). Each key below is
-- unbound first, so sensei's action is the only one. Change the keys freely.

-- ===========================================================================
-- Layer rules -- the shell's surfaces
-- ===========================================================================

-- Every sensei surface that comes and goes fades as one unit, blur included,
-- rather than sliding -- which is what stops blurred rectangles arriving from a
-- screen edge or lingering after their content is gone. QML never fades these
-- surfaces itself; that would double the fade.
hl.layer_rule({
    match     = { namespace = "sensei-(bar|deck|deckbg|popup|overlay|notifications)" },
    animation = "fade",
})

-- The daily-driver profile keeps these surfaces opaque and unblurred.
hl.layer_rule({
    match        = { namespace = "sensei-(bar|deck|deckbg|popup|overlay|notifications)" },
    blur         = false,
})

-- The wallpaper layer is opaque and must not fade on a profile change (the
-- shell crossfades the image itself), so it is outside both rules above.
hl.layer_rule({
    match   = { namespace = "sensei-background" },
    no_anim = true,
})

-- ===========================================================================
-- The deck -- a special workspace holding the sensei-deck Alacritty window
-- ===========================================================================

-- The deck terminal floats on its own special workspace; the shell sizes and
-- moves it, because a window rule is evaluated in raw monitor coordinates and
-- cannot see the area the bar reserves.
-- `silent`, so the terminal opening at login does not bring the deck up with
-- it: the deck stays closed until Super + E.
--
-- `size` and `move` put it in its slot from the moment it opens -- the exact
-- slot on a 1920 x 1080 screen, a whole number of Alacritty cells wide. The shell
-- then places it precisely for whatever screen it is on (and again whenever
-- the layout changes), deck open or not; these only make sure it never
-- appears anywhere else first.
hl.window_rule({
    match     = { class = "sensei-deck" },
    float     = true,
    workspace = "special:deck silent",
    size      = "1422 690",
    move      = "25 69",
})

-- Alacritty asks for activation when its screen is cleared; with focus-on-activate
-- on, that would pop the deck open on every profile change (which reprints the
-- greeting). Off, only Super + E opens it.
hl.window_rule({
    match             = { class = "sensei-deck" },
    focus_on_activate = false,
})

-- The deck terminal's frame matches the panels beside it: a 1 px border, the
-- colour set per profile by ~/.local/bin/sensei-profile.
hl.window_rule({
    match       = { class = "sensei-deck" },
    border_size = 1,
})

-- No gaps or shadow around the deck terminal: the shell's layout is the layout.
hl.workspace_rule({
    workspace = "special:deck",
    gaps_out  = 0,
    gaps_in   = 0,
    no_shadow = true,
})

-- The deck's curve, defined here under sensei's own name so it neither needs
-- nor disturbs a curve from any other config: fast out of the gate, settling
-- gently -- the same shape the deck was designed and measured against.
hl.curve("senseiDeck", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })

-- The deck fades as one thing. The panels are layer surfaces forced to `fade`
-- by the layer rule; the terminal is a window on the special workspace. Both
-- run at speed 4 (400 ms) on the same curve, so they arrive together rather
-- than in two pieces.
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 4, bezier = "senseiDeck" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 4, bezier = "senseiDeck" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "senseiDeck", style = "fade" })

-- ===========================================================================
-- Decoration -- what the deck terminal needs to match the panels
-- ===========================================================================
-- These are global (they affect every window). rounding_power = 1 turns
-- Hyprland's rounded corners into straight cuts, and rounding = 34 makes the
-- cut's leg 16 px -- the same chamfer the shell's own panels cut -- so a window
-- corner and a panel corner beside it are the same shape. Blur is on for special
-- workspaces only: every special -- the deck, scratch, communication -- gets the
-- same frosted, dimmed backdrop, so no window beneath shows through a gutter and
-- no special looks like a different surface. Measured on the Intel iGPU: an idle
-- normal workspace is unchanged with blur on (10% render), and the deck costs
-- about 10 points more with it on (61% -> 72% render while open).
-- Adjust to taste, but the deck terminal expects rounding_power = 1 and
-- rounding = 34.
hl.config({
    decoration = {
        dim_special    = 0.38,
        blur           = {
            enabled        = true,
            special        = true,
            size           = 8,
            passes         = 1,
        },
        rounding       = 34,
        rounding_power = 1,
        -- Shadows are off for the same render cost; the colour is kept for when they return.
        shadow = {
            enabled = false,
            color = "rgba(0000004D)",
            range = 15,
        },
    },
})

-- ===========================================================================
-- The lockscreen may be restarted into a held lock
-- ===========================================================================
-- If the lockscreen's process dies while the screen is locked, Hyprland keeps
-- the session locked and shows its own "lock screen app died" screen. This lets
-- a new sensei lockscreen take that lock over (sensei-shell starts one at once,
-- and sensei-recover does it from a text console), so getting back in is typing
-- your password, not ending the session. It never unlocks anything: the new
-- lockscreen still needs your password. See DESIGN.md, Security.
--
-- `session_lock_xray` keeps Hyprland drawing the desktop *behind* the lock
-- surface, which the lock surface covers opaquely until the password is
-- accepted; the unlock then dissolves onto the live desktop instead of onto
-- black. The surface is only ever transparent during that exit fade, after
-- authentication (see modules/lock/LockScreen.qml and DESIGN.md, Security).
hl.config({
    misc = {
        allow_session_lock_restore = true,
        session_lock_xray          = true,
    },
})

-- ===========================================================================
-- Start-up -- launch the shell, the idle daemon, and the deck terminal
-- ===========================================================================
hl.on("hyprland.start", function()
    -- Through the supervisor, which starts `qs -c sensei` and, if the shell
    -- ever dies while the screen is locked, starts it again straight into the
    -- lock (see external/sensei-shell).
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/sensei-shell")
    -- Idle: dim, lock, screen off, suspend (optional; needs the `hypridle`
    -- package and ~/.config/hypr/hypridle.conf -- see the install step).
    hl.exec_cmd("command -v hypridle > /dev/null && exec hypridle")
    -- The deck terminal. The reset script is also how it is first started.
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/sensei-deck-reset")
end)

-- ===========================================================================
-- Keybinds -- an example set (change freely)
-- ===========================================================================

-- Unbind first: see the header. Unbinding a key nothing is bound to is fine.
for _, key in ipairs({
    "SUPER + E", "SUPER + SHIFT + E", "SUPER + SUPER_L", "SUPER + P", "SUPER + L",
    "XF86MonBrightnessUp", "XF86MonBrightnessDown",
    "XF86AudioRaiseVolume", "XF86AudioLowerVolume", "XF86AudioMute",
    "SUPER + 1", "SUPER + 2", "SUPER + 3", "SUPER + 4", "SUPER + 5",
    "SUPER + 6", "SUPER + 7", "SUPER + 8", "SUPER + 9", "SUPER + 0",
}) do
    hl.unbind(key)
end

-- Super + E toggles the deck; Super + Shift + E redraws the deck terminal.
hl.bind("SUPER + E", hl.dsp.workspace.toggle_special("deck"))
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/sensei-deck-refresh"))

-- Super + Space opens the launcher. (A bare Super tap is not bound: SUPER_L is
-- cleared above.)
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("qs -c sensei ipc call launcher toggle"))

-- Super + P opens the power menu here; custom-setup.lua rebinds Super + P to the
-- calculator and keeps the power menu on Super + Ctrl + P. Super + L locks the screen.
hl.bind("SUPER + P", hl.dsp.exec_cmd("qs -c sensei ipc call power toggle"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("qs -c sensei ipc call lock lock"))

-- Brightness straight to brightnessctl (optional package); the OSD follows the
-- sysfs change whoever made it.
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -d intel_backlight set 5%+"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -d intel_backlight set 5%-"), { locked = true })

-- Volume in 5% steps, so one press is one segment on the OSD's 20-segment bar,
-- capped at 100%. The OSD follows PipeWire whoever moves it.
hl.bind("XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 2.0 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })

-- Super + <number> goes to that workspace, first closing any open special
-- workspace (the deck) so a number key means the same thing whether the deck is
-- up or not. A Lua function so it reads the live state on each press.
for i = 1, 10 do
    local key = tostring(i % 10) -- 10 maps to key 0
    local ws  = tostring(i)
    hl.bind("SUPER + " .. key, function()
        local sp = hl.get_active_special_workspace()
        if sp then
            hl.dispatch(hl.dsp.workspace.toggle_special((sp.name:gsub("^special:", ""))))
        end
        hl.dispatch(hl.dsp.focus({ workspace = ws }))
    end)
end
