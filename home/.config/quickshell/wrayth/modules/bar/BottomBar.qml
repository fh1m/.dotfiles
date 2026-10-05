import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import qs.modules.bar.items
import qs.modules.dropdowns

// ScreenPad's bottom strip: machine meters, centered workspaces, robot bench.
Variants {
    model: ShellState.bottomBarScreens
    PanelWindow {
        id: bar
        Component.onCompleted: ShellState.bottomBarWindow = bar
        Component.onDestruction: if (ShellState.bottomBarWindow === bar) ShellState.bottomBarWindow = null
        required property ShellScreen modelData
        property bool archiveOpen: false
        property bool machineOpen: false
        screen: modelData
        color: "transparent"
        implicitHeight: Appearance.metrics.barHeight
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "wrayth-bar"
        anchors { bottom: true; left: true; right: true }
        Rectangle { anchors.fill: parent; color: Theme.barBg }
        Row {
            id: meters
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            TrayGroup { anchors.verticalCenter: parent.verticalCenter }
            RailFold { expanded: bar.archiveOpen; onToggled: bar.archiveOpen = !bar.archiveOpen; anchors.verticalCenter: parent.verticalCenter }
            ArchiveButton { condensed: !bar.archiveOpen; anchors.verticalCenter: parent.verticalCenter }
            ArchiveButton { condensed: !bar.archiveOpen; target: "clipboard"; label: "Clipboard"; detail:"History"; glyph: "\uf0ea"; anchors.verticalCenter: parent.verticalCenter }
            ArchiveButton { condensed: !bar.archiveOpen; target: "phone"; label: "Phone"; detail:PhoneBridge.phoneNearby?"Nearby":PhoneBridge.ready?"Online":"Offline"; glyph: "\uf10b"; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            id: navigation
            anchors.centerIn: parent
            spacing: 10
            PageMarker { anchors.verticalCenter: parent.verticalCenter }
            Workspaces { id: workspaces; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            id:machineControls
            spacing: 3
            UsbBadge { condensed: !bar.machineOpen; anchors.verticalCenter: parent.verticalCenter }
            SimLaunchpad { condensed: !bar.machineOpen; anchors.verticalCenter: parent.verticalCenter }
            DisplayBadge { output: "screenpad"; condensed: !bar.machineOpen; anchors.verticalCenter: parent.verticalCenter }
            RailFold { expanded: bar.machineOpen; opensRight: false; onToggled: bar.machineOpen = !bar.machineOpen; anchors.verticalCenter: parent.verticalCenter }
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
