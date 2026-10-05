import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

BarSurface {
    id: root
    property bool condensed: false
    clip: true
    property int deviceIndex: -1
    readonly property var devices: UsbLab.presence.devices ?? []

    implicitWidth: condensed ? 48 : Math.min(220, label.implicitWidth + 18); implicitHeight: 34
    Behavior on implicitWidth { NumberAnimation { duration: Theme.motionTravel; easing.type: Easing.OutCubic } }
    grouped:condensed
    selected:ShellState.dropdown==="usb";hovered:usbPointer.containsMouse;pressed:usbPointer.pressed
    NrLabel { centred: true; pixelSize: root.condensed ? 23 : 13; font.letterSpacing: 0.3; id: label; anchors.centerIn: parent; width: root.condensed ? 30 : Math.min(210, implicitWidth); elide: Text.ElideRight; text: root.condensed ? "\uf287" : root.deviceIndex >= 0 && root.deviceIndex < root.devices.length ? `\uf287 ${root.devices[root.deviceIndex]}` : `\uf287 USB ${UsbLab.presence.count}`; color: UsbLab.presence.count > 0 ? Theme.widgetAccent : Theme.dim }
    MouseArea { id:usbPointer; anchors.fill: parent; hoverEnabled:true; cursorShape: Qt.PointingHandCursor; onWheel: event => { if (root.devices.length) { const count = root.devices.length + 1; root.deviceIndex = ((root.deviceIndex + 1 + (event.angleDelta.y > 0 ? 1 : -1) + count) % count) - 1; } event.accepted = true; }; onClicked: { ShellState.dropdownAnchorX = root.mapToItem(null,0,0).x; ShellState.toggleDropdown("usb"); } }
}
