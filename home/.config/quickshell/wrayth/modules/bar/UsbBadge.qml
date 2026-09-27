import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

Rectangle {
    id: root
    property int deviceIndex: -1
    readonly property var devices: UsbLab.presence.devices ?? []

    implicitWidth: Math.min(220, label.implicitWidth + 18); implicitHeight: 30
    radius: 2; color: "transparent"; border.width: 1; border.color: "#26282d"
    NrLabel { centred: true; pixelSize: 12; font.letterSpacing: 0.7; id: label; anchors.centerIn: parent; width: Math.min(210, implicitWidth); elide: Text.ElideRight; text: root.deviceIndex >= 0 && root.deviceIndex < root.devices.length ? `\uf287 ${root.devices[root.deviceIndex]}` : `\uf287 USB ${UsbLab.presence.count}`; color: UsbLab.presence.count > 0 ? Theme.signal : Theme.dim }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onWheel: event => { if (root.devices.length) { const count = root.devices.length + 1; root.deviceIndex = ((root.deviceIndex + 1 + (event.angleDelta.y > 0 ? 1 : -1) + count) % count) - 1; } event.accepted = true; }; onClicked: { ShellState.dropdownAnchorX = root.mapToItem(null,0,0).x; ShellState.toggleDropdown("usb"); } }
}
