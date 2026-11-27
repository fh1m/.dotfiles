import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root
    property int generation: 0
    property int swaps: 0
    PanelWindow {
        id: probe
        screen: Quickshell.screens.find(s => s.name === Quickshell.env("SENSEI_EGL_TEST_OUTPUT")) || Quickshell.screens[0]
        anchors { top: true; left: true }
        margins.top: 100
        margins.left: 100
        implicitWidth: 192
        implicitHeight: 128
        visible: true
        color: root.generation % 2 ? "#00cc88" : "#6633cc"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: Quickshell.env("SENSEI_EGL_TEST_ID")
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region { width: 0; height: 0 }
        Item {
            id: paintSurface
            anchors.fill: parent
            Connections {
                target: paintSurface.Window.window
                function onFrameSwapped() { root.swaps++ }
            }
        }
    }
    Timer { interval: 250; running: true; repeat: true; onTriggered: root.generation++ }
    IpcHandler {
        target: "egl-recovery-probe"
        function state(): string {
            return JSON.stringify({generation: root.generation, swaps: root.swaps, width: probe.width, height: probe.height})
        }
        function resize(width: int, height: int): string {
            probe.implicitWidth = width
            probe.implicitHeight = height
            return state()
        }
    }
}
