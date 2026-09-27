pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.services

// Monitor playback only while an output stream exists or the spectrum is visible.
// Native PipeWire graph updates wake it; there is no idle polling process.
Singleton {
    id: root

    readonly property bool hasStreams:Pipewire.nodes.values.some(n=>n.type===PwNodeType.AudioOutStream)
    property bool streamRunning:false
    readonly property bool detailed:ShellState.deckVisible || ShellState.dropdown==="sound"
    readonly property bool active:!ShellState.locked && (ShellState.deckVisible || streamRunning)
    function checkStreams(){if(!streamQuery.running)streamQuery.running=true;}
    onHasStreamsChanged:checkStreams()
    Process {id:streamEvents;running:root.hasStreams;command:["pactl","subscribe"];stdout:SplitParser{onRead:line=>{if(line.indexOf("sink-input")>=0)streamDebounce.restart();}}}
    Timer {id:streamDebounce;interval:180;onTriggered:root.checkStreams()}
    Process {id:streamQuery;command:["pactl","-f","json","list","sink-inputs"];stdout:StdioCollector{onStreamFinished:{try{root.streamRunning=JSON.parse(text).some(n=>!n.corked&&!n.mute);}catch(e){root.streamRunning=false;}}}}
    Component.onCompleted:checkStreams()
    readonly property int bars: 48

    // Throttle spectrum frames when its detailed view is closed.
    readonly property int idleEvery: 1
    property int _skipped: 0

    // One 0..1 value per bar, left to right.
    property var levels: []
    // Anything actually coming out of the speakers. Falls to false a moment
    // after the audio stops, so the panel settles rather than flickering.
    property bool live: false

    // **It restarts.** `running: root.active` starts cava once; the process
    // exiting -- a crash, PipeWire restarting under it, somebody killing it
    // -- left the deck's spectrum a flat line for the rest of the session
    // with no way back but a shell restart. Measured: killed, and gone
    // eighteen seconds later.
    //
    // The backoff is what keeps a cava that cannot run at all from becoming a
    // spawn loop, and the levels are dropped on the way down so the panel
    // does not sit holding the last frame it saw.
    Process {
        id: cava

        running: root.active
        command: ["cava", "-p", Quickshell.shellPath(root.detailed ? "assets/cava.conf" : "assets/cava-compact.conf")]

        onRunningChanged: {
            if (running)
                return;
            root.levels = [];
            root.live = false;
            quiet.stop();
            if (root.active)
                revive.restart();
        }

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: line => {
                if (!line)
                    return;
                if (!ShellState.deckVisible) {
                    if (++root._skipped < root.idleEvery)
                        return;
                }
                root._skipped = 0;
                const parts = line.split(";");
                const values = [];
                let peak = 0;
                // cava ends every frame with a trailing separator.
                for (let i = 0; i < parts.length; i++) {
                    if (parts[i] === "")
                        continue;
                    const value = Math.max(0, Math.min(1, Number(parts[i]) / 100));
                    values.push(value);
                    if (value > peak)
                        peak = value;
                }
                if (values.length === 0)
                    return;
                root.levels = values;
                if (peak > 0.02) {
                    root.live = true;
                    quiet.restart();
                }
            }
        }
    }

    Timer {
        id: revive

        interval: 3000
        onTriggered: if (root.active) cava.running = true
    }

    // Silence has to last a moment before the panel calls it silence.
    Timer {
        id: quiet

        interval: 900
        onTriggered: root.live = false
    }

    // Kept for the case where `active` is gated again: without it a restart
    // would come back holding the last frame from before it stopped.
    onActiveChanged: {
        cava.running=active;
        if (!active) {
            levels = [];
            live = false;
            quiet.stop();
        }
    }
}
