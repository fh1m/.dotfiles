pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config

// The workspace rail follows the focused display, including ScreenPad Misc.
// Switching a workspace must be reflected even when it belongs to another output.
// The indicator is always seven regular slots wide: the numbered workspaces
// holding the active one. While a special workspace is visible, the page marker
// names it instead (`pageLabel`, `modeGlyph`).
//
// Kept out of the bar component so the indicator stays pure rendering, and out
// of `Deck` so it does not depend on the deck being constructed.
Singleton {
    id: root

    IpcHandler {target:"workspaces";function state():string {return JSON.stringify({monitors:root.outputState.map(m=>({name:m.name,active:m.activeWorkspace?.id,focused:m.focused,slots:root.slotsFor(m.name).map(s=>({target:s.target,active:s.active,count:s.count,localCount:s.localCount,occupied:s.occupied}))})),mode:root.pageLabel,glyph:root.modeGlyph,special:root.activeSpecial,active:root.activeId,slots:root.slots.map(s=>({label:s.label,active:s.active}))});}}
    property var attentionAddresses: []
    property bool remoteCapture: false
    FileView {path:Quickshell.env("HOME")+"/.local/state/homie-control/input/active";watchChanges:true;printErrors:false
        onFileChanged:reload();onLoaded:root.remoteCapture=text().trim()==="1"}
    function attention(address):void {const a=String(address||"").replace(/^0x/,"");if(a&&!attentionAddresses.includes(a))attentionAddresses=attentionAddresses.concat([a]);}
    function acknowledge(address):void {const a=String(address||"").replace(/^0x/,"");attentionAddresses=attentionAddresses.filter(x=>x!==a);}
    readonly property int perPage: 7
    property var contract: ({subjects:[]})
    readonly property var workspaceIds: contract.subjects.map((s,i)=>i+1)
    readonly property var workspaceNames: contract.subjects.map(s=>s.name)
    readonly property var workspaceGlyphs: contract.subjects.map(s=>s.glyph)
    FileView {path:Quickshell.env("HOME")+"/.local/share/sensei/workspaces.json";watchChanges:true;printErrors:false
        onFileChanged:reload();onLoaded:{try{const c=JSON.parse(text());if(c.schema===1&&c.subjects.length===7&&c.utility===90)root.contract=c;}catch(e){console.warn("Workspace contract unavailable");}}
    }

    // Special workspaces carry a name; these are the ones worth a word rather
    // than the first four letters of whatever Hyprland calls them.
    readonly property var specialLabels: ({
        deck: "Deck",
        special: "Scratch",
        communication: "Chat",
        favourites: "Favorites",
        favorites: "Favorites"
    })

    // The compositor snapshot is authoritative across multi-GPU hotplug and QML reloads.
    // Some Quickshell builds retain an incomplete monitor IPC cache.
    property var outputState: []
    property var clientsState: []
    property bool outputRefreshPending: false
    function refreshOutputs():void {if(outputScan.running){outputRefreshPending=true;return;}outputScan.running=true;}
    Component.onCompleted: refreshOutputs()
    Timer {id:outputSettle;interval:35;onTriggered:root.refreshOutputs()}
    Process {id:outputScan;command:[Quickshell.env("HOME")+"/.local/bin/sensei-workspace-state"]
        stdout:StdioCollector {onStreamFinished:{try{const data=JSON.parse(text);if(Array.isArray(data.monitors)&&Array.isArray(data.clients)){root.clientsState=data.clients;root.outputState=data.monitors;}}catch(e){console.warn("Workspace monitor snapshot unavailable");}}}
        onExited:if(root.outputRefreshPending){root.outputRefreshPending=false;Qt.callLater(()=>root.refreshOutputs());}
    }
    readonly property var mainMonitor: outputState.find(m=>m.name===MachineProfile.primaryOutput) ?? outputState[0] ?? null
    readonly property var monitorIpc: mainMonitor
    readonly property var focusedMonitor: outputState.find(m=>m.focused) ?? mainMonitor
    function windowWorkspace(t){return t.lastIpcObject?.workspace?.id??t.workspace?.id;}
    function logicalId(id):int {return id>100&&id<3300&&id%100>=1&&id%100<=7?id%100:id;}
    readonly property int activeId: logicalId(focusedMonitor?.activeWorkspace?.id ?? 1)
    readonly property string activeSpecial: focusedMonitor?.specialWorkspace?.name ?? ""
    readonly property bool special: activeSpecial.startsWith("special:")

    function labelFor(name: string): string {
        return specialLabels[name] ?? name.charAt(0).toUpperCase() + name.slice(1);
    }

    // Always the seven regular slots in the configured order. Special workspaces
    // are not slots here: while one is up, the page label and mode glyph say so.
    readonly property var slots: {
        const out = [];
        for (let i = 0; i < workspaceIds.length; i++) {
            const id = workspaceIds[i];
            out.push({
                label: workspaceNames[id - 1] ?? `${id}`.padStart(2, "0"),
                glyph: workspaceGlyphs[id - 1] ?? "",
                target: `${id}`,
                special: false,
                empty: id > workspaceNames.length,
                active: !special && id === activeId,
                occupied: clientsState.some(t=>logicalId(t.workspace?.id)===id),
                count: clientsState.filter(t=>logicalId(t.workspace?.id)===id).length,
                attention: clientsState.some(t=>logicalId(t.workspace?.id)===id && attentionAddresses.includes(String(t.address||"").replace(/^0x/,"")))
            });
        }
        return out;
    }

    // --- Pages, for the bar's page marker -----------------------------------
    // A page is in use if any of its workspaces exist or it is the active one.
    // Pages need not be contiguous -- workspaces 1 and 12 put pages 0 and 2 in
    // use and page 1 not -- so the pips follow the *used* pages in order, and
    // the lit one is the current page's place in that list rather than its
    // page number.
    readonly property var usedPages: {
        const pages = {};
        for (const ws of Hyprland.workspaces.values)
            if (logicalId(ws.id) >= 1 && logicalId(ws.id) <= 7)
                pages[Math.floor((logicalId(ws.id) - 1) / perPage)] = true;
        pages[Math.floor(Math.max(0, activeId - 1) / perPage)] = true;
        return Object.keys(pages).map(Number).sort((a, b) => a - b);
    }

    readonly property int currentPage: Math.floor(Math.max(0, activeId - 1) / perPage)

    // `SPC` while a special workspace is up, otherwise the page number.
    readonly property string modeGlyph: !special ? "\uf009" : activeSpecial === "special:deck" ? "\uf120" : activeSpecial === "special:special" ? "\uf044" : "\uf24d"
    readonly property string pageLabel: special ? labelFor(activeSpecial.slice(8)) : "Spaces"

    // One pip per used page, plus a final one for the special page.
    //
    // The marker rests at three pips -- two numbered pages and the special
    // one -- rather than following the used pages down to a single pip. A lone
    // pip reads as a decoration beside the slots; a standing row of three reads
    // as the pager it is, and the pips stop appearing and vanishing as
    // workspaces come and go. Extra pips light up as pages beyond the second
    // come into use.
    readonly property int minNumberedPips: 2
    readonly property int numberedPips: Math.max(minNumberedPips, usedPages.length)
    readonly property int pipCount: numberedPips + 1
    readonly property int litPip: special ? numberedPips : Math.max(0, usedPages.indexOf(currentPage))

    // Which slot the bar's accent line runs to, or -1 when none is lit.
    readonly property int activeIndex: special ? -1 : workspaceIds.indexOf(activeId)

    function slotsFor(output:string):var {
        if(!output)return slots;
        const monitor=outputState.find(m=>m.name===output);
        const active=logicalId(monitor?.activeWorkspace?.id ?? 1);
        return slots.map(s=>{
            const id=Number(s.target);
            const local=clientsState.filter(t=>logicalId(t.workspace?.id)===id && Number(t.monitor)===Number(monitor?.id));
            return Object.assign({},s,{active:id===active,count:s.count,localCount:local.length,occupied:s.occupied,
                elsewhere:outputState.some(m=>m.name!==output&&logicalId(m.activeWorkspace?.id)===id)});
        });
    }
    function activate(slot, output = "") {
        if (slot.empty)
            return;
        if(output&&!slot.special){Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-displays","workspace",slot.target,output]);return;}
        // The name goes into a Lua string, so only plain characters may reach it;
        // a quote in a workspace name would break out of that string. PageMarker
        // applies the same rule.
        if (slot.special && !/^[A-Za-z0-9._-]+$/.test(slot.target))
            return;
        if (slot.special)
            Hyprland.dispatch(`hl.dsp.workspace.toggle_special("${slot.target}")`);
        else
            Hyprland.dispatch(`(function() local sp=hl.get_active_special_workspace(); if sp then hl.dispatch(hl.dsp.workspace.toggle_special(sp.name:gsub("^special:", ""))) end; return hl.dsp.focus({ workspace = "${slot.target}" }) end)()`);
    }

    Timer { interval:3000; repeat:true; running:true; onTriggered:root.refreshOutputs() }
    Process {id:sessionEvents;running:true;command:[Quickshell.env("HOME")+"/.local/bin/sensei-workspace-events"]
        stdout:SplitParser {onRead: data=>{
            outputSettle.restart();
            try {const event=JSON.parse(data);if(event.name==="urgent")root.attention(event.data);
                if(event.name==="activewindowv2"||event.name==="closewindow")root.acknowledge(event.data);
                if(["workspace","workspacev2","movewindow","movewindowv2","monitoradded","monitoraddedv2","monitorremoved","configreloaded"].includes(event.name))pairSettle.restart();
            } catch(e) {}
        }}
        onExited:eventRestart.restart()
    }
    Timer {id:eventRestart;interval:2000;onTriggered:sessionEvents.running=true}
    property bool pairRefreshPending:false
    Timer {id:pairSettle;interval:140;onTriggered:{if(pairSync.running)root.pairRefreshPending=true;else pairSync.running=true;}}
    Process {id:pairSync;command:[Quickshell.env("HOME")+"/.local/bin/sensei-displays","reconcile"]
        onExited:if(root.pairRefreshPending){root.pairRefreshPending=false;pairSettle.restart();}
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            const n = event.name;
            if(["workspace","workspacev2","movewindow","movewindowv2","monitoradded","monitoraddedv2","monitorremoved","configreloaded"].includes(n))pairSettle.restart();
            if(n==="urgent"){root.attention(event.data);Hyprland.refreshToplevels();}
            if(n==="activewindowv2"||n==="closewindow")root.acknowledge(event.data);
            if (["activespecial", "activespecialv2", "workspace", "workspacev2", "moveworkspace", "moveworkspacev2", "focusedmon", "monitoradded", "monitoraddedv2", "monitorremoved","movewindow","movewindowv2"].includes(n)) outputSettle.restart();
            if (["activespecial", "workspace", "createworkspace", "destroyworkspace", "moveworkspace", "renameworkspace", "focusedmon"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            }
        }
    }
}
