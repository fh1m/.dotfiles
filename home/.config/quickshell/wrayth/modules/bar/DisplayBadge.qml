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
    implicitWidth: condensed ? 44 : output === "main" ? 108 : 120
    implicitHeight: 34
    Behavior on implicitWidth { NumberAnimation { duration: Theme.motionTravel; easing.type: Easing.OutCubic } }
    BarSurface { anchors.fill: parent; grouped:condensed; hovered: hover.containsMouse; pressed: hover.pressed }
    Row {anchors.left:parent.left;anchors.leftMargin:10;anchors.verticalCenter:parent.verticalCenter;spacing:6
        InstrumentIcon {anchors.verticalCenter:parent.verticalCenter;kind:"display";ink:Theme.signalRed}
        Column {visible:!root.condensed;anchors.verticalCenter:parent.verticalCenter;spacing:-1
            Text {text:root.output==="main"?"Display":"ScreenPad";font.family:Appearance.font.barUi;font.pixelSize:12;font.weight:Font.DemiBold;color:Theme.text}
            Text {text:Math.round(root.level)+"%";font.family:Appearance.font.barUi;font.pixelSize:10;color:Theme.widgetMuted}
        }
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
