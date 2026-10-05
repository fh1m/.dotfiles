import QtQuick
import qs.config

// Three related instrument marks instead of unrelated font pictograms.
Item {
    id: root
    property string kind: "system"
    property color ink: Theme.signalRed
    property real level: 0
    property bool muted: false
    implicitWidth: 24
    implicitHeight: 24
    onKindChanged: Qt.callLater(() => iconCanvas.requestPaint())
    onInkChanged: Qt.callLater(() => iconCanvas.requestPaint())
    onLevelChanged: Qt.callLater(() => iconCanvas.requestPaint())
    onMutedChanged: Qt.callLater(() => iconCanvas.requestPaint())
    Canvas {
        id: iconCanvas
        anchors.centerIn: parent
        width: 20; height: 20
        onPaint: {
            const c = getContext("2d"); c.reset();
            c.strokeStyle = root.ink; c.fillStyle = root.ink;
            c.lineWidth = 1.6; c.lineCap = "square"; c.lineJoin = "miter";
            if (root.kind === "display") {
                c.strokeRect(2, 3, 16, 11);
                c.beginPath(); c.moveTo(10, 14); c.lineTo(10, 18);
                c.moveTo(6, 18); c.lineTo(14, 18); c.stroke();
            } else if (root.kind === "bluetooth") {
                c.beginPath(); c.moveTo(10, 1); c.lineTo(10, 19);
                c.moveTo(10, 1); c.lineTo(15, 5); c.lineTo(5, 15);
                c.moveTo(10, 19); c.lineTo(15, 15); c.lineTo(5, 5);
                c.stroke();
            } else if (root.kind === "audio") {
                c.beginPath();
                c.moveTo(2, 8); c.lineTo(6, 8); c.lineTo(10, 4);
                c.lineTo(10, 16); c.lineTo(6, 12); c.lineTo(2, 12); c.closePath();
                c.stroke();
                if (root.muted) {
                    c.beginPath(); c.moveTo(13, 7); c.lineTo(18, 13);
                    c.moveTo(18, 7); c.lineTo(13, 13); c.stroke();
                } else if (root.level > .01) {
                    c.beginPath(); c.arc(10, 10, 5, -.78, .78); c.stroke();
                    if (root.level > .58) {
                        c.beginPath(); c.arc(10, 10, 8, -.78, .78); c.stroke();
                    }
                }
            } else if (root.kind === "gpu") {
                c.strokeRect(4, 4, 12, 12);
                c.strokeRect(7, 7, 6, 6);
                c.beginPath();
                for (let n of [7, 13]) {
                    c.moveTo(n, 1); c.lineTo(n, 4);
                    c.moveTo(n, 16); c.lineTo(n, 19);
                    c.moveTo(1, n); c.lineTo(4, n);
                    c.moveTo(16, n); c.lineTo(19, n);
                }
                c.stroke();
            } else {
                // A compact machined gear: distinct from the display and GPU.
                c.beginPath(); c.arc(10, 10, 6, 0, Math.PI * 2);
                c.moveTo(10, 1); c.lineTo(10, 4);
                c.moveTo(10, 16); c.lineTo(10, 19);
                c.moveTo(1, 10); c.lineTo(4, 10);
                c.moveTo(16, 10); c.lineTo(19, 10);
                c.stroke();
                c.beginPath(); c.arc(10, 10, 2, 0, Math.PI * 2); c.stroke();
            }
        }
    }
}
