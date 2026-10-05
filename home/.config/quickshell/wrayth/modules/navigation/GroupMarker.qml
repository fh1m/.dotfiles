import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

// A small read-only marker at the edge of Hyprland's native groupbar.
// The native tabs keep click and drag behavior; this surface accepts no input.
Variants {
    model: ShellState.screens
    PanelWindow {
        id: marker
        required property ShellScreen modelData
        readonly property var monitor: Hyprland.monitors.values.find(m => m.name === modelData.name) ?? null
        readonly property var members: ActiveWindow.ipc?.grouped ?? []
        readonly property int position: Math.max(1, members.indexOf(ActiveWindow.ipc?.address) + 1)
        screen: modelData
        color: "transparent"
        visible: ActiveWindow.present && members.length > 1 && WindowDesk.focusScreen === modelData.name && !ShellState.locked
        implicitWidth: Math.max(1, ActiveWindow.width)
        implicitHeight: 29
        anchors { top: true; left: true }
        margins.left: Math.max(0, ActiveWindow.x - (monitor?.lastIpcObject?.x ?? 0))
        margins.top: Math.max(0, ActiveWindow.y - (monitor?.lastIpcObject?.y ?? 0) - 39)
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "sensei-tabs"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}
        Repeater {
            model: marker.members
            Item {
                required property string modelData
                required property int index
                readonly property var groupWindow: WindowDesk.all.find(t => WindowDesk.addressFor(t) === modelData) ?? null
                readonly property string tabTitle: groupWindow?.title ?? groupWindow?.lastIpcObject?.title ?? "Window"
                TextMetrics {
                    id: titleWidth
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    text: parent.tabTitle
                }
                x: (index + .5) * marker.width / Math.max(1, marker.members.length) - titleWidth.advanceWidth / 2 - 83
                y: 7
                width: 17; height: 17
                Image {
                    id: appArt
                    anchors.fill: parent
                    source: WindowDesk.iconFor(parent.groupWindow)
                    sourceSize: Qt.size(32, 32)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: appArt.status !== Image.Ready
                    text: "·"
                    color: Theme.paperMuted
                    font.pixelSize: 15
                }
            }
        }
        Rectangle {
            x: (marker.position - .5) * marker.width / Math.max(1, marker.members.length) - width / 2
            anchors.bottom: parent.bottom
            width: 72
            height: 2
            color: Theme.signalRed
            Behavior on x { SmoothedAnimation { velocity: 1200; maximumEasingTime: 130 } }
        }
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 6
            y: 5
            width: 110
            height: 19
            color: Theme.ink
            radius: Theme.radiusSmall
            border.width: 1
            border.color: Theme.rule
            Rectangle { x: 1; y: 3; width: 2; height: parent.height - 6; color: Theme.signalRed }
            Text {
                anchors.centerIn: parent
                text: `TABS  ${marker.position} / ${marker.members.length}`
                color: Theme.paper
                font.family: Appearance.font.telemetry
                font.pixelSize: 11
                font.weight: Font.DemiBold
                renderType: Text.NativeRendering
            }
        }
    }
}
