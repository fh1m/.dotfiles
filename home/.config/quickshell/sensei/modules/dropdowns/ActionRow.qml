import QtQuick
import qs.components
import qs.config

// Secondary action: a readable list row, not another toggle tile.
BarSurface {
    id: root
    property string label: ""
    property string detail: ""
    property string glyph: ""
    signal activated()
    implicitHeight: 50
    hovered: pointer.containsMouse
    pressed: pointer.pressed
    Accessible.role: Accessible.Button
    Accessible.name: label

    Text { textFormat: Text.PlainText; x: 14; anchors.verticalCenter: parent.verticalCenter; text: root.glyph; font.family: Appearance.font.icons; font.pixelSize: 24; color: Theme.widgetAccent }
    Column { x: 47; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 72; spacing: 2
        Text { textFormat: Text.PlainText; width: parent.width; text: root.label; elide: Text.ElideRight; font.family:Appearance.font.reading; font.pixelSize: Appearance.textSize.body; font.weight: Font.Medium; color: Theme.widgetText }
        Text { textFormat: Text.PlainText; width: parent.width; visible: text !== ""; text: root.detail; elide: Text.ElideRight; font.family:Appearance.font.reading; font.pixelSize: Appearance.textSize.caption; color: Theme.widgetMuted }
    }
    Text { textFormat: Text.PlainText; anchors.right: parent.right; anchors.rightMargin: 13; anchors.verticalCenter: parent.verticalCenter; text: "›"; font.family:Appearance.font.reading; font.pixelSize: 19; color: pointer.containsMouse ? Theme.widgetAccent : Theme.widgetMuted }
    MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.activated() }
}
