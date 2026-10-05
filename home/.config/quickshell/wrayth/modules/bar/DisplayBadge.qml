import QtQuick
import qs.components
import qs.config
import qs.services

Item {
    id: root
    property bool condensed: false
    clip: true
    property string output: "screenpad"
    readonly property real level: output === "main" ? (RobotBench.data.mainBrightness ?? 0) : (RobotBench.data.brightness ?? 0)
    implicitWidth: condensed ? 48 : output === "main" ? 108 : 98
    implicitHeight: 34
    Behavior on implicitWidth { NumberAnimation { duration: Theme.motionTravel; easing.type: Easing.OutCubic } }
    BarSurface { anchors.fill: parent; grouped:condensed; hovered: hover.containsMouse; pressed: hover.pressed }
    Row {anchors.left:parent.left;anchors.leftMargin:8;anchors.verticalCenter:parent.verticalCenter;spacing:6
        Text {anchors.verticalCenter:parent.verticalCenter;text:"\uf185";font.family:Appearance.font.icons;font.pixelSize:24;color:Theme.semanticAmber}
        Column {visible:!root.condensed;anchors.verticalCenter:parent.verticalCenter;spacing:-1
            Text {text:root.output==="main"?"Display":"ScreenPad";font.family:Appearance.font.barUi;font.pixelSize:12;font.weight:Font.DemiBold;color:Theme.text}
            Text {text:Math.round(root.level)+"%";font.family:Appearance.font.barUi;font.pixelSize:10;color:Theme.widgetMuted}
        }
    }
    Rectangle {
        anchors.left: parent.left; anchors.leftMargin: 8; anchors.bottom: parent.bottom
        width: root.condensed ? 31 * Math.min(1, Math.max(0, root.level / 100)) : 0
        height: 2; color: Theme.semanticAmber
    }
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onWheel: event => { DisplayControls.adjustLevel(root.output, event.angleDelta.y > 0 ? 5 : -5); event.accepted = true; }
        onClicked: { ShellState.dropdownAnchorX = ShellState.anchorFor("system"); ShellState.toggleDropdown("system"); }
    }
}
