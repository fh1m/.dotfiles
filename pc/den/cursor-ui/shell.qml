import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
ShellRoot {
    id: root
    // Loader reload refreshes QML only. Restart den-cursor when shared JS changes;
    // Qt caches imported scripts for the renderer engine lifetime.
    property real companionRevision:Date.now()
    Loader {
        id:companionLoader
        asynchronous:true
        source:"file://"+Quickshell.env("HOME")+"/.local/share/sensei-companion/Companion.qml?v="+root.companionRevision
        onLoaded:item.ownerOutput=Qt.binding(()=>root.focusedOutput)
    }
    property bool focusDimming:false
    property bool focusMarker:true
    property bool reducedMotion:false
    FileView {path:Quickshell.env("HOME")+"/.config/sensei-den/companion.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{const p=JSON.parse(text());root.focusDimming=false;root.focusMarker=p.focusMarker!==false;root.reducedMotion=p.reducedMotion===true;}catch(e){}}}
    property string output: ""
    property string focusedOutput: ""
    property real px: 0
    property real py: 0
    property bool active: false
    property real phase: 0
    IpcHandler {
        target: "den-cursor"
        function state(): string { return JSON.stringify({focusedOutput:root.focusedOutput,dimOpacity:root.focusDimming?36/255:0,locatorActive:root.active,focusStyle:"brief-edge",focusMarker:root.focusMarker,cueOpacity:root.markerOpacity}) }
        function reloadCompanion():void {root.companionRevision=Date.now()}
        function focus(name: string): void {if(name===root.focusedOutput)return;root.focusedOutput=name;if(name)root.showFocusCue();}
        function pulse(name: string, x: real, y: real): void {
            root.output=name; root.px=x; root.py=y; root.active=true;
            motion.restart(); expiry.restart();
        }
    }
    NumberAnimation { id: motion; target: root; property: "phase"; from: 0; to: 1; duration: 850; easing.type: Easing.OutCubic }
    Timer { id: expiry; interval: 900; onTriggered: root.active=false }
    Variants {
        model: Quickshell.screens.filter(s => !s.name.startsWith("SENSEI-REFOCUS"))
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.active && root.output===modelData.name
            color: "transparent"
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "den-cursor-locator"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    property real diameter: 30 + root.phase*140 + index*22
                    x: root.px-diameter/2; y: root.py-diameter/2
                    width: diameter; height: diameter; radius: diameter/2
                    color: "transparent"; border.width: index===0?3:2; border.color: "#f91b84"
                    opacity: (1-root.phase)*(1-index*.2)
                }
            }
            Rectangle { x:root.px-3; y:root.py-3; width:6; height:6; radius:3; color:"#fff0f8"; opacity:1-root.phase }
        }
    }
    // Localised switch acknowledgement. Never tint the screen or keep a label.
    property real markerOpacity:0
    function showFocusCue():void {
        if(!focusMarker)return;
        if(reducedMotion){markerOpacity=1;markerExpiry.restart();}
        else markerMotion.restart();
    }
    Timer {id:markerExpiry;interval:650;onTriggered:root.markerOpacity=0}
    SequentialAnimation {id:markerMotion
        NumberAnimation {target:root;property:"markerOpacity";from:0;to:1;duration:110;easing.type:Easing.OutCubic}
        PauseAnimation {duration:420}
        NumberAnimation {target:root;property:"markerOpacity";to:0;duration:650;easing.type:Easing.OutCubic}
    }
    Connections {target:Hyprland;function onRawEvent(event){if(event.name==="activewindowv2"&&root.focusedOutput)root.showFocusCue();}}

    Variants {
        model:Quickshell.screens.filter(s=>!s.name.startsWith("SENSEI-"))
        PanelWindow {
            required property var modelData
            screen:modelData
            visible:root.focusMarker && root.markerOpacity>0 && root.focusedOutput===modelData.name
            color:"transparent"
            implicitHeight:5
            anchors {top:true;left:true;right:true}
            exclusionMode:ExclusionMode.Ignore
            WlrLayershell.layer:WlrLayer.Overlay
            WlrLayershell.namespace:"den-focus-marker"
            WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
            mask:Region {}
            Rectangle {anchors.horizontalCenter:parent.horizontalCenter;width:180;height:4;radius:2;color:"#e6d7bb";opacity:root.markerOpacity}
        }
    }
}
