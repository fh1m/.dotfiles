import QtQuick
import qs.components
import qs.config
import qs.services

BarSurface {
    id: root
    property bool condensed: false
    clip: true
    implicitWidth: condensed ? 44 : 106; implicitHeight: 34
    grouped: condensed
    Behavior on implicitWidth { NumberAnimation { duration: Theme.motionTravel; easing.type: Easing.OutCubic } }
    selected: ShellState.dropdown === "system"
    hovered: pointer.containsMouse
    pressed: pointer.pressed
    Row {anchors.left:parent.left;anchors.leftMargin:10;anchors.verticalCenter:parent.verticalCenter;spacing:7
        InstrumentIcon {anchors.verticalCenter:parent.verticalCenter;kind:"system";ink:Theme.signalRed}
        Column {visible:!root.condensed;anchors.verticalCenter:parent.verticalCenter;spacing:-1
            Text {text:"System";font.family:Appearance.font.barUi;font.pixelSize:12;font.weight:Font.DemiBold;color:Theme.text}
            Text {text:"Controls";font.family:Appearance.font.barUi;font.pixelSize:10;color:Theme.widgetMuted}
        }
    }
    function publish(): void { ShellState.publishAnchor("system", root.mapToItem(null, 0, 0).x); }
    onXChanged: publish()
    Component.onCompleted: Qt.callLater(publish)
    MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { ShellState.dropdownAnchorX = root.mapToItem(null, 0, 0).x; ShellState.toggleDropdown("system"); } }
}
