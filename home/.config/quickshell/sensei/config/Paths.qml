pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Every path the shell reads or writes, in one place.
Singleton {
    id: root

    // **Keep the shell's own directories owner-only.** They hold the planner
    // (real task names), the launch history and the like -- personal, not
    // secret, but there is no reason for another local user to read them, and
    // FileView creates them at the process umask (usually world-readable 755).
    // Created 700 and re-tightened at every start; the paths are the user's own
    // home plus fixed names, passed as positional args so nothing is a shell
    // string.
    Process {
        id: dirGuard
        command: ["sh", "-c", "for d in \"$@\"; do mkdir -p -m 700 \"$d\" 2> /dev/null; chmod 700 \"$d\" 2> /dev/null; done", "sh", root.configDir, root.cacheDir, root.stateDir]
    }

    // Started from onCompleted, not `running: true`, so the command's path
    // arguments (derived properties) are resolved before it runs. Re-applied
    // once after start-up settles, because a config directory a FileView
    // creates as it writes its first default can land after the first pass and
    // would otherwise keep the umask's world-readable mode.
    function _guardDirs(): void {
        dirGuard.running = true;
    }

    Component.onCompleted: root._guardDirs()

    Timer {
        interval: 2500
        running: true
        onTriggered: root._guardDirs()
    }

    readonly property string home: Quickshell.env("HOME")

    // **A path shown to a person reads the home folder as `~`.** This is a
    // permanent display rule, not a demo-mode mask: `/home/<user>` in a label
    // leaks the username and is noise besides, and `~` is what a person reads
    // a path as anyway. The stored paths are always absolute; only the display
    // changes. Every label, field placeholder, tooltip and message that shows
    // a path goes through this.
    function display(path: string): string {
        if (!path)
            return path;
        if (path === home)
            return "~";
        if (path.startsWith(home + "/"))
            return "~" + path.slice(home.length);
        return path;
    }

    // The inverse, for a field that shows `~` and is typed back into.
    function expand(path: string): string {
        if (!path)
            return path;
        if (path === "~")
            return home;
        if (path.startsWith("~/"))
            return home + path.slice(1);
        return path;
    }

    readonly property string configDir: `${home}/.config/sensei`
    readonly property string cacheDir: `${home}/.cache/sensei`
    readonly property string stateDir: `${home}/.local/state/sensei`

    readonly property string profileFile: `${configDir}/profile`
    readonly property string customProfilesFile: `${configDir}/custom-profiles.json`
    readonly property string wallpapersFile: `${configDir}/wallpapers.json`
    // The first-run prefill for the wallpaper folder (services/Wallpapers.qml
    // seedFolder). README: "The folder defaults to ~/Pictures/wallpapers".
    readonly property string defaultWallpaperRoot: `${home}/Pictures/wallpapers`
    readonly property string effectsFile: `${configDir}/effects.json`
    readonly property string plannerFile: `${configDir}/planner.txt`
    readonly property string runnerFile: `${configDir}/runner`
    readonly property string statusFile: `${cacheDir}/status`
    readonly property string sessionFile: `${stateDir}/session`
    readonly property string launchesFile: `${stateDir}/launches`
    readonly property string idleFile: `${stateDir}/idle`
    // Marker that the one-time "short screen" notice has been shown; its mere
    // existence is the flag. Delete it (or the state dir) to see the notice again.
    readonly property string shortScreenFlag: `${stateDir}/shortscreen-notified`

    // The `sensei` subfolder of the library folder the user picks, where the
    // generated `net-*.png` wallpapers live. The library folder itself is
    // `Wallpapers.folder`; this is only the naming rule for its subfolder.
    function senseiSubfolder(root: string): string {
        return root ? `${root}/sensei` : "";
    }

    // Called by an absolute path: ~/.local/bin is not necessarily on the PATH
    // the shell was started with, and execDetached fails silently when it is not.
    readonly property string deckResetScript: `${home}/.local/bin/sensei-deck-reset`
    readonly property string deckRefreshScript: `${home}/.local/bin/sensei-deck-refresh`
    readonly property string daemonScript: `${home}/.local/bin/sensei-daemon`
    readonly property string wallpaperScript: `${home}/.local/bin/sensei-wallpaper`
    readonly property string unreadScript: `${home}/.local/bin/sensei-unread`


    // Path -> file:// url, for Image.source and friends. Each segment is
    // percent-encoded: a raw `#` starts a fragment and a raw `%` is read as an
    // escape, so a wallpaper named "net 50%#1.png" failed to load.
    function url(path: string): url {
        return Qt.resolvedUrl(`file://${String(path).split("/").map(encodeURIComponent).join("/")}`);
    }
}
