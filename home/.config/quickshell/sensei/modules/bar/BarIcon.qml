import QtQuick
import qs.components
import qs.config

// A fixed control slot; Glyph centers the visible ink rather than the font line.
Item {
    id: root
    property string glyph: ""
    property color ink: Theme.paper
    property real inkSize: 19
    implicitWidth: 24
    implicitHeight: 24
    Glyph {
        anchors.centerIn: parent
        text: root.glyph
        color: root.ink
        pixelSize: root.inkSize
        family: Appearance.font.icons
    }
}
