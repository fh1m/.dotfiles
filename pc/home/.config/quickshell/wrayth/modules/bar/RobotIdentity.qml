import QtQuick
import Quickshell
import qs.config
import qs.services

Item {
    id: root
    implicitWidth: 178
    implicitHeight: Appearance.metrics.barHeight

    // Desktop identity with a live compute indicator; one wallpaper accent.
    Rectangle {
        x: 7
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 14
        height: 36
        radius: 10
        color: Qt.alpha(Theme.signalRed, 0.08)
        border.width: 1
        border.color: Qt.alpha(Theme.signalRed, 0.22)
    }
    Rectangle {
        x: 17
        anchors.verticalCenter: parent.verticalCenter
        width: 5; height: 5; radius: 3
        color: Theme.signalRed
        opacity: (RobotBench.data.gpu.computeCount ?? 0) > 0 ? 1 : 0.65
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }
    Column {
        x: 30
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
            text: "fh1m · desktop"
            font.family: Appearance.font.ui
            font.pixelSize: 12
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
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: ""
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
