import QtQuick
import Quickshell
import qs.config
import qs.services

Item {
    id: root
    implicitWidth: 168
    implicitHeight: Appearance.metrics.barHeight

    // An operator tag, not a logo. The second line reports live lab activity.
    Column {
        x: 13
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
            text: "FH1M / DESKTOP"
            font.family: Appearance.font.display
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Theme.signalRed
            renderType: Text.QtRendering
        }
        Text {
            text: (RobotBench.data.gpu.computeCount ?? 0) > 0
                ? "CUDA " + RobotBench.data.gpu.computeCount + " · COMPUTE"
                : "GTX 1660 SUPER · READY"
            font.family: Appearance.font.telemetry
            font.pixelSize: 10
            color: Theme.paperMuted
            renderType: Text.QtRendering
        }
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 11
        anchors.verticalCenter: parent.verticalCenter
        text: "↗"
        font.family: Appearance.font.display
        font.pixelSize: 14
        color: Theme.signalRed
        renderType: Text.QtRendering
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton) {
                ShellState.publishAnchor("comic", 12);
                ShellState.toggleDropdown("comic");
            } else if (event.button === Qt.MiddleButton || (event.modifiers & Qt.ShiftModifier)) {
                ShellState.publishAnchor("ident", 12);
                ShellState.toggleDropdown("ident");
            } else {
                Quickshell.execDetached(["xdg-open", "https://github.com/fh1m"]);
            }
        }
    }
}
