import QtQuick
import qs.components
import qs.config

// The shell every bar dropdown shares: chamfered panel2 with blur, a header of
// title + katakana + a right-hand slot, and a hairline under it.
ChamferPanel {
    id: root

    property string title: ""
    property string katakana: ""
    property string greeting: "Sensei, your workstation is ready."
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
        height: 44
        Rectangle {anchors.left:parent.left;anchors.right:parent.right;anchors.top:parent.top;anchors.topMargin:-8;height:1;color:Theme.alpha(root.headerAccent,.28)}

        Row {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 1
            spacing: 8

            NrLabel {
                anchors.verticalCenter: parent.verticalCenter
                pixelSize: Math.max(13, Appearance.size.label)
                font.weight: Font.Bold
                color: Theme.widgetText
                text: root.title
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.katakana
                color: root.headerAccent
                font.family: Appearance.font.accent
                font.letterSpacing: 0
                font.pixelSize: Appearance.size.katakana
                font.weight: Appearance.font.weightMedium
                renderType: Text.NativeRendering
            }
        }

        Text { x: 0; y: 29; text: root.greeting; color: Theme.widgetMuted; font.family: Appearance.font.data; font.pixelSize: 11; renderType: Text.QtRendering }

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
