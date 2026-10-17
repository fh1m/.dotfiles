pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root
    property var passports:[]
    property var data: ({boards: [], boardCount: 0, simulators: [], simCount: 0, brightness: 100, gpu: {state: "unavailable", usage: null, temperature: null}})
    Component.onCompleted: refresh()
    function refresh(): void { if (!poll.running) poll.running = true; }
    Process {
        id: poll
        command: ["env", "SENSEI_MONITOR_OPEN="+(ShellState.dropdown === "monitor" ? "1" : "0"), "@HOME@/.local/bin/robot-bench-data"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.data = JSON.parse(text); } catch (error) {}
            }
        }
    }
    Process {running:true;command:[Quickshell.env("HOME")+"/.local/bin/sensei-hardware","watch"];stdout:SplitParser{onRead:line=>{try{root.passports=JSON.parse(line).devices||[];deviceEvent.restart();}catch(e){}}}}
    Timer {id:deviceEvent;interval:180;onTriggered:root.refresh()}
    Timer {
        interval: ShellState.dropdown === "monitor" ? 1000 : 2000
        repeat: true
        running: ShellState.dropdown === "monitor" || ShellState.dropdown === "system"
        triggeredOnStart: true
        onTriggered: if (!poll.running) poll.running = true
    }
}
