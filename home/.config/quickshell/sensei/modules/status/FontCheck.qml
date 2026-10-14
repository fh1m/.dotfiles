import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// **Warn, don't render boxes.** The shell asks for four specific font families
// by name (see config/Appearance.qml); if one is not installed Qt silently
// substitutes a default face, which for the katakana tags and the Nerd-Font bar
// icons means tofu. This checks the families at start and, if any is missing,
// raises a notification naming them and pointing at the README. The shell keeps
// working either way -- this only tells the user what to install.
Scope {
    // The families the shell's typography actually names, read from the same
    // place the text is drawn from, so this list cannot drift from it.
    readonly property var families: [...new Set([Appearance.font.display, Appearance.font.heading, Appearance.font.ui, Appearance.font.barUi, Appearance.font.data, Appearance.font.telemetry, Appearance.font.accent, Appearance.font.icons])]

    Process {
        running: true
        // fc-list may itself be absent (fontconfig not installed); then skip
        // quietly rather than warning about a tool we cannot use.
        command: ["sh", "-c", "command -v fc-list >/dev/null 2>&1 || exit 0; miss=''; for f in \"$@\"; do fc-list : family 2>/dev/null | grep -qiF \"$f\" || miss=\"${miss:+$miss, }$f\"; done; printf '%s' \"$miss\"", "sh"].concat(families)

        stdout: StdioCollector {
            onStreamFinished: {
                const missing = text.trim();
                if (missing)
                    Notifications.send("Sensei: fonts missing", `${missing} -- install these for correct rendering (see the README).`);
            }
        }
    }
}
