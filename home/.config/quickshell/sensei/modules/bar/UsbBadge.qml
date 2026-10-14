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

    implicitWidth: condensed ? 44 : Math.min(220, label.implicitWidth + 54); implicitHeight: 34
    Behavior on implicitWidth { NumberAnimation { duration: Theme.motionTravel; easing.type: Easing.OutCubic } }
    grouped:condensed
    selected:ShellState.dropdown==="usb";hovered:usbPointer.containsMouse;pressed:usbPointer.pressed
    Row {
        anchors.left: parent.left; anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter; spacing: 6
        BarIcon { glyph: "\uf287"; anchors.verticalCenter: parent.verticalCenter; inkSize: 18; ink: UsbLab.presence.count > 0 ? Theme.signalRed : Theme.dim }
        Text {
            id: label
            visible: !root.condensed
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(164, implicitWidth)
            elide: Text.ElideRight
            text: root.deviceIndex >= 0 && root.deviceIndex < root.devices.length ? root.devices[root.deviceIndex] : `USB ${UsbLab.presence.count}`
            font.family: Appearance.font.barUi; font.pixelSize: 12
            color: UsbLab.presence.count > 0 ? Theme.paper : Theme.paperMuted
        }
    }
    MouseArea { id:usbPointer; anchors.fill: parent; hoverEnabled:true; cursorShape: Qt.PointingHandCursor; onWheel: event => { if (root.devices.length) { const count = root.devices.length + 1; root.deviceIndex = ((root.deviceIndex + 1 + (event.angleDelta.y > 0 ? 1 : -1) + count) % count) - 1; } event.accepted = true; }; onClicked: { ShellState.dropdownAnchorX = root.mapToItem(null,0,0).x; ShellState.toggleDropdown("usb"); } }
}
