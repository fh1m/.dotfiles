import QtQuick
import qs.components
import qs.config
import qs.services

BarSurface {
    id: root
    property bool condensed: false
    clip: true
    implicitWidth: condensed ? 44 : 115
    implicitHeight: 34
    grouped: condensed
    Behavior on implicitWidth { NumberAnimation { duration: Theme.motionTravel; easing.type: Easing.OutCubic } }
    selected: ShellState.dropdown === "notifications"
    hovered: pointer.containsMouse
    pressed: pointer.pressed
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7
        BarIcon { anchors.verticalCenter: parent.verticalCenter; glyph: Notifications.unreadCount ? "\uf0f3" : "\uf0a2"; inkSize: 19; ink: Notifications.unreadCount ? Theme.signalRed : Theme.paperMuted }
        Column { visible: !root.condensed; anchors.verticalCenter: parent.verticalCenter; spacing: -1
            Text { text: "Alerts"; font.family: Appearance.font.barUi; font.pixelSize: 12; font.weight: Font.DemiBold; color: Theme.text }
            Text { text: Notifications.unreadCount ? Notifications.unreadCount + " new" : "Quiet"; font.family: Appearance.font.barUi; font.pixelSize: 10; color: Theme.widgetMuted }
        }
    }
    Rectangle { anchors.bottom:parent.bottom; anchors.horizontalCenter:parent.horizontalCenter; width:root.condensed&&Notifications.unreadCount?17:0; height:2; color:Theme.signalRed }
    Component.onCompleted: Qt.callLater(() => ShellState.publishAnchor("notifications", root.mapToItem(null, 0, 0).x))
    onXChanged: ShellState.publishAnchor("notifications", root.mapToItem(null, 0, 0).x)
    MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Notifications.markRead(); ShellState.dropdownAnchorX = root.mapToItem(null, 0, 0).x; ShellState.toggleDropdown("notifications"); } }
}
