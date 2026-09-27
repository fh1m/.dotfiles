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
        screen: modelData
        color: "transparent"
        implicitHeight: Appearance.metrics.barHeight
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "wrayth-bar"
        anchors { bottom: true; left: true; right: true }
        Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.barBg, 0.92); border.width:1; border.color:"#181a1e" }
        Row {
            id: meters
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7
            TrayGroup { anchors.verticalCenter: parent.verticalCenter }
            ArchiveButton { anchors.verticalCenter: parent.verticalCenter }
            ArchiveButton { target: "clipboard"; label: "CLIPBOARD"; glyph: "\uf0ea"; anchors.verticalCenter: parent.verticalCenter }
            ArchiveButton { target: "phone"; label: PhoneBridge.ready ? "Phone · online" : "Phone"; glyph: "\uf10b"; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            id: navigation
            anchors.centerIn: parent
            spacing: 10
            PageMarker { anchors.verticalCenter: parent.verticalCenter }
            Workspaces { id: workspaces; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            spacing: 12
            UsbBadge { anchors.verticalCenter: parent.verticalCenter }
            SimLaunchpad { anchors.verticalCenter: parent.verticalCenter }
            DisplayBadge { output: "screenpad"; anchors.verticalCenter: parent.verticalCenter }
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 1; color: "#181a1e" }
        Scanlines { surface: "panel" }
    }
}
