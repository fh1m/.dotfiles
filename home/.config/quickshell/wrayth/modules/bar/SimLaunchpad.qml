import QtQuick
import Quickshell
import QtQuick.Controls
import qs.components
import qs.config
import qs.services

BarSurface {
    id: root
    readonly property var gpu: RobotBench.data.gpu
    readonly property int compute: gpu.computeCount ?? 0
    readonly property int graphics: gpu.graphicsCount ?? 0
    readonly property bool busy: compute > 0 || graphics > 0
    readonly property color activity: compute > 0 ? Theme.accent : (graphics > 0 ? Theme.signal : Theme.dim)
    implicitWidth: 156; implicitHeight: 34
    grouped:false
    selected: busy; hovered: pointer.containsMouse; pressed: pointer.pressed
    Row { anchors.centerIn: parent; spacing: 7
        NrLabel { text: "\uf2db"; centred: true; anchors.verticalCenter: parent.verticalCenter; pixelSize: 19; color: root.activity }
        Column {anchors.verticalCenter:parent.verticalCenter;spacing:-1
            Text {text:"Nvidia";font.family:Appearance.font.barUi;font.pixelSize:12;font.weight:Font.DemiBold;color:Theme.text}
            Text {text:root.compute>0?"CUDA "+root.compute:root.graphics>0?"RTX "+root.graphics:root.gpu.state==="sleep"?"Sleep":root.gpu.processesKnown?"Ready":"Unknown";font.family:Appearance.font.data;font.pixelSize:10;color:root.activity}
        }
    }
    MouseArea {
        id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => { if (event.button === Qt.RightButton) Quickshell.execDetached(["/home/fh1m/.local/bin/sim-console"]); else { ShellState.monitorPage = 2; ShellState.dropdownAnchorX = root.mapToItem(null, 0, 0).x; ShellState.toggleDropdown("monitor"); } }
    }
}
