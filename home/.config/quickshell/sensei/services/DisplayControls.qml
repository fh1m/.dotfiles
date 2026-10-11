pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root
    property var pending: ({})
    property var targets: ({})
    function adjustLevel(output: string, delta: real): void {
        const previous = targets[output];
        const actual = output === "main" ? RobotBench.data.mainBrightness : RobotBench.data.brightness;
        const base = previous && Date.now() - previous.time < 2500 ? previous.level : actual;
        setLevel(output, base + delta);
    }
    function setLevel(output: string, percent: real): void {
        const level = Math.max(1, Math.min(100, Math.round(percent)));
        targets[output] = {level: level, time: Date.now()};
        pending[output] = level;
        if (!control.running) next();
    }
    function next(): void {
        const outputs = Object.keys(pending);
        if (outputs.length === 0) return;
        const output = outputs[0];
        const request = [output, pending[output]];
        delete pending[output];
        control.command = request[0] === "screenpad"
            ? ["asusctl", "backlight", "--screenpad-brightness", String(request[1])]
            : ["brightnessctl", "-d", "intel_backlight", "set", `${request[1]}%`];
        control.running = true;
    }
    Process {
        id: control
        onExited: { RobotBench.refresh(); root.next(); }
    }
}
