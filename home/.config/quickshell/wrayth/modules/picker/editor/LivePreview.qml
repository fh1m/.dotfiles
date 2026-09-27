import QtQuick
import qs.components
import qs.config
import qs.modules.picker.mini

// What the palette being edited would look like: the bar, a few terminal rows
// with a selection in them, and the SYS.DIAG panel. The same two miniatures
// the picker's cards use, with the terminal added -- the terminal is where
// most of a palette's work is seen, and `bright` on `ground` is the one pair
// no swatch can show you.
Item {
    id: root

    required property var previewPalette

    implicitHeight: 300

    Rectangle {
        anchors.fill: parent
        color: root.previewPalette.ground
        border.width: Appearance.metrics.hairline
        border.color: root.previewPalette.hair
    }

    MiniBar {
        id: bar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: 20
        previewPalette: root.previewPalette
    }

    MiniDiag {
        id: diag

        anchors.top: bar.bottom
        anchors.right: parent.right
        anchors.topMargin: 18
        anchors.rightMargin: 14
        previewPalette: root.previewPalette
    }

    // A terminal, in the colours `wrayth-profile` writes into kitty's
    // config: the prompt in accent, body in text, katakana in signal, warnings
    // in alert, and the selection reversed -- `ground` on `bright`, which is
    // the locked rule and the same contrast in every previewPalette.
    Column {
        anchors.top: bar.bottom
        anchors.left: parent.left
        anchors.topMargin: 18
        anchors.leftMargin: 14
        anchors.right: diag.left
        anchors.rightMargin: 16
        spacing: 7

        Row {
            spacing: 6

            Text {
                text: "wrayth"
                color: root.previewPalette.accent
                font.family: Appearance.font.data
                font.pixelSize: 11
                font.weight: Appearance.font.weightSemi
                renderType: Text.NativeRendering
            }

            Text {
                text: "~/deck"
                color: root.previewPalette.signal
                font.family: Appearance.font.data
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }

            Text {
                text: "$"
                color: root.previewPalette.dim
                font.family: Appearance.font.data
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }
        }

        Text {
            text: "ICE NOMINAL // 25 SERVICES // UPLINK 12MS"
            color: root.previewPalette.text
            font.family: Appearance.font.data
            font.pixelSize: 11
            renderType: Text.NativeRendering
        }

        // The selection sample. It is a filled box rather than a real
        // selection because there is nothing here to select; the colours are
        // the ones kitty is given.
        Rectangle {
            width: selected.implicitWidth + 8
            height: selected.implicitHeight + 4
            color: root.previewPalette.bright

            Text {
                id: selected

                anchors.centerIn: parent
                text: "SELECTED TEXT READS LIKE THIS"
                color: root.previewPalette.ground
                font.family: Appearance.font.data
                font.pixelSize: 11
                font.weight: Appearance.font.weightSemi
                renderType: Text.NativeRendering
            }
        }

        Row {
            spacing: 8

            Text {
                text: "ОНЛАЙН"
                color: root.previewPalette.signal
                font.family: Appearance.font.accent
                font.letterSpacing: 0
                font.pixelSize: 12
                font.weight: Appearance.font.weightMedium
                renderType: Text.NativeRendering
            }

            Text {
                text: "2 PACKAGES PENDING"
                color: root.previewPalette.alert
                font.family: Appearance.font.data
                font.pixelSize: 11
                font.weight: Appearance.font.weightSemi
                renderType: Text.NativeRendering
            }
        }

        Text {
            text: "these are the labels that sit under everything"
            color: root.previewPalette.dim
            font.family: Appearance.font.data
            font.pixelSize: 10
            renderType: Text.NativeRendering
        }
    }
}
