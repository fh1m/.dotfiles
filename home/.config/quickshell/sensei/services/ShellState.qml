pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.config

// Which overlays are up. IPC and keybinds flip these; the overlay modules bind
// their visibility to them.
Singleton {
    id: root
    // Geometry only: let the independent companion avoid layer-shell panels.
    property var companionSpaces: ({})
    function reserveCompanion(key:string,output:string,x:real,y:real,w:real,h:real,shown:bool):void {
        const next=Object.assign({},companionSpaces);
        if(shown&&w>0&&h>0)next[key]={output:output,x:x,y:y,w:w,h:h};else delete next[key];
        if(JSON.stringify(next)!==JSON.stringify(companionSpaces)){companionSpaces=next;companionSpaceWrite.restart();}
    }
    FileView {id:companionSpaceFile;path:Quickshell.env("HOME")+"/.local/state/sensei-den/panel-spaces.json";printErrors:false}
    Timer {id:companionSpaceWrite;interval:160;onTriggered:companionSpaceFile.setText(JSON.stringify({version:1,spaces:Object.values(root.companionSpaces)}))}
    Component.onCompleted:companionSpaceWrite.restart()
    property int systemPage: 0
    property int monitorPage: 0

    // **The screens the shell draws on.** Every per-screen surface -- bar,
    // background, scanlines, deck, dropdowns, popups, launcher, picker, power
    // menu, notifications -- takes its screens from here, never from
    // `Quickshell.screens` directly. The one difference is the temporary
    // output `sensei-lock-assist refocus` adds for a moment after a console
    // switch: it exists only so the session lock gets a second surface, and
    // nothing else may appear on it. The lock itself (WlSessionLock) still
    // covers every output, that one included, as the protocol requires.
    readonly property string refocusOutputPrefix: "SENSEI-REFOCUS-"
    readonly property var screens: Quickshell.screens.filter(s => !String(s.name).startsWith(refocusOutputPrefix))

    // One bar and one dropdown focus grab, on the UX581GV main panel.
    // Leave ScreenPad's full height available to applications.
    readonly property var barScreens: {
        const main = screens.find(s => s.name === MachineProfile.primaryOutput);
        return main ? [main] : screens.slice(0, 1);
    }

    // SENSEI-HDMI-TEST and SENSEI-UPPER-TEST are names for headless outputs
    // made by hand, to rehearse an HDMI screen and a top-bar external screen
    // without the hardware. Nothing in the repo creates them; they are seams
    // for the same reason as the names in sensei-displays.
    function isExternalOutput(name:string):bool {return name!==(barScreens[0]?.name??MachineProfile.primaryOutput)&&(MachineProfile.role(name)!=="screenpad")&&(name.startsWith("HDMI-")||name.startsWith("DP-")||name.startsWith("eDP-")||name.startsWith("DVI-")||name==="SENSEI-HDMI-TEST"||name==="SENSEI-UPPER-TEST");}
    function externalBarEdge(name:string):string {return MachineProfile.role(name)==="upper"?"top":ExternalDisplays.display(name)?.barEdge??((name==="DP-1"||name==="SENSEI-UPPER-TEST")?"top":"bottom");}
    readonly property var externalScreens: screens.filter(s => isExternalOutput(s.name))
    readonly property var bottomBarScreens: MachineProfile.desktop ? barScreens.concat(externalScreens) : screens.filter(s => s.name === "DP-2" || externalScreens.some(e=>e.name===s.name))
    property string dropdownOriginScreen: ""
    property var barWindows: ({})
    function registerBar(output:string,window:var):void {const next=Object.assign({},barWindows);if(window)next[output]=window;else delete next[output];barWindows=next;}
    property string hoveredBarOutput:""
    property double barContextAt:0
    function barContext(output:string):void {hoveredBarOutput=output;barContextAt=Date.now();if(dropdown==="")dropdownOriginScreen=output;}

    function focusedScreenName(): string {
        return Spaces.focusedMonitor?.name ?? Hyprland.focusedMonitor?.name ?? barScreens[0]?.name ?? "";
    }
    property string overlayScreenName: "eDP-1"
    readonly property var overlayScreens: {
        const selected = screens.find(s => s.name === overlayScreenName);
        return selected ? [selected] : barScreens;
    }

    property bool externalDialogOpen: false
    property bool launcherOpen: false
    property bool powerOpen: false
    property bool pickerOpen: false
    property bool shortcutsOpen: false
    // Which of the picker's three screens is up: "grid", "editor" or "pools".
    // It lives here rather than on the overlay so the IPC can drive it -- the
    // two inner screens are reached by clicking, and nothing in a test session
    // can click.
    property string pickerView: "grid"
    // The custom profile the editor is editing, or "" for a new one.
    property string pickerEditing: ""
    property bool locked: false
    // True only once the compositor has confirmed the session lock (`lock.secure`
    // in LockScreen). `locked` says the shell wants a lock; this says it has one.
    property bool lockSecure: false

    // **Locking closes whatever was up.** The session lock draws over every
    // layer, so an overlay left open behind it is invisible -- and still
    // holding the keyboard when the lock lifts, over a screen that looks
    // ordinary. The power menu's own LOCK already closed itself; Super + L
    // and `ipc call lock lock` did not.
    onLockedChanged: {
        if (locked) closeAll()
        Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-den","companion","suspended",locked?"on":"off"])
    }

    // Set by the deck plumbing, from Hyprland's workspace events.
    property bool deckVisible: false

    // The bar's PanelWindow, published by Bar.qml. The dropdown layer needs it
    // to size itself against the bar's width and to keep the bar clickable
    // under its focus grab.
    property var barWindow: null
    property var bottomBarWindow: null

    // Which bar dropdown is open, by name, or "" for none. The names are the ones
    // Ipc's dropdownNames lists.
    property string dropdown: ""
    // The x of the bar readout that opened it, in bar-window coordinates. The
    // dropdown overlay shares that origin, so it can use the value directly.
    property real dropdownAnchorX: 0
    // Bumped whenever a readout toggles a dropdown, so the bar's own dismiss
    // handler can tell a click on a readout from a click on bare bar.
    property int dropdownStamp: 0
    // True while the pointer is anywhere over the bar. The dropdown's focus grab
    // waits on this; see the comment there.
    property bool barHovered: false
    // A moving bar surface can force both Intel-driven screens to composite at
    // full rate. Keep readings live, but spend animation frames only while the
    // bar or an overlay is being used. Music playback itself is unaffected.
    readonly property bool ambientMotion: !DesktopTools.quiet && (barHovered || dropdown !== "" || deckVisible || pickerOpen || launcherOpen || powerOpen || shortcutsOpen)

    // **Where each bar readout is, published by the readouts themselves.**
    // `dropdown open <name>` used to hang every panel at a fixed x in the
    // middle of the bar, which is fine for a frame burst and wrong on camera.
    // A readout knows its own position; nothing else does.
    property var dropdownAnchors: ({})
    property var dropdownAnchorEdges: ({})
    property string dropdownEdge: "top"

    function publishAnchor(name, x, output, edge) {
        if(output)name=output+":"+name;
        if(edge==='top'||edge==='bottom'){const edges=Object.assign({},dropdownAnchorEdges);edges[name]=edge;dropdownAnchorEdges=edges;}
        if (dropdownAnchors[name] === x)
            return;
        const next = Object.assign({}, dropdownAnchors);
        next[name] = x;
        dropdownAnchors = next;
    }

    function barInset(output,edge) {
        let value=0;
        for(const [key,window] of Object.entries(barWindows))if(key===output+':'+edge&&window)value=Math.max(value,window.height||Appearance.metrics.barHeight);
        return value;
    }
    function edgeFor(name,output) {
        return dropdownAnchorEdges[output+':'+name] || (MachineProfile.role(output)==='screenpad'?'bottom':isExternalOutput(output)?externalBarEdge(output):['monitor','clipboard','usb','phone','oasis'].includes(name)?'bottom':'top');
    }
    function toggleDropdownAt(name,item,window) {
        if(!window?.screen)return;
        const output=window.screen.name;
        const entry=Object.entries(barWindows).find(pair=>pair[1]===window);
        const edge=entry?.[0]?.endsWith(':bottom')?'bottom':'top';
        const point=item.mapToItem(window.contentItem,item.width/2,0);
        publishAnchor(name,point.x,output,edge);
        toggleDropdownOn(name,output);
    }
    function anchorFor(name: string): real {
        return dropdownAnchors[dropdownOriginScreen+":"+name] ?? dropdownAnchors[name] ?? 0;
    }

    property string engineeringSelectedAction:""
    property string engineeringSelectedJob:""
    property string engineeringSelectedHost:""
    property int instrumentPage:0
    property string instrumentProject:""
    property string instrumentHost:""
    property bool instrumentLoaded:false
    FileView {id:instrumentSettings;path:Quickshell.env("HOME")+"/.config/sensei-den/instrument.json";printErrors:false
        onLoaded:{try{const d=JSON.parse(text());if(["normal","coding","simulation","hardware","drawing"].includes(d.mode))root.instrumentMode=d.mode;if(typeof d.project==="string")root.instrumentProject=d.project;}catch(e){}root.instrumentLoaded=true;}
        onLoadFailed:root.instrumentLoaded=true
    }
    function saveInstrument():void{if(instrumentLoaded)instrumentSettings.setText(JSON.stringify({version:1,mode:instrumentMode,project:instrumentProject}));}
    onInstrumentModeChanged:saveInstrument()
    onInstrumentProjectChanged:saveInstrument()
    property string instrumentMode:"normal"
    property string instrumentKind:"engineering"
    property bool instrumentPinned:false
    property var instrumentPrevious:({name:"",output:""})
    function openDropdownOn(name:string,output:string):void {
        if(!screens.some(s=>s.name===output))output=focusedScreenName();
        if(!screens.some(s=>s.name===output))output=MachineProfile.primaryOutput;
        if(!screens.some(s=>s.name===output))return;
        SpotifyDesk.fullscreen=false;dropdownOriginScreen=output;dropdownEdge=edgeFor(name,output);dropdownAnchorX=anchorFor(name);dropdown=name;dropdownStamp++;
    }
    function toggleDropdownOn(name:string,output:string):void {
        if(!screens.some(s=>s.name===output)){toggleDropdown(name);return;}
        const close=dropdown===name&&dropdownOriginScreen===output;
        if(close){dropdown="";dropdownStamp++;return;}
        openDropdownOn(name,output);
    }
    function pinInstrument(kind:string):void {
        const pad=screens.find(s=>MachineProfile.role(s.name)==="screenpad");if(!pad)return;
        instrumentPrevious={name:dropdown,output:dropdownOriginScreen};instrumentKind=kind||"engineering";instrumentPinned=true;dropdown="";
    }
    function releaseInstrument():void {instrumentPinned=false;if(dropdown===""&&instrumentPrevious.name)openDropdownOn(instrumentPrevious.name,instrumentPrevious.output);}
    function openDropdown(name: string): void {
        openDropdownOn(name,barHovered&&hoveredBarOutput?hoveredBarOutput:focusedScreenName());
    }
    function toggleDropdown(name: string): void {
        toggleDropdownOn(name,barHovered&&hoveredBarOutput?hoveredBarOutput:focusedScreenName());
    }

    // **One overlay at a time, and this is the only way in.**
    //
    // It used to be exclusive of the launcher, the power menu and the picker
    // and of nothing else, so `daemons library open` followed by `launcher
    // open` left two `sensei-overlay` surfaces stacked -- both asking for
    // exclusive keyboard focus, and Escape closing only the top one. The bar
    // dropdowns escaped the same fault by luck: an overlay taking the
    // keyboard clears the dropdown's focus grab, which closes it, and that
    // grab is not armed while the pointer is still on the bar.
    //
    // `daemons` is a name here like any other, so the library opens through
    // the same call rather than through a flag of its own.
    function openExclusive(which: string): void {
        if (which !== "") {WindowDesk.opened=false;SpotifyDesk.fullscreen=false;}
        if (which !== "") overlayScreenName = which === "picker" && Quickshell.screens.some(s=>s.name==="eDP-1") ? "eDP-1" : focusedScreenName();
        launcherOpen = which === "launcher";
        powerOpen = which === "power";
        pickerOpen = which === "picker";
        shortcutsOpen = which === "shortcuts";
        Daemons.libraryOpen = which === "daemons";
        // A dropdown is not an overlay, but it is a surface holding a focus
        // grab, and two things on screen asking for the keyboard is the bug
        // whatever they are called.
        if (which !== "")
            dropdown = "";
    }

    function closeAll(): void {
        openExclusive("");
        SpotifyDesk.fullscreen=false;
        dropdown = "";
        WindowDesk.opened=false;
    }

    // **Reaches into the custom editor from outside it.** Its swatch rows and
    // its colour picker are both pointer-driven -- a `TapHandler` and a drag --
    // and a recording has no pointer. A signal rather than a property because
    // the editor owns its own draft and nothing else should be able to hold a
    // copy of it.
    signal editorColour(string key, string hex)

    // Moves the picker's selection, which is what previews a profile *and*
    // lifts its card. `profile preview` only recolours the shell: the grid
    // would sit on whatever card it opened on while the colours changed
    // underneath it, which reads as the picker being broken.
    signal pickerSelect(string name)

    // Runs the pools screen's demo drag: a wallpaper from the library to a
    // profile's row, animated as a hand would move it. Demo-only, because
    // there is no pointer in a recording and this is the one gesture the
    // screen is built around.
    signal poolsDemoDrag(string file, string profile)

    // Saves the open custom editor under a name, the same call its own
    // NAME // PROFILE prompt makes. It is the fallback for a recording where
    // the typed name did not land: a video that stops halfway through a scene
    // is worse than one where the last keystroke came from somewhere else.
    signal editorSave(string name)

    // TEMPORARY (QA): the interaction states are pointer-driven and `ydotoold`
    // is not running, so there is no way to click a button from a test. This
    // lets the frame bursts drive a real ActionState through each phase.
    // Remove with the `qa` IPC handler once the states are signed off.
    signal qaAction(string kind)
}
