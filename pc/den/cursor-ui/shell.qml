import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
ShellRoot {
    id: root
    // Zondo policy v6: reload this root when the shared JS policy changes.
    property real companionRevision:Date.now()
    Loader {
        id:companionLoader
        asynchronous:true
        source:Quickshell.env("HOME")+"/.local/share/sensei-companion/Companion.qml?v="+root.companionRevision
        onLoaded:item.ownerOutput=Qt.binding(()=>root.focusedOutput)
    }
    property bool focusDimming:false
    FileView {path:Quickshell.env("HOME")+"/.config/sensei-den/companion.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.focusDimming=JSON.parse(text()).focusDimming===true;}catch(e){}}}
    property string output: ""
    property string focusedOutput: ""
    property real px: 0
    property real py: 0
    property bool active: false
    property real phase: 0
    IpcHandler {
        target: "den-cursor"
        function state(): string { return JSON.stringify({focusedOutput:root.focusedOutput,dimOpacity:root.focusDimming?36/255:0,locatorActive:root.active}) }
        function reloadCompanion():void {root.companionRevision=Date.now()}
        function focus(name: string): void { root.focusedOutput=name }
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
    Variants {
        model: Quickshell.screens.filter(s => !s.name.startsWith("SENSEI-REFOCUS"))
        Scope {
            required property var modelData
            id: screenScope
            property var display: modelData
            PanelWindow {screen:screenScope.display;visible:root.focusedOutput===(screenScope.display?.name??"");anchors {top:true} implicitWidth:150;implicitHeight:4;color:"#f23d70";exclusionMode:ExclusionMode.Ignore;WlrLayershell.layer:WlrLayer.Overlay;WlrLayershell.namespace:"den-focus-beacon";WlrLayershell.keyboardFocus:WlrKeyboardFocus.None;mask:Region {}}
            Variants {
                model: ["top-right", "bottom-right", "top-left", "bottom-left"]
                PanelWindow {
                    required property var modelData
                    screen: screenScope.display
                    visible: true
                    color: "transparent"
                    implicitWidth: 44; implicitHeight: 44
                    anchors { right:modelData.endsWith("right");left:modelData.endsWith("left");top:modelData.startsWith("top");bottom:modelData.startsWith("bottom") }
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.namespace: "den-focus-indicator"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                    mask: Region {}
                    property bool focusedDisplay: root.focusedOutput===(screenScope.display?.name??"")
                    Item {
                        anchors.fill: parent
                        opacity: focusedDisplay ? 1 : .16
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                        Rectangle { x:5; y:modelData.startsWith("top")?4:36; width:35; height:focusedDisplay?4:2; color:focusedDisplay?"#f23d70":"#82777c" }
                        Rectangle { x:modelData.endsWith("right")?36:5; y:4; width:focusedDisplay?4:2; height:36; color:focusedDisplay?"#f23d70":"#82777c" }
                    }
                }
            }
        }
    }

    // A solid translucent surface: no blur, shader, polling or idle animation.
    Variants {
        model: Quickshell.screens.filter(s => !s.name.startsWith("SENSEI-REFOCUS"))
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.focusDimming && root.focusedOutput !== modelData.name
            color: "#24000000"
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "den-focus-dim"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}
        }
    }

}
