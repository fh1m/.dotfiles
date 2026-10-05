import QtQuick
import qs.components
import qs.config
import qs.services

Item {
    id: root
    property string output: "screenpad"
    readonly property real level: output === "main" ? (RobotBench.data.mainBrightness ?? 0) : (RobotBench.data.brightness ?? 0)
    implicitWidth: output === "main" ? 108 : 98
    implicitHeight: 34
    BarSurface { anchors.fill: parent; grouped:false; hovered: hover.containsMouse; pressed: hover.pressed }
    Row {anchors.centerIn:parent;spacing:6
        Text {anchors.verticalCenter:parent.verticalCenter;text:"\uf185";font.family:Appearance.font.icons;font.pixelSize:18;color:Theme.widgetAccent}
        Column {anchors.verticalCenter:parent.verticalCenter;spacing:-1
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
