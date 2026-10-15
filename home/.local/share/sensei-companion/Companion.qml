import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Loaded in the independent cursor overlay, never in the main desktop shell.
Item {
    id: root
    IpcHandler {target:"companion";function state():string{return JSON.stringify({allowed:root.allowed,output:root.target,fullscreen:root.fullscreen,pose:root.pose,size:root.preferences.size??96});}}
    property string ownerOutput: ""
    property var preferences: ({enabled:true,quiet:false,size:96})
    property var presence: ({})
    property int pose: 0
    property real drift: 0
    property bool fullscreen: false
    readonly property bool standalone: presence.mode?.effective === "homie" || presence.mode?.effective === "away"
    readonly property string preferred: Quickshell.screens.some(s=>s.name===preferences.output)?preferences.output:""
    readonly property string target: ownerOutput ? (preferred || ownerOutput) : (standalone ? (preferred || Quickshell.screens[0]?.name || "") : "")
    readonly property bool allowed: preferences.enabled !== false && preferences.quiet !== true && preferences.suspended !== true && !fullscreen && target !== ""
    function refreshFullscreen():void {Hyprland.refreshWorkspaces();settle.restart();}
    function choosePose():void {
        if(!allowed)return;
        if(Date.now()/1000-(preferences.poseAt||0)<8){pose=({wave:3,celebrate:6,think:2,sleep:7})[preferences.pose]??0;return;}
        pose=Math.random()<.25?2:0;
        if(Math.random()<.12){pose=4;drift=drift?0:120;walkExpiry.restart();}
    }
    FileView {id:settings;path:Quickshell.env("HOME")+"/.config/sensei-den/companion.json";watchChanges:true;printErrors:false
        onFileChanged:reload();onLoaded:{try{root.preferences=JSON.parse(text());root.choosePose();poseExpiry.restart();}catch(e){}}}
    FileView {id:presenceFile;path:Quickshell.env("HOME")+"/.local/state/sensei-den/presence.json";watchChanges:true;printErrors:false
        onFileChanged:reload();onLoaded:{try{root.presence=JSON.parse(text());}catch(e){}}}
    Connections {target:Hyprland;function onRawEvent(event){if(["fullscreen","workspace","focusedmon","monitoradded","monitorremoved"].includes(event.name))root.refreshFullscreen();}}
    Timer {id:settle;interval:80;onTriggered:{const monitor=Quickshell.screens.find(s=>s.name===root.target);root.fullscreen=(monitor?Hyprland.monitorFor(monitor)?.activeWorkspace?.lastIpcObject?.hasfullscreen:false)===true;}}
    onTargetChanged:refreshFullscreen()
    Timer {interval:7500;repeat:true;running:root.allowed;onTriggered:{if(root.pose===0){root.pose=1;blinkExpiry.restart();}}}
    Timer {id:poseExpiry;interval:8100;onTriggered:root.choosePose()}
    Timer {id:blinkExpiry;interval:180;onTriggered:root.pose=0}
    Timer {interval:30000;repeat:true;running:root.allowed;onTriggered:root.choosePose()}
    Timer {id:walkExpiry;interval:2000;onTriggered:root.pose=0}
    Timer {interval:250;repeat:true;running:root.allowed&&(root.pose===4||root.pose===5);onTriggered:root.pose=root.pose===4?5:4}
    PanelWindow {
        id:pet
        screen:Quickshell.screens.find(s=>s.name===root.target)??Quickshell.screens[0]
        visible:root.allowed
        color:"transparent"
        implicitWidth:Math.max(64,Math.min(180,root.preferences.size??96));implicitHeight:implicitWidth
        anchors {right:true;bottom:true}
        margins {right:20+root.drift;bottom:62}
        exclusionMode:ExclusionMode.Ignore
        WlrLayershell.layer:WlrLayer.Overlay
        WlrLayershell.namespace:"sensei-fh1m-companion"
        WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
        mask:Region {}
        Behavior on margins.right {NumberAnimation {duration:1800;easing.type:Easing.InOutSine}}
        Image {
            anchors.fill:parent
            source:Qt.resolvedUrl("fh1m-poses.png")
            readonly property real cell:1774/4
            sourceClipRect:Qt.rect((root.pose%4)*cell,Math.floor(root.pose/4)*cell,cell,cell)
            fillMode:Image.PreserveAspectFit
            smooth:true;asynchronous:true
        }
    }
}
