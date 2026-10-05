import QtQuick
import Quickshell
import QtQuick.Controls
import qs.components
import qs.config
import qs.services

BarSurface {
    id: root
    property bool condensed: false
    clip: true
    readonly property var gpu: RobotBench.data.gpu
    readonly property int compute: gpu.computeCount ?? 0
    readonly property int graphics: gpu.graphicsCount ?? 0
    readonly property bool busy: compute > 0 || graphics > 0
    readonly property color activity: compute > 0 ? Theme.accent : (graphics > 0 ? Theme.signal : Theme.dim)
    implicitWidth: condensed ? 48 : 94; implicitHeight: 34
    Behavior on implicitWidth { NumberAnimation { duration: Theme.motionTravel; easing.type: Easing.OutCubic } }
    grouped:condensed
    selected: busy; hovered: pointer.containsMouse; pressed: pointer.pressed
    Row { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; spacing: 6
        NrLabel { text: "\uf2db"; centred: true; anchors.verticalCenter: parent.verticalCenter; pixelSize: 24; color: root.activity }
        Column {visible:!root.condensed;anchors.verticalCenter:parent.verticalCenter;spacing:-1
            Text {text:"NVIDIA";font.family:Appearance.font.barUi;font.pixelSize:11;font.weight:Font.DemiBold;color:Theme.text}
            Text {text:root.compute>0?"CUDA "+root.compute:root.graphics>0?"GPU "+root.graphics:root.gpu.state==="sleep"?"Asleep":root.gpu.processesKnown?"Ready":"--";font.family:Appearance.font.data;font.pixelSize:10;color:root.activity}
        }
    }
    MouseArea {
        id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => { if (event.button === Qt.RightButton) Quickshell.execDetached(["/home/fh1m/.local/bin/sim-console"]); else { ShellState.monitorPage = 2; ShellState.dropdownAnchorX = root.mapToItem(null, 0, 0).x; ShellState.toggleDropdown("monitor"); } }
    }
}
