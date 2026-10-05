import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import qs.modules.bar.items

// fh1m's main-panel flight strip: identity, ticker, centered clock, network.
Variants {
    model: ShellState.barScreens
    PanelWindow {
        id: bar
        required property ShellScreen modelData
        screen: modelData
        color: "transparent"
        implicitHeight: Appearance.metrics.barHeight
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "wrayth-bar"
        anchors { top: true; left: true; right: true }
        Component.onCompleted: ShellState.barWindow = bar
        HoverHandler { onHoveredChanged: ShellState.barHovered = hovered }
        property bool inhibitReady: false
        property bool readoutsOpen: false
        Timer { interval: 1000; running: true; onTriggered: bar.inhibitReady = true }
        IdleInhibitor { window: bar; enabled: Idle.hold && bar.inhibitReady }
        Rectangle { anchors.fill: parent; color: Theme.barBg }
        MouseArea {
            anchors.fill: parent
            property int stamp: 0
            onPressed: stamp = ShellState.dropdownStamp
            onClicked: if (stamp === ShellState.dropdownStamp) ShellState.dropdown = ""
        }
        RobotIdentity {
            id: identity
            anchors.left: parent.left
            anchors.top: parent.top
            width: implicitWidth
            height: bar.height
        }
        BarClock {
            id: clock
            anchors.centerIn: parent
        }
        SpotifyButton {
            anchors.left: identity.right
            anchors.leftMargin: 13
            height: bar.height
            width: Math.min(implicitWidth,clock.x-identity.width-24)
            anchors.verticalCenter: parent.verticalCenter
        }
        Row {
            id: controls
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            RailFold { expanded: bar.readoutsOpen; onToggled: bar.readoutsOpen = !bar.readoutsOpen; anchors.verticalCenter: parent.verticalCenter }
            BtReadout { condensed: !bar.readoutsOpen; anchors.verticalCenter: parent.verticalCenter }
            DisplayBadge { output: "main"; condensed: !bar.readoutsOpen; anchors.verticalCenter: parent.verticalCenter }
            SoundButton { condensed: !bar.readoutsOpen; anchors.verticalCenter: parent.verticalCenter }
            NotificationsButton { condensed: !bar.readoutsOpen; anchors.verticalCenter: parent.verticalCenter }
            SystemButton { condensed: !bar.readoutsOpen; anchors.verticalCenter: parent.verticalCenter }
        }
        Rectangle { x: 51; anchors.bottom: parent.bottom; width: 38; height: 2; color: Theme.signalRed }

    }
}
