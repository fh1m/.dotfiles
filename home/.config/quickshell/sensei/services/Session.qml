pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// The power menu's tiles and what they do. Reboot and power off are armed by a
// first press and only run on a second, so neither is one keystroke away.
Singleton {
    id: root

    readonly property var tiles: [
        {
            id: "lock",
            label: "LOCK",
            key: "L",
            katakana: "ЗАМОК",
            confirm: false
        },
        {
            id: "logout",
            label: "LOG OUT",
            key: "E",
            katakana: "ВЫХОД",
            confirm: true
        },
        {
            id: "sleep",
            label: "SLEEP",
            key: "S",
            katakana: "СОН",
            confirm: false
        },
        {
            id: "reboot",
            label: "REBOOT",
            key: "R",
            katakana: "ПЕРЕЗАПУСК",
            confirm: true
        },
        {
            id: "poweroff",
            label: "POWER OFF",
            key: "P",
            katakana: "СТОП",
            confirm: true
        }
    ]

    property int selected: 0
    // The tile id waiting on a second press, cleared when the countdown runs out.
    property string armed: ""
    // The tile whose action is under way, so it can wear the working state.
    // LOCK and SLEEP hand off to something that takes a moment; LOG OUT ends
    // the session outright.
    property string running: ""
    property string status: "READY"

    readonly property int confirmMs: 4000

    function move(delta: int): void {
        selected = (selected + delta + tiles.length) % tiles.length;
        armed = "";
        status = "READY";
    }

    // Escape, a click off the tiles, or the countdown running out all land
    // here: the armed tile stands down and the menu is whole again, without
    // closing. Only used while something is armed; closing is a separate act.
    function disarm(): void {
        armed = "";
        countdown.stop();
        status = "READY";
    }

    function selectKey(key: string): void {
        const index = tiles.findIndex(tile => tile.key === key.toUpperCase());
        if (index < 0)
            return;
        if (index !== selected) {
            selected = index;
            armed = "";
        }
        activate();
    }

    function activate(): void {
        const tile = tiles[selected];
        if (!tile)
            return;

        if (tile.confirm && armed !== tile.id) {
            armed = tile.id;
            status = `CONFIRM ${tile.label}`;
            countdown.restart();
            return;
        }

        armed = "";
        countdown.stop();
        status = `EXECUTING ${tile.label}`;
        run(tile.id);
    }

    function run(id: string): void {
        running = id;
        switch (id) {
        case "lock":
            close();
            ShellState.locked = true;
            break;
        case "logout":
            // Hyprland is configured in Lua, so this is an expression.
            Hyprland.dispatch("hl.dsp.exit()");
            break;
        case "sleep":
            // Lock first, then suspend: Hyprland keeps a session lock held
            // across suspend, so wake never shows the desktop. Suspend waits
            // for the compositor to confirm the lock (ShellState.lockSecure),
            // and refuses if it does not confirm in time -- a machine that
            // sleeps unlocked is worse than one that stays awake.
            ShellState.locked = true;
            sleepWait.waited = 0;
            sleepWait.restart();
            close();
            break;
        case "reboot":
            Quickshell.execDetached(["systemctl", "reboot"]);
            break;
        case "poweroff":
            Quickshell.execDetached(["systemctl", "poweroff"]);
            break;
        }
    }

    function open(): void {
        running = "";
        selected = 0;
        armed = "";
        status = "READY";
        countdown.stop();
        ShellState.openExclusive("power");
    }

    function close(): void {
        armed = "";
        countdown.stop();
        ShellState.closeAll();
    }

    // Polls for the confirmed lock. 3 s is a ceiling, not an expected wait.
    Timer {
        id: sleepWait

        property int waited: 0

        interval: 100
        repeat: true
        onTriggered: {
            if (ShellState.lockSecure) {
                stop();
                Quickshell.execDetached(["systemctl", "suspend"]);
                return;
            }
            waited += interval;
            if (waited >= 3000) {
                stop();
                console.warn("sensei: lock not confirmed in 3 s; suspend refused");
            }
        }
    }

    // No second press within confirmMs (four seconds) and the tile disarms itself.
    Timer {
        id: countdown

        interval: root.confirmMs
        onTriggered: {
            root.armed = "";
            root.status = "READY";
        }
    }
}
