import QtQuick
import QtQuick.Controls
import qs.components
import qs.config
import qs.services

SlantBlock {
    id: root
    implicitWidth: 270
    implicitHeight: Appearance.metrics.barHeight
    Canvas {
        id: robotArt
        x: 8; y: 3; width: 44; height: 38
        scale: SpotifyDesk.playing ? 1.0225 - .0225 * Math.cos(MotionClock.ms * Math.PI * 2 / 1300) : 1
        property color ink: Theme.ground
        onInkChanged: requestPaint()
        onPaint: {
            const c = getContext("2d"); c.reset(); c.strokeStyle=ink; c.fillStyle=ink; c.lineWidth=1;
            c.beginPath(); c.moveTo(9,3); c.lineTo(34,3); c.lineTo(41,10); c.lineTo(41,29); c.lineTo(34,36); c.lineTo(9,36); c.lineTo(2,29); c.lineTo(2,10); c.closePath(); c.stroke();
            c.strokeRect(10,12,23,17); c.fillRect(14,17,5,4); c.fillRect(24,17,5,4);
            c.beginPath(); c.moveTo(17,25); c.lineTo(26,25); c.moveTo(21.5,12); c.lineTo(21.5,7); c.stroke(); c.fillRect(20,5,3,3);
            c.beginPath(); c.moveTo(10,18); c.lineTo(5,18); c.lineTo(5,25); c.moveTo(33,18); c.lineTo(38,18); c.lineTo(38,25); c.moveTo(17,29); c.lineTo(17,33); c.moveTo(27,29); c.lineTo(27,33); c.stroke();
            c.fillRect(4,9,2,2); c.fillRect(37,9,2,2); c.fillRect(4,28,2,2); c.fillRect(37,28,2,2);
        }
    }
    Column {
        x: 61; anchors.verticalCenter: parent.verticalCenter; spacing: 2
        Row {
            spacing: 9
            Text { renderType: Text.QtRendering; renderTypeQuality: 104; text: "fh1m"; font.family: Appearance.font.data; font.pixelSize: 15; font.weight: 700; font.letterSpacing: 1; color: Theme.ground }
            Text { renderType: Text.QtRendering; renderTypeQuality: 104; text: "// R-01"; font.family: Appearance.font.data; font.pixelSize: 11; color: Theme.ground; anchors.verticalCenter: parent.verticalCenter }
        }
        Text { renderType: Text.QtRendering; renderTypeQuality: 104; text: "ROBOTICS // " + (RobotBench.data.boardCount ?? 0) + " USB"; font.family: Appearance.font.data; font.pixelSize: 10; font.letterSpacing: 0.5; color: Theme.ground }
    }
    Rectangle { x: 194; y: 9; width: 1; height: 26; color: Theme.alpha(Theme.ground, 0.4) }
    Column {
        x: 204; anchors.verticalCenter: parent.verticalCenter; spacing: 4
        Text { renderType: Text.QtRendering; renderTypeQuality: 104; text: (RobotBench.data.gpu.computeCount ?? 0) > 0 ? "CUDA" : "DECK"; font.family: Appearance.font.data; font.pixelSize: 10; font.weight: 600; color: Theme.ground }
        Row {
            spacing: 3
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    width: 5; height: 4; color: Theme.ground
                    SequentialAnimation on opacity {
                        running: (RobotBench.data.gpu.computeCount ?? 0) > 0
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.9; duration: 1100 + index * 150 }
                        NumberAnimation { to: 0.3; duration: 1100 + index * 150 }
                    }
                }
            }
        }
    }
    MouseArea { id: operatorPointer; hoverEnabled: true; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton; onClicked: event => { const panel=event.button===Qt.RightButton?"comic":"ident"; ShellState.publishAnchor(panel,12); ShellState.toggleDropdown(panel); } }
}
