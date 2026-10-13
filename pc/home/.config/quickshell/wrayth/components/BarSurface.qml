import QtQuick
import qs.config

// One continuous instrument rail: temporary local elevation on hover, a
// fine separator for grouping, and a short signal rule for an open panel.
Rectangle {
    id: root
    property bool hovered: false
    property bool selected: false
    property bool pressed: false
    property bool showSelectionRule: true
    property real selectionRuleWidth: 24
    property real selectionRuleCenterX: width / 2
    property bool grouped: false
    radius: 0
    color: pressed ? Theme.alpha(Theme.surfaceTwo,.55) : hovered || selected ? Theme.alpha(Theme.surfaceOne,.35) : "transparent"
    border.width: 0
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 1; height: root.height - 16
        visible: !root.grouped
        color: Theme.rule
    }
    Rectangle {
        anchors.bottom: parent.bottom
        x: root.selectionRuleCenterX - width / 2
        width: root.selected && root.showSelectionRule ? root.selectionRuleWidth : 0
        height: 2
        color: Theme.signalRed
        Behavior on width { NumberAnimation { duration: Theme.motionTravel; easing.type: Easing.OutCubic } }
    }
    scale: pressed ? .985 : 1
    Behavior on color { ColorAnimation { duration: Theme.motionAck } }
    Behavior on scale { NumberAnimation { duration: Theme.motionAck; easing.type: Easing.OutCubic } }
}
