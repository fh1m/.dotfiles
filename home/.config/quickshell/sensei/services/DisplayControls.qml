pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root
    property string error: ""
    property var pending: ({})
    property var targets: ({})
    function adjustLevel(output: string, delta: real): void {
        const previous = targets[output];
        // The main panel is read live from the backlight, as the sliders are.
        // RobotBench's copy is polled every few seconds and is only the fallback.
        const actual = output === "main" ? (Brightness.ready ? Brightness.value * 100 : RobotBench.data.mainBrightness) : output === "screenpad"?RobotBench.data.brightness:ExternalDisplays.display(output)?.level;
        if(!Number.isFinite(actual))return;
        const base = previous && Date.now() - previous.time < 2500 ? previous.level : actual;
        setLevel(output, base + delta);
    }
    function setLevel(output: string, percent: real): void {
        if(output!=="main"&&output!=="screenpad"){
            const externalLevel = Math.max(0, Math.min(100, Math.round(percent)));
            targets[output] = {level: externalLevel, time: Date.now()};
            ExternalDisplays.setLevel(output,externalLevel);return;
        }
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
        // The panel's backlight is the one Brightness found, so the OSD and the
        // slider always drive the same node.
        const panel = Brightness.device.replace(/\/+$/, "").split("/").pop() || "intel_backlight";
        control.command = request[0] === "screenpad"
            ? ["asusctl", "backlight", "--screenpad-brightness", String(request[1])]
            : ["brightnessctl", "-d", panel, "set", `${request[1]}%`];
        control.running = true;
    }
    Process {
        id: control
        stderr: StdioCollector { onStreamFinished: root.error = text.trim() }
        onExited: (code, status) => { if (code === 0) root.error = ""; RobotBench.refresh(); root.next(); }
    }
}
