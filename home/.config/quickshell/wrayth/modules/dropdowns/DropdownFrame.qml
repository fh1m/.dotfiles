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

    readonly property real padding: 14

    implicitWidth: 380
    chamfer: Appearance.chamfer.panel
    fillColor: Theme.widgetGlass
    borderColor: Theme.widgetBorder
    scanlines: false

    Item {
        id: header

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: root.padding
        height: root.greeting === "" ? 38 : 50
        ChamferPanel {anchors.fill:parent;chamfer:5;scanlines:false;fillColor:Theme.widgetSurface;borderColor:"transparent";borderWidth:0}
        Rectangle {anchors.left:parent.left;anchors.right:parent.right;anchors.top:parent.top;anchors.topMargin:-8;height:1;color:Theme.alpha(root.headerAccent,.28)}

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 4
            spacing: 8

            ChamferPanel {visible:root.hasTitleGlyph;chamfer:4;scanlines:false;width:27;height:27;fillColor:Theme.blend(Theme.widgetSurface,root.headerAccent,.14);borderColor:"transparent";borderWidth:0
                Text {anchors.centerIn:parent;text:root.hasTitleGlyph?root.title.charAt(0):"";font.family:Appearance.font.icons;font.pixelSize:15;color:root.headerAccent}
            }

            NrLabel {
                anchors.verticalCenter: parent.verticalCenter
                pixelSize: 15
                font.family: Appearance.font.heading
                font.capitalization: Font.MixedCase
                font.letterSpacing: 0
                font.weight: Font.DemiBold
                color: Theme.widgetText
                text: root.titleText
            }

        }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: right.width + 12
                y: 8
                text: root.katakana
                color: Theme.widgetMuted
                font.family: Appearance.font.accent
                font.letterSpacing: 0
                font.pixelSize: 10
                font.weight: Appearance.font.weightMedium
                renderType: Text.NativeRendering
            }

        Text { x: 8; y: 31; visible: root.greeting !== ""; text: root.greeting; color: Theme.widgetMuted; font.family: Appearance.font.ui; font.pixelSize: 12; renderType: Text.QtRendering }

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
