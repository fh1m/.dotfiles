import QtQuick
import qs.config
import qs.services

Item {
    id: root
    implicitWidth: 158
    implicitHeight: Appearance.metrics.barHeight

    // Small, functional station mark: identity remains visible beside media.
    Canvas {
        id: mark
        x: 13; anchors.verticalCenter: parent.verticalCenter
        width: 30; height: 30
        property color ink: Theme.signalRed
        onInkChanged: requestPaint()
        onPaint: {
            const c = getContext("2d"); c.reset();
            c.strokeStyle = ink; c.fillStyle = ink; c.lineWidth = 1.5;
            c.strokeRect(4, 6, 22, 19);
            c.beginPath(); c.moveTo(15, 2); c.lineTo(15, 6); c.moveTo(3, 13); c.lineTo(0, 13); c.moveTo(27, 13); c.lineTo(30, 13); c.stroke();
            c.fillRect(8, 12, 4, 3); c.fillRect(18, 12, 4, 3);
            c.beginPath(); c.moveTo(11, 20); c.lineTo(19, 20); c.stroke();
        }
        SequentialAnimation on opacity {
            running: ShellState.ambientMotion && SpotifyDesk.playing
            loops: Animation.Infinite
            NumberAnimation { from: 1; to: .7; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { from: .7; to: 1; duration: 900; easing.type: Easing.InOutSine }
        }
    }
    Column {
        x: 51; anchors.verticalCenter: parent.verticalCenter; spacing: 1
        Text {
            text: "fh1m"; font.family: Appearance.font.display; font.pixelSize: 16
            font.weight: Font.Bold; color: Theme.signalRed
        }
        Text {
            text: "R-01  ·  " + (RobotBench.data.boardCount ?? 0) + " USB"
            font.family: Appearance.font.telemetry; font.pixelSize: 10
            color: Theme.paperMuted
        }
    }
    MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            const panel = event.button === Qt.RightButton ? "comic" : "ident";
            ShellState.publishAnchor(panel, 12); ShellState.toggleDropdown(panel);
        }
    }
}
