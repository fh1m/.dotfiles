import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
ShellRoot {
    id: root
    property real companionRevision:Date.now()
    Loader {
        id:companionLoader
        asynchronous:true
        source:Quickshell.env("HOME")+"/.local/share/sensei-companion/Companion.qml?v="+root.companionRevision
        onLoaded:item.ownerOutput=Qt.binding(()=>root.focusedOutput)
    }
    property string output: ""
    property string focusedOutput: ""
    property real px: 0
    property real py: 0
    property bool active: false
    property real phase: 0
    IpcHandler {
        target: "den-cursor"
        function state(): string { return JSON.stringify({focusedOutput:root.focusedOutput,dimOpacity:36/255,locatorActive:root.active}) }
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
            Variants {
                model: ["top", "bottom"]
                PanelWindow {
                    required property var modelData
                    screen: screenScope.display
                    visible: true
                    color: "transparent"
                    implicitWidth: 22; implicitHeight: 22
                    anchors { right:true; top:modelData==="top"; bottom:modelData==="bottom" }
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.namespace: "den-focus-indicator"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                    mask: Region {}
                    property bool focusedDisplay: root.focusedOutput===screenScope.display.name
                    Item {
                        anchors.fill: parent
                        opacity: focusedDisplay ? .85 : .23
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                        Rectangle { x:4; y:modelData==="top"?3:17; width:15; height:2; color:focusedDisplay?"#f91b84":"#82777c" }
                        Rectangle { x:17; y:3; width:2; height:16; color:focusedDisplay?"#f91b84":"#82777c" }
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
            visible: root.focusedOutput !== modelData.name
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
