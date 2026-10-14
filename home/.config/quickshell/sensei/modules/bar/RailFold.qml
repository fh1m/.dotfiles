import QtQuick
import qs.components
import qs.config

BarSurface {
    id: root
    property bool expanded: false
    property bool opensRight: true
    signal toggled()
    implicitWidth: 32
    implicitHeight: 34
    grouped: true
    hovered: pointer.containsMouse
    pressed: pointer.pressed
    Text {
        anchors.centerIn: parent
        text: root.expanded ? (root.opensRight ? "‹" : "›") : (root.opensRight ? "›" : "‹")
        color: root.expanded ? Theme.signalRed : Theme.paperMuted
        font.family: Appearance.font.display
        font.pixelSize: 22
        font.weight: Font.DemiBold
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
