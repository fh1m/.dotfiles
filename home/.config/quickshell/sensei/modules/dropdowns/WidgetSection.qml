import QtQuick
import qs.components
import qs.config

// Shared quiet card: one section, one title, one visual boundary.
Item {
    id: root
    property string title: ""
    property string subtitle: ""
    property string glyph: ""
    property color accent: Theme.widgetAccent
    default property alias body: content.data
    implicitHeight: content.y + content.childrenRect.height + 12

    ChamferPanel {
        anchors.fill: parent
        chamfer: 7
        scanlines: false
        fillColor: Theme.widgetSurface
        borderColor: Theme.alpha(Theme.widgetText, .075)
        borderWidth: 1
    }
    Text {
        x: 13; y: 10
        text: root.glyph
        visible: text !== ""
        font.family: Appearance.font.icons
        font.pixelSize: 18
        color: root.accent
    }
    Text {
        x: root.glyph === "" ? 14 : 39; y: 10
        text: root.title
        font.family: Appearance.font.heading
        font.pixelSize: 13
        font.weight: Font.Medium
        color: Theme.widgetText
    }
    Text {
        anchors.right: parent.right; anchors.rightMargin: 13; y: 14
        visible: root.subtitle !== ""
        text: root.subtitle
        font.family: Appearance.font.ui
        font.pixelSize: 11
        color: Theme.widgetMuted
    }
    Item { id: content; x: 12; y: 39; width: parent.width - 24; height: childrenRect.height }
}
