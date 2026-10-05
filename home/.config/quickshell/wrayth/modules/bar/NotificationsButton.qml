import QtQuick
import qs.components
import qs.config
import qs.services

BarSurface {
    id: root
    implicitWidth: 115
    implicitHeight: 34
    selected: ShellState.dropdown === "notifications"
    hovered: pointer.containsMouse
    pressed: pointer.pressed
    Row {
        anchors.centerIn: parent
        spacing: 7
        Text { anchors.verticalCenter: parent.verticalCenter; text: Notifications.unreadCount ? "\uf0f3" : "\uf0a2"; font.family: Appearance.font.icons; font.pixelSize: 19; color: Notifications.unreadCount ? Theme.widgetAccent : Theme.dim }
        Column { anchors.verticalCenter: parent.verticalCenter; spacing: -1
            Text { text: "Alerts"; font.family: Appearance.font.barUi; font.pixelSize: 12; font.weight: Font.DemiBold; color: Theme.text }
            Text { text: Notifications.unreadCount ? Notifications.unreadCount + " new" : "Quiet"; font.family: Appearance.font.barUi; font.pixelSize: 10; color: Theme.widgetMuted }
        }
    }
    Component.onCompleted: Qt.callLater(() => ShellState.publishAnchor("notifications", root.mapToItem(null, 0, 0).x))
    onXChanged: ShellState.publishAnchor("notifications", root.mapToItem(null, 0, 0).x)
    MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Notifications.markRead(); ShellState.dropdownAnchorX = root.mapToItem(null, 0, 0).x; ShellState.toggleDropdown("notifications"); } }
}
