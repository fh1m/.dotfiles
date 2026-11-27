pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    function run(argv, cwd): void {
        if (!Array.isArray(argv) || argv.length === 0 || argv.some(arg => typeof arg !== "string"))
            return;
        const command = [Quickshell.env("HOME") + "/.local/bin/sensei-app-run"];
        if (cwd)
            command.push("--cwd", cwd);
        command.push("--", ...argv);
        Quickshell.execDetached(command);
    }
}
