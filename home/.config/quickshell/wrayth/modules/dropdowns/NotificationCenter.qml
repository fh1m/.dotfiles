import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

DropdownFrame {
    id: root
    title: "\uf0f3 Notifications"
    katakana: "СООБЩЕНИЯ"
    implicitWidth: 510
    headerRight: Text {
        text: Notifications.history.length + " recent"
        font.family: Appearance.font.ui
        font.pixelSize: 10
        color: Theme.widgetMuted
    }
    Column {
        width: parent.width
        spacing: 10
        Row {
            spacing: 8
            ControlTile { implicitWidth: 216; label: Notifications.doNotDisturb ? "Quiet mode on" : "Quiet mode off"; glyph: "\uf186"; selected: Notifications.doNotDisturb; onActivated: Notifications.doNotDisturb = !Notifications.doNotDisturb }
            ControlTile { implicitWidth: 216; label: "Clear history"; glyph: "\uf1f8"; enabled: Notifications.history.length > 0; onActivated: Notifications.clearHistory() }
        }
        Text {
            visible: Notifications.history.length === 0
            text: "All caught up, Sensei."
            font.family: Appearance.font.ui
            font.pixelSize: 12
            color: Theme.widgetMuted
        }
        Flickable {
            width: parent.width
            height: Math.min(550, Math.max(0, entries.height))
            contentHeight: entries.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: entries
                width: parent.width
                spacing: 7
                Repeater {
                    model: Notifications.history
                    ChamferPanel {
                        required property var modelData
                        width: entries.width
                        height: body.implicitHeight + 24
                        chamfer: 7
                        scanlines: false
                        fillColor: Theme.widgetSurface
                        borderColor: Theme.widgetBorder
                        Column {
                            id: body
                            x: 12; y: 10
                            width: parent.width - 24
                            spacing: 4
                            Row {
                                width: parent.width
                                spacing: 8
                                Image {
                                    width: 18; height: 18
                                    source: {
                                        const icon = String(modelData.icon || "");
                                        return !icon ? "" : icon.startsWith("/") ? "file://" + icon : icon.startsWith("image://") || icon.startsWith("file://") ? icon : Quickshell.iconPath(icon, true);
                                    }
                                    sourceSize: Qt.size(36, 36)
                                    visible: status === Image.Ready
                                    asynchronous: true
                                }
                                Text { text: modelData.app; width: parent.width - 95; elide: Text.ElideRight; font.family: Appearance.font.ui; font.pixelSize: 11; color: Theme.widgetAccent }
                                Text { text: modelData.time; font.family: Appearance.font.data; font.pixelSize: 9; color: Theme.widgetMuted }
                            }
                            Text { width: parent.width; text: modelData.summary; textFormat: Text.PlainText; wrapMode: Text.Wrap; font.family: Appearance.font.ui; font.pixelSize: 12; font.weight: Font.DemiBold; color: Theme.widgetText }
                            Text { visible: text !== ""; width: parent.width; text: modelData.body; textFormat: Text.RichText; wrapMode: Text.Wrap; maximumLineCount: 4; elide: Text.ElideRight; font.family: Appearance.font.ui; font.pixelSize: 11; color: Theme.widgetMuted }
                        }
                    }
                }
            }
        }
    }
}
