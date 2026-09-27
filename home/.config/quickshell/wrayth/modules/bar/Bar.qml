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
        Timer { interval: 1000; running: true; onTriggered: bar.inhibitReady = true }
        IdleInhibitor { window: bar; enabled: Idle.hold && bar.inhibitReady }
        Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.barBg, 0.92); border.width:1; border.color:"#181a1e" }
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
            anchors.leftMargin: -14
            height: bar.height
            width: Math.min(implicitWidth,clock.x-identity.width-24)
            anchors.verticalCenter: parent.verticalCenter
        }
        Row {
            id: controls
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            
            BtReadout { anchors.verticalCenter: parent.verticalCenter }
            DisplayBadge { output: "main"; anchors.verticalCenter: parent.verticalCenter }
            SoundButton { anchors.verticalCenter: parent.verticalCenter }
            SystemButton { anchors.verticalCenter: parent.verticalCenter }
        }
        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: "#181a1e" }
        Rectangle { anchors.left: parent.left; anchors.bottom: parent.bottom; width: identity.width; height: 2; color: Theme.accent }

        Scanlines { surface: "panel" }
    }
}
