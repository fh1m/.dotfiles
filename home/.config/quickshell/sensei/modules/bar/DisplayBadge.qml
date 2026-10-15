import QtQuick
import qs.components
import qs.config
import qs.services

Item {
    id: root
    property bool condensed: false
    clip: true
    property string output: "screenpad"
    readonly property bool external:output!=="main"&&output!=="screenpad"
    readonly property var externalDisplay:ExternalDisplays.display(output)
    // The main panel follows the event-driven Brightness service (inotify on the
    // backlight), so the badge moves with the hardware keys at once. RobotBench
    // polls every 10 s and is only the fallback. The ScreenPad has no such source.
    readonly property real level: MachineProfile.desktop && output === "main" ? (ExternalDisplays.display(MachineProfile.primaryOutput)?.level ?? 0) : external?(externalDisplay?.level??0):output === "main" ? (Brightness.ready ? Brightness.value * 100 : (RobotBench.data.mainBrightness ?? 0)) : (RobotBench.data.brightness ?? 0)
    implicitWidth: condensed ? 44 : external ? 156 : output === "main" ? 108 : 120
    implicitHeight: 34
    Behavior on implicitWidth { NumberAnimation { duration: Theme.motionTravel; easing.type: Easing.OutCubic } }
    BarSurface { anchors.fill: parent; grouped:condensed||root.external; hovered: hover.containsMouse; pressed: hover.pressed }
    Row {anchors.left:parent.left;anchors.leftMargin:10;anchors.verticalCenter:parent.verticalCenter;spacing:6
        InstrumentIcon {anchors.verticalCenter:parent.verticalCenter;kind:root.external?"external-display":root.output==="main"?"brightness":"display";ink:Theme.signalRed;level:root.level/100}
        Column {visible:!root.condensed;anchors.verticalCenter:parent.verticalCenter;spacing:-1
            Text { textFormat: Text.PlainText;text:root.output===MachineProfile.primaryOutput?"Display":root.external?(ShellState.externalBarEdge(root.output)==="top"?"Upper display":"Lower display"):root.output==="main"?"Display":"ScreenPad";font.family:Appearance.font.barUi;renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;font.pixelSize:root.external?13:12;font.weight:Font.DemiBold;color:Theme.text}
            Text { textFormat: Text.PlainText;text:root.external&&!root.externalDisplay?.ready?"Monitor keys":Math.round(root.level)+"%";font.family:Appearance.font.barUi;renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;font.pixelSize:root.external?12:10;color:Theme.widgetMuted}
        }
    }
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onWheel: event => { DisplayControls.adjustLevel(root.output, event.angleDelta.y > 0 ? 5 : -5); event.accepted = true; }
        onClicked: { if(root.external){ShellState.dropdownAnchorX=mapToItem(null,0,0).x;ShellState.toggleDropdown("external-display");}else{ShellState.dropdownAnchorX = ShellState.anchorFor("system"); ShellState.toggleDropdown("system");} }
    }
}
