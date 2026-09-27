import QtQuick
import qs.config

Item {
    implicitHeight: 18
    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; height: 1; color: Theme.hair }
    Repeater {
        model: 3
        Rectangle {
            required property int index
            x: Math.max(0, (parent.width - width) * index / 2)
            anchors.verticalCenter: parent.verticalCenter
            width: 4; height: 4
            color: Theme.signal
            opacity: 0.4
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.85; duration: 1000 + index * 240; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.3; duration: 1000 + index * 240; easing.type: Easing.InOutSine }
            }
        }
    }
}
