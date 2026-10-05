import QtQuick
import qs.components
import qs.config
import qs.services

// Five slots, never more, never fewer, never a different width. What is in them
// is `Spaces`' business: the page of numbered workspaces holding the active one,
// or the special workspaces while one of those is up.
Item {
    id: root

    // The bar draws the line under these, so it needs their pitch and which one
    // is lit. -1 leaves the line short rather than guessing.
    readonly property int itemWidth: Appearance.metrics.workspaceWidth
    readonly property int itemSpacing: 7
    readonly property int activeIndex: Spaces.activeIndex

    implicitWidth: slots.implicitWidth + 6
    implicitHeight: Appearance.metrics.workspaceHeight + 6

    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceOne
        radius: Theme.radiusSmall
        border.width: 1
        border.color: Theme.rule
    }
    Rectangle {
        id: carriage
        visible: root.activeIndex >= 0
        x: 3 + root.activeIndex * (root.itemWidth + root.itemSpacing)
        y: 3
        width: root.itemWidth
        height: Appearance.metrics.workspaceHeight
        color: Theme.surfaceTwo
        radius: Theme.radiusSmall
        border.width: 1
        border.color: Theme.rule
        Behavior on x { SmoothedAnimation { velocity: 900; maximumEasingTime: 140 } }
    }
    Row {
    id: slots
    x: 3
    anchors.verticalCenter: parent.verticalCenter
    spacing: root.itemSpacing

    Repeater {
        model: Spaces.slots

        Item {
            id: button

            required property var modelData
            readonly property bool active: modelData.active
            readonly property bool occupied: modelData.occupied??false

            width: Appearance.metrics.workspaceWidth
            height: Appearance.metrics.workspaceHeight
            scale: 1
            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            HoverHandler { id: workspaceHover }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: button.active ? 24 : button.occupied ? 10 : 0
                height: button.active ? 2 : 1
                color: button.active ? Theme.signalRed : Theme.paperMuted
                Behavior on width { NumberAnimation { duration: Theme.motionTravel; easing.type: Easing.OutCubic } }
            }

            // **`NrLabel`, so the number is centred on its ink.** It was a
            // bare `Text` centred as an item, which is off in both directions
            // at once: the tracking is added after the last digit as well, and
            // the item is as tall as the font's whole line while a digit draws
            // in the top two thirds of it. The spec calls this slot out by
            // name -- "the active workspace number worst of all".
            Row {
                anchors.centerIn: parent
                spacing: 5
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""
                    text: button.modelData.glyph ?? ""
                    font.family: "ZedMono Nerd Font"
                    font.pixelSize: 14
                    color: button.active ? Theme.signalRed : button.occupied ? Theme.paper : Theme.mute
                    renderType: Text.NativeRendering
                }
                NrLabel {
                    anchors.verticalCenter: parent.verticalCenter
                    centred: true
                    text: button.modelData.label
                    font.capitalization: Font.MixedCase
                    color: button.active ? Theme.paper : button.occupied ? Theme.paper : Theme.mute
                    pixelSize: 11
                    font.family: Appearance.font.barUi
                    tracked: false
                    font.letterSpacing: 0.5; font.features: Appearance.tabularFigures
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: !button.modelData.empty
                cursorShape: Qt.PointingHandCursor

                // **No press flash here.** The shared flash exists to say a
                // click landed before the work starts, but a workspace switch
                // lands in a frame or two and lights this very slot -- so the
                // flash fired and faded on top of the highlight arriving, and
                // read as a blink rather than as an acknowledgement. The slot
                // taking the accent and the bar's line sliding to it are the
                // confirmation, and they are already animated.
                onClicked: Spaces.activate(button.modelData)
            }
        }
    }
    }
}
