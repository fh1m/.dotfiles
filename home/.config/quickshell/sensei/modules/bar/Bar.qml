import QtQuick
import Quickshell
import Quickshell.Io
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
        IpcHandler {target:"bar-controls-"+bar.modelData.name;function expand(value:string):void {bar.readoutsOpen=value==="on";}function state():string {return JSON.stringify({expanded:bar.readoutsOpen});}}
        screen: modelData
        color: "transparent"
        implicitHeight: Appearance.metrics.barHeight
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "sensei-bar"
        anchors { top: true; left: true; right: true }
        Component.onCompleted: {ShellState.barWindow = bar;ShellState.registerBar(modelData.name+":top",bar);}
        Component.onDestruction: ShellState.registerBar(modelData.name+":top",null)
        HoverHandler { onHoveredChanged: {ShellState.barHovered = hovered;if(hovered)ShellState.barContext(bar.modelData.name);} }
        property bool inhibitReady: false
        property bool readoutsOpen: false
        Timer { interval: 1000; running: true; onTriggered: bar.inhibitReady = true }
        IdleInhibitor { window: bar; enabled: Idle.hold && bar.inhibitReady }
        Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.barBg, .94) }
        MouseArea {
            anchors.fill: parent
            property int stamp: 0
            onPressed: stamp = ShellState.dropdownStamp
            onClicked: if (stamp === ShellState.dropdownStamp) ShellState.dropdown = ""
        }
        RobotIdentity {
            id: identity
            anchors.left: parent.left
            anchors.leftMargin: 6
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
            anchors.leftMargin: 8
            height: bar.height
            width: Math.min(implicitWidth,clock.x-identity.x-identity.width-32)
            anchors.verticalCenter: parent.verticalCenter
        }
        CompanionPerch {
            output:bar.modelData.name;edge:"top"
            freeLeft:clock.x+clock.width+12;freeRight:controls.x-12
            anchors.verticalCenter:parent.verticalCenter
        }
        Row {
            id: controls
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            RailFold { opensRight:false; expanded: bar.readoutsOpen; onToggled: bar.readoutsOpen = !bar.readoutsOpen; anchors.verticalCenter: parent.verticalCenter }
            EthernetButton {condensed:!bar.readoutsOpen;anchors.verticalCenter:parent.verticalCenter}
            BtReadout { condensed: !bar.readoutsOpen; anchors.verticalCenter: parent.verticalCenter }
            DisplayBadge { output: "main"; condensed: !bar.readoutsOpen; anchors.verticalCenter: parent.verticalCenter }
            SoundButton { condensed: !bar.readoutsOpen; anchors.verticalCenter: parent.verticalCenter }
            NotificationsButton { condensed: !bar.readoutsOpen; anchors.verticalCenter: parent.verticalCenter }
            BatteryButton { visible:!MachineProfile.desktop; condensed: !bar.readoutsOpen; anchors.verticalCenter: parent.verticalCenter }
            SystemButton { condensed: !bar.readoutsOpen; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
