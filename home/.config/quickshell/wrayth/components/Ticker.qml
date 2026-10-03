import QtQuick
import qs.config
import qs.services

// Two copies make a seamless marquee. Animate a single item transform rather
// than driving every glyph through a global JavaScript clock and two FBO masks.
Item {
    id: root

    property string text: ""
    property color foreground:Theme.dim
    property int pixelSize:Appearance.size.ticker
    property bool scrollOnlyOverflow:false
    property bool scrollEnabled:true
    property real loopGap:0
    property real speed: Appearance.metrics.tickerSpeed
    property real fade: Appearance.metrics.tickerFade

    readonly property real contentWidth: first.implicitWidth

    Item {
        id: viewport

        anchors.fill: parent
        clip: true

        Item {
            id: strip

            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: first.implicitHeight

            // Scrolls the width of one copy, then loops; the second copy is
            // exactly where the first started, so the seam never shows.
            property real offset: 0
            NumberAnimation on offset {
                from: 0
                to: Math.max(1, root.contentWidth + root.loopGap)
                duration: Math.max(1000, Math.round(1000 * (root.contentWidth + root.loopGap) / Math.max(1, root.speed)))
                loops: Animation.Infinite
                running: root.scrollActive && ShellState.ambientMotion
            }

            Text {
                id: first

                x: root.scrollOnlyOverflow && root.contentWidth <= root.width ? (root.width-root.contentWidth)/2 : -(ShellState.ambientMotion ? strip.offset : 0)
                color: root.foreground
                text: root.text
                font.family: Appearance.font.data
                font.pixelSize: root.pixelSize
                font.letterSpacing: Appearance.size.ticker * Appearance.tickerTracking
                renderType: Text.QtRendering
                renderTypeQuality: 104
            }

            Text {
                id: second

                x: first.x + root.contentWidth + root.loopGap
                visible: !root.scrollOnlyOverflow || root.contentWidth > root.width
                color: first.color
                text: first.text
                font: first.font
                renderType: Text.QtRendering
                renderTypeQuality: 104
            }

            // Only earns its keep if the line is ever shorter than the viewport,
            // where two copies would leave a gap at the end of a loop.
            Text {
                x: second.x + root.contentWidth + root.loopGap
                visible: !root.scrollOnlyOverflow && root.contentWidth < root.width
                color: first.color
                text: first.text
                font: first.font
                renderType: Text.QtRendering
                renderTypeQuality: 104
            }
        }
    }

    readonly property bool scrollActive: root.visible && root.scrollEnabled && root.contentWidth > 0 && (!root.scrollOnlyOverflow || root.contentWidth > root.width)
}
