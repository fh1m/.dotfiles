import QtQuick
import Quickshell
import QtQuick.Controls
import qs.components
import qs.config
import qs.services

Rectangle {
    id: root
    readonly property var gpu: RobotBench.data.gpu
    readonly property int compute: gpu.computeCount ?? 0
    readonly property int graphics: gpu.graphicsCount ?? 0
    readonly property bool busy: compute > 0 || graphics > 0
    readonly property color activity: compute > 0 ? Theme.accent : (graphics > 0 ? Theme.signal : Theme.dim)
    implicitWidth: 156; implicitHeight: 30
    radius: 2; color: pointer.containsMouse || busy ? Theme.alpha(activity, 0.12) : "transparent"
    border.width: 1; border.color: "#26282d"
    Behavior on color { ColorAnimation { duration: 180 } }
    Row { anchors.centerIn: parent; spacing: 7
        NrLabel { text: "\uf2db"; centred: true; anchors.verticalCenter: parent.verticalCenter; pixelSize: 17; color: root.activity }
        NrLabel { centred: true; anchors.verticalCenter: parent.verticalCenter; pixelSize: 12; font.letterSpacing: 0.3; color: root.activity; font.capitalization:Font.MixedCase;tracked:false;text: "Nvidia · " + (root.compute > 0 ? "CUDA " + root.compute : root.graphics > 0 ? "RTX " + root.graphics : root.gpu.state === "sleep" ? "SLEEP" : root.gpu.processesKnown ? "READY" : "UNKNOWN") }
    }
    MouseArea {
        id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => { if (event.button === Qt.RightButton) Quickshell.execDetached(["@HOME@/.local/bin/sim-console"]); else { ShellState.monitorPage = 2; ShellState.dropdownAnchorX = root.mapToItem(null, 0, 0).x; ShellState.toggleDropdown("monitor"); } }
    }
}
