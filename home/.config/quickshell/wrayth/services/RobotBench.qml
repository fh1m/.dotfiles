pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root
    property var data: ({boards: [], boardCount: 0, simulators: [], simCount: 0, brightness: 100, gpu: {state: "unavailable", usage: null, temperature: null}})
    function refresh(): void { if (!poll.running) poll.running = true; }
    Process {
        id: poll
        command: ["env", "SENSEI_MONITOR_OPEN="+(ShellState.dropdown === "monitor" ? "1" : "0"), "/home/fh1m/.local/bin/robot-bench-data"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.data = JSON.parse(text); } catch (error) {}
            }
        }
    }
    Process {running:true;command:["udevadm","monitor","--udev","--subsystem-match=tty"];stdout:SplitParser{onRead:line=>{if(line.indexOf("UDEV")>=0)deviceEvent.restart();}}}
    Timer {id:deviceEvent;interval:180;onTriggered:root.refresh()}
    Timer {
        interval: ShellState.dropdown === "monitor" ? 1000 : ShellState.dropdown === "system" ? 2000 : 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: if (!poll.running) poll.running = true
    }
}
