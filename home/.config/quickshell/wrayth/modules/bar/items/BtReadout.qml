import QtQuick
import Quickshell.Bluetooth
import qs.components
import qs.config
import qs.services
import qs.modules.bar

Item {
    id: root
    property bool condensed: false
    clip: true

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connectedDevices:(Bluetooth.devices?.values??[]).filter(d=>d.connected)
    readonly property bool audioPlaying:Cava.live&&Audio.audible&&/^bluez_output\./.test(Audio.sink?.name||'')

    implicitWidth: condensed ? 44 : 116
    implicitHeight: 34
    Behavior on implicitWidth { NumberAnimation { duration: Theme.motionTravel; easing.type: Easing.OutCubic } }
    BarSurface { anchors.fill: parent; grouped:true; selected: ShellState.dropdown === "bluetooth"; hovered: btHover.hovered; pressed: btTap.pressed }
    Row {
        id: readout
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

    // The rune stands in for the word `BT`, so it keeps that word's grey in
    // every state. The device name beside it is what carries the reading.
    Item {
        width: 24; height: 24
        y: (readout.height - height) / 2
        InstrumentIcon {
            id:musicRune
            anchors.centerIn: parent
            kind: "bluetooth"
            ink:root.audioPlaying?Theme.signalRed:root.connectedDevices.length?Theme.signalRed:Theme.alpha(Theme.signalRed,.55)
            SequentialAnimation on scale {
                running: ShellState.ambientMotion && root.audioPlaying && musicRune.visible
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 1.12; duration: 420; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.12; to: 1; duration: 420; easing.type: Easing.InOutSine }
            }
        }
    }
    // Left-aligned so a short name sits next to the label, but capped at 120px
    // so a long one truncates instead of pushing the ticker around.
    Column { visible: !root.condensed; y: (readout.height - height) / 2; spacing: -1
        Text {text:"Bluetooth";font.family:Appearance.font.barUi;font.pixelSize:12;font.weight:Font.DemiBold;color:Theme.text}
        Text {text:!root.adapter||!root.adapter.enabled?"Off":root.connectedDevices.length?`${root.connectedDevices.length} linked`:"Ready";font.family:Appearance.font.barUi;font.pixelSize:10;color:root.connectedDevices.length?Theme.widgetAccent:Theme.dim}
    }

    }

    // Opens the bluetooth dropdown under this readout. TapHandler rather than a
    // MouseArea, so the Row does not try to lay the handler out as a child.
    HoverHandler { id: btHover
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
    TapHandler { id: btTap
        onTapped: {
            ShellState.dropdownAnchorX = root.mapToItem(null, 0, 0).x;
            ShellState.toggleDropdown("bluetooth");
        }
    }

}
