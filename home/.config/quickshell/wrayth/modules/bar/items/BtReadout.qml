import QtQuick
import Quickshell.Bluetooth
import qs.components
import qs.config
import qs.services

Item {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connectedDevices:(Bluetooth.devices?.values??[]).filter(d=>d.connected)
    readonly property bool audioPlaying:Cava.live&&Audio.audible&&/^bluez_output\./.test(Audio.sink?.name||'')

    implicitWidth: readout.implicitWidth + 18
    implicitHeight: 30
    Rectangle { anchors.fill: parent; radius: 2; color: ShellState.dropdown === "bluetooth" ? Theme.alpha(Theme.signal, 0.10) : "transparent"; border.color: "#26282d"; border.width: 1 }
    Row {
        id: readout
        anchors.centerIn: parent
    spacing: 7

    // The rune stands in for the word `BT`, so it keeps that word's grey in
    // every state. The device name beside it is what carries the reading.
    BluetoothGlyph {
        id:musicRune
        anchors.verticalCenter: parent.verticalCenter
        color:root.audioPlaying?Theme.signal:Theme.dim
        scale: root.audioPlaying ? 1.08 - .08 * Math.cos(MotionClock.ms * Math.PI * 2 / 840) : 1
    }

    // Left-aligned so a short name sits next to the label, but capped at 120px
    // so a long one truncates instead of pushing the ticker around.
    Slot {
        anchors.verticalCenter: parent.verticalCenter

        implicitWidth: Math.min(Appearance.slot.btName, label.implicitWidth)
        horizontalAlignment: Text.AlignLeft

        text: {
            if (!root.adapter || !root.adapter.enabled)
                return "OFF";
            return root.connectedDevices.length ? `Connected [${root.connectedDevices.length}]` : "Disconnected";
        }
        color: root.connectedDevices.length ? Theme.signal : Theme.dim

        // Measures the untruncated name so the slot can shrink below its cap.
        Text {
            renderType: Text.NativeRendering
            id: label

            visible: false
            text: parent.text
            font: parent.font
        }
    }

    }

    // Opens the bluetooth dropdown under this readout. TapHandler rather than a
    // MouseArea, so the Row does not try to lay the handler out as a child.
    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }


    // Published so `dropdown open bluetooth` can hang the panel where a click
    // would have. `mapToItem` is a function call, so it is re-read from a
    // handler rather than bound -- a binding through it captures whatever it
    // returned the first time and never runs again.
    function _publish(): void {
        ShellState.publishAnchor("bluetooth", root.mapToItem(null, 0, 0).x);
    }

    onXChanged: root._publish()
    onWidthChanged: root._publish()
    Component.onCompleted: Qt.callLater(root._publish)
    TapHandler {
        onTapped: {
            ShellState.dropdownAnchorX = root.mapToItem(null, 0, 0).x;
            ShellState.toggleDropdown("bluetooth");
        }
    }

}
