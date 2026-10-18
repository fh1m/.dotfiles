import QtQuick
import Quickshell
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
    showSelectionRule: false
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
            Text { textFormat: Text.PlainText; text: "Alerts"; font.family: Appearance.font.barUi; font.pixelSize: 12; font.weight: Font.DemiBold; color: Theme.text }
            Text { textFormat: Text.PlainText; text: Notifications.unreadCount ? Notifications.unreadCount + " new" : "Quiet"; font.family: Appearance.font.barUi; font.pixelSize: 10; color: Theme.widgetMuted }
        }
    }
    Rectangle {x:29;y:4;width:5;height:5;radius:2.5;visible:Notifications.unreadCount>0;color:Theme.signalRed}

    Component.onCompleted: Qt.callLater(() => ShellState.publishAnchor("notifications", root.mapToItem(null, 0, 0).x,root.QsWindow.window?.screen?.name??""))
    onXChanged: ShellState.publishAnchor("notifications", root.mapToItem(null, 0, 0).x,root.QsWindow.window?.screen?.name??"")
    MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Notifications.markRead(); ShellState.dropdownAnchorX = root.mapToItem(null, 0, 0).x; ShellState.toggleDropdownOn("notifications",root.QsWindow.window?.screen?.name??""); } }
}
