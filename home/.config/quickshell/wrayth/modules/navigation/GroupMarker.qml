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
        readonly property int groupWorkspace: ActiveWindow.ipc?.workspace?.id ?? -1
        readonly property int shownWorkspace: monitor?.activeWorkspace?.id ?? -2
        screen: modelData
        color: "transparent"
        visible: ActiveWindow.present && members.length > 1 && groupWorkspace === shownWorkspace && WindowDesk.focusScreen === modelData.name && !ShellState.locked
        implicitWidth: Math.max(1, ActiveWindow.width)
        implicitHeight: 29
        anchors { top: true; left: true }
        margins.left: Math.max(0, ActiveWindow.x - (monitor?.lastIpcObject?.x ?? 0))
        margins.top: Math.max(0, ActiveWindow.y - (monitor?.lastIpcObject?.y ?? 0) - 30)
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "sensei-tabs"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}
        // Hyprland owns the invisible click/drag targets. This inset surface
        // gives the tabs the same clipped-corner vocabulary as the windows.
        Canvas {
            anchors.fill: parent
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const p = getContext("2d")
                p.reset()
                const inset = 8, cut = 8, h = height - 1
                p.fillStyle = Theme.ink
                p.beginPath()
                p.moveTo(inset + cut, 0)
                p.lineTo(width - inset - cut, 0)
                p.lineTo(width - inset, cut)
                p.lineTo(width - inset, h - cut)
                p.lineTo(width - inset - cut, h)
                p.lineTo(inset + cut, h)
                p.lineTo(inset, h - cut)
                p.lineTo(inset, cut)
                p.closePath()
                p.fill()
            }
        }
        Repeater {
            model: marker.members
            Item {
                id: tab
                required property string modelData
                required property int index
                readonly property var groupWindow: Hyprland.toplevels.values.find(t => WindowDesk.addressFor(t) === modelData) ?? null
                readonly property string tabTitle: Demo.active
                    ? (WindowDesk.desktopEntryFor(groupWindow)?.name ?? groupWindow?.lastIpcObject?.class ?? "Window")
                    : (groupWindow?.title ?? groupWindow?.lastIpcObject?.title ?? "Window")
                readonly property real tabWidth: marker.width / Math.max(1, marker.members.length)
                readonly property bool current: marker.position === index + 1
                x: index * tabWidth
                width: Math.max(1, tabWidth)
                height: marker.height - 2
                Rectangle {
                    visible: index > 0
                    x: 0; y: 5; width: 1; height: 18
                    color: Theme.rule
                }
                Row {
                    id: titleGroup
                    anchors.centerIn: parent
                    spacing: 10
                    Item {
                        width: 16; height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        Image {
                            id: appArt
                            anchors.fill: parent
                            source: WindowDesk.iconFor(tab.groupWindow)
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
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tab.tabTitle
                        textFormat: Text.PlainText
                        width: Math.min(implicitWidth, Math.max(1, tab.tabWidth - 160))
                        elide: Text.ElideRight
                        color: tab.current ? Theme.paper : Theme.paperMuted
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 12
                        font.weight: tab.current ? Font.Bold : Font.DemiBold
                        renderType: Text.NativeRendering
                    }
                }
                Rectangle {
                    visible: tab.current
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: titleGroup.horizontalCenter
                    width: Math.min(98, titleGroup.implicitWidth)
                    height: 2
                    color: Theme.signalRed
                }
            }
        }
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 22
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
