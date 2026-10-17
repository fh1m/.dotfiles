pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: root
    property var facts: ({profile:"generic",primaryOutput:"eDP-1",gpuName:"GPU",cpuName:"CPU"})
    readonly property bool desktop: facts.profile === "pc"
    readonly property string primaryOutput: facts.primaryOutput ?? ""
    readonly property string gpuName: facts.gpuName ?? "NVIDIA GPU"
    readonly property string cpuName: facts.cpuName ?? "CPU"
    readonly property string host: facts.host ?? (desktop ? "homie" : "arete")
    readonly property var displayRoles: facts.displayRoles ?? ({})
    function role(output:string):string {return displayRoles[output] ?? "external";}
    FileView {path:Quickshell.env("HOME")+"/.config/hypr/monitors-user.json";watchChanges:true;printErrors:false;onFileChanged:{reload();settle.restart();}}
    property string outputNames: Quickshell.screens.map(s=>s.name).join(",")
    onOutputNamesChanged: settle.restart()
    Timer {id:settle;interval:700;onTriggered:if(!probe.running)probe.running=true}
    Process {
        id:probe
        running: true
        command: [Quickshell.env("HOME") + "/.local/bin/sensei-machine"]
        stdout: StdioCollector { onStreamFinished: { try {root.facts = JSON.parse(text);} catch(e) {} } }
    }
}
