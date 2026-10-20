import QtQuick
import qs.components
import qs.config

// The shell every bar dropdown shares: chamfered panel2 with blur, a header of
// title + katakana + a right-hand slot, and a hairline under it.
ChamferPanel {
    id: root

    property string title: ""
    readonly property bool hasTitleGlyph: title.length > 0 && title.charCodeAt(0) >= 0xe000 && title.charCodeAt(0) <= 0xf8ff
    readonly property string titleText: hasTitleGlyph ? title.slice(1).trim() : title
    property string katakana: ""
    property string greeting: ""
    property color headerAccent: Theme.widgetAccent
    default property alias body: content.data
    property alias headerRight: right.data

    readonly property real padding: 18

    implicitWidth: 380
    chamfer: Theme.radiusPanel
    fillColor: Theme.widgetGlass
    borderColor: Theme.rule
    scanlines: false

    Item {
        id: header

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: root.padding
        height: root.greeting === "" ? 44 : 60

        Rectangle {anchors.left:parent.left;anchors.top:parent.top;anchors.topMargin:-8;width:30;height:2;color:root.headerAccent}

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 8
            spacing: 8

            ChamferPanel {visible:root.hasTitleGlyph;chamfer:Theme.radiusSmall;scanlines:false;width:27;height:27;fillColor:Theme.ink;borderColor:Theme.rule;borderWidth:1
                Text { textFormat: Text.PlainText;anchors.centerIn:parent;text:root.hasTitleGlyph?root.title.charAt(0):"";font.family:Appearance.font.icons;font.pixelSize:18;color:root.headerAccent}
            }

            NrLabel {
                anchors.verticalCenter: parent.verticalCenter
                pixelSize: Appearance.textSize.title
                font.family: Appearance.font.heading
                font.capitalization: Font.MixedCase
                font.letterSpacing: 0
                font.weight: Font.Medium
                color: Theme.widgetText
                width:Math.max(80,header.width-right.width-36-(root.hasTitleGlyph?36:0)-(root.katakana!==""?100:0))
                elide:Text.ElideRight
                text: root.titleText
            }

        }

            Text {
                textFormat: Text.PlainText
                anchors.right: parent.right
                anchors.rightMargin: right.width + 12
                y: 8
                text: root.katakana
                color: Theme.widgetMuted
                font.family: Appearance.font.accent
                font.letterSpacing: 0
                font.pixelSize: Appearance.textSize.caption
                font.weight: Appearance.font.weightMedium
                renderType: Text.NativeRendering
            }

        Text { textFormat: Text.PlainText; x: 8; y: 31; visible: root.greeting !== ""; text: root.greeting; color: Theme.widgetMuted; font.family:Appearance.font.reading; font.pixelSize: Appearance.textSize.body; renderType: Text.QtRendering }

        Item {
            id: right

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
            width: implicitWidth
            height: implicitHeight
        }
    }

    Rectangle {
        id: rule

        anchors.top: header.bottom
        anchors.topMargin: root.padding * 0.7
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        height: Appearance.metrics.hairline
        color: Theme.widgetBorder
    }

    Item {
        id: content

        anchors.top: rule.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: root.padding * 0.8
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        height: childrenRect.height
    }

    implicitHeight: content.y + content.height + root.padding
}
