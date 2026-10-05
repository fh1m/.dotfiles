import QtQuick
import qs.components
import qs.config
import qs.services

BarSurface {
    id: root
    implicitWidth: 106; implicitHeight: 34
    grouped: false
    selected: ShellState.dropdown === "system"
    hovered: pointer.containsMouse
    pressed: pointer.pressed
    Row {anchors.centerIn:parent;spacing:7
        Text {anchors.verticalCenter:parent.verticalCenter;text:"\uf1de";font.family:Appearance.font.icons;font.pixelSize:17;color:ShellState.dropdown==="system"?Theme.widgetAccent:Theme.dim}
        Column {anchors.verticalCenter:parent.verticalCenter;spacing:-1
            Text {text:"System";font.family:Appearance.font.barUi;font.pixelSize:12;font.weight:Font.DemiBold;color:Theme.text}
            Text {text:"Controls";font.family:Appearance.font.barUi;font.pixelSize:10;color:Theme.widgetMuted}
        }
    }
    function publish(): void { ShellState.publishAnchor("system", root.mapToItem(null, 0, 0).x); }
    onXChanged: publish()
    Component.onCompleted: Qt.callLater(publish)
    MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { ShellState.dropdownAnchorX = root.mapToItem(null, 0, 0).x; ShellState.toggleDropdown("system"); } }
}
