import QtQuick
import qs.components
import qs.config
import qs.services

Item {
    id: root
    property string output: "screenpad"
    readonly property real level: output === "main" ? (RobotBench.data.mainBrightness ?? 0) : (RobotBench.data.brightness ?? 0)
    implicitWidth: label.implicitWidth + 14
    implicitHeight: 28
    Rectangle { anchors.fill: parent; color: hover.containsMouse ? Theme.alpha(Theme.signal, 0.10) : "transparent"; border.color: "#26282d"; border.width: 1; radius: 2; Behavior on color { ColorAnimation { duration: 120 } } }
    NrLabel { pixelSize: 12; font.letterSpacing: 0.7; id: label; anchors.centerIn: parent; text: `\uf185 ${root.output === "main" ? "MAIN" : "PAD"} ${Math.round(root.level)}%`; color: Theme.text }
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onWheel: event => { DisplayControls.adjustLevel(root.output, event.angleDelta.y > 0 ? 5 : -5); event.accepted = true; }
        onClicked: { ShellState.dropdownAnchorX = ShellState.anchorFor("system"); ShellState.toggleDropdown("system"); }
    }
}
