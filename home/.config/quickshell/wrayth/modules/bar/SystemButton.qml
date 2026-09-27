import QtQuick
import qs.components
import qs.config
import qs.services

Rectangle {
    id: root
    implicitWidth: 104; implicitHeight: 28
    radius: 2
    color: ShellState.dropdown === "system" || pointer.containsMouse ? Theme.alpha(Theme.signal, 0.15) : "transparent"
    border.color: "#26282d"
    border.width: 1
    Behavior on color { ColorAnimation { duration: 120 } }
    NrLabel { pixelSize: 12; font.letterSpacing: 0.7; anchors.centerIn: parent; text: "\uf1de SYSTEM"; color: Theme.text }
    function publish(): void { ShellState.publishAnchor("system", root.mapToItem(null, 0, 0).x); }
    onXChanged: publish()
    Component.onCompleted: Qt.callLater(publish)
    MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { ShellState.dropdownAnchorX = root.mapToItem(null, 0, 0).x; ShellState.toggleDropdown("system"); } }
}
