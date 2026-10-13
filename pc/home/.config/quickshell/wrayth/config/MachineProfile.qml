pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: root
    property var facts: ({primaryOutput: "", gpuName: "NVIDIA GPU", cpuName: "CPU"})
    readonly property bool desktop: true
    readonly property string primaryOutput: facts.primaryOutput ?? ""
    readonly property string gpuName: facts.gpuName ?? "NVIDIA GPU"
    readonly property string cpuName: facts.cpuName ?? "CPU"
    Process {
        running: true
        command: [Quickshell.env("HOME") + "/.local/bin/sensei-machine"]
        stdout: StdioCollector { onStreamFinished: { try {root.facts = JSON.parse(text);} catch(e) {} } }
    }
}
