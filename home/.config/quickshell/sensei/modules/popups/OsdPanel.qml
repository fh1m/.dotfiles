import QtQuick
import qs.components
import qs.config
import qs.services
import qs.utils

// The volume / brightness readout: a title row and a 20-segment bar --
// one segment per 5% step, so a single key press fills or empties exactly one.
ChamferPanel {
    id: root

    required property bool volume

    readonly property bool muted: volume && Audio.muted
    readonly property real level: volume ? Audio.volume : Brightness.value

    readonly property real padding: 14

    chamfer: Appearance.chamfer.panel
    fillColor: Theme.panel2
    borderColor: root.muted ? Theme.accent : Theme.hair

    Item {
        id: line

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: root.padding
        height: 24

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                textFormat: Text.PlainText
                anchors.verticalCenter: parent.verticalCenter
                text: root.volume ? "Volume" : "Brightness"
                color: Theme.bright
                font.family: Appearance.font.display
                font.pixelSize: 14
                font.weight: Appearance.font.weightBold
                renderType: Text.NativeRendering
            }

            Text {
                anchors.verticalCenter:parent.verticalCenter
                width:Math.max(0,line.width-198)
                text:root.volume?Audio.deviceName:Brightness.outputName
                textFormat:Text.PlainText;elide:Text.ElideRight
                font.family:Appearance.font.reading;font.pixelSize:13;color:Theme.paperMuted
            }
        }

        Text {
            textFormat: Text.PlainText
            renderType: Text.NativeRendering
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            text: root.muted ? "MUTED" : Fmt.percent(root.level * 100)
            color: root.muted ? Theme.accent : Theme.bright
            font.family: Appearance.font.data
            font.pixelSize: Appearance.size.body
            font.weight: Appearance.font.weightSemi
        }
    }

    SegmentMeter {
        id: bar

        anchors.top: line.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding

        // 20, not 25: both keys step 5%, and 100 / 5 is 20. At 25 a press moved
        // 1.25 segments and the bar stuttered against the number beside it.
        // The popup keeps its width; the segments widen to fill it.
        segments: 20
        spacing: 3
        segmentWidth: (width - (segments - 1) * spacing) / segments
        segmentHeight: 16
        value: root.level
        litColor: root.muted ? Theme.mute : Theme.accent
        animate: false
    }
}
