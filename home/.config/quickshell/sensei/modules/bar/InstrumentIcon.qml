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
    onKindChanged: Qt.callLater(() => { if (iconCanvas) iconCanvas.requestPaint(); })
    onInkChanged: Qt.callLater(() => { if (iconCanvas) iconCanvas.requestPaint(); })
    onLevelChanged: Qt.callLater(() => { if (iconCanvas) iconCanvas.requestPaint(); })
    onMutedChanged: Qt.callLater(() => { if (iconCanvas) iconCanvas.requestPaint(); })
    Canvas {
        id: iconCanvas
        anchors.centerIn: parent
        width: 20; height: 20
        onPaint: {
            const c = getContext("2d"); c.reset();
            c.strokeStyle = root.ink; c.fillStyle = root.ink;
            c.lineWidth = 1.6; c.lineCap = "square"; c.lineJoin = "miter";
            if (root.kind === "brightness") {
                c.beginPath();c.arc(10,10,4,0,Math.PI*2);c.stroke();
                c.globalAlpha=.65;c.beginPath();c.moveTo(10,10);c.arc(10,10,3, -Math.PI/2,-Math.PI/2+Math.PI*2*Math.max(0,Math.min(1,root.level)));c.closePath();c.fill();c.globalAlpha=1;
                for(let i=0;i<8;i++){let a=i*Math.PI/4;c.beginPath();c.moveTo(10+7*Math.cos(a),10+7*Math.sin(a));c.lineTo(10+9*Math.cos(a),10+9*Math.sin(a));c.stroke();}
            } else if (root.kind === "battery" || root.kind === "ac") {
                if(root.kind === "ac"){c.beginPath();c.moveTo(7,1);c.lineTo(7,6);c.moveTo(13,1);c.lineTo(13,6);c.moveTo(5,6);c.lineTo(15,6);c.lineTo(15,10);c.lineTo(12,13);c.lineTo(8,13);c.lineTo(5,10);c.closePath();c.stroke();c.beginPath();c.moveTo(10,13);c.lineTo(10,19);c.stroke();}
                else {c.strokeRect(1,5,16,10);c.fillRect(18,8,2,4);c.fillRect(3,7,12*Math.max(0,Math.min(1,root.level)),6);}
            } else if (root.kind === "external-display") {
                c.strokeRect(1,2,18,12);c.beginPath();c.moveTo(10,14);c.lineTo(10,18);c.moveTo(6,18);c.lineTo(14,18);c.stroke();
                c.globalAlpha=.7;c.fillRect(3,10,14*Math.max(0,Math.min(1,root.level)),2);c.globalAlpha=1;
                c.beginPath();c.moveTo(12,5);c.lineTo(16,5);c.lineTo(16,9);c.moveTo(11,10);c.lineTo(16,5);c.stroke();
            } else if (root.kind === "monitor") {
                c.strokeRect(1,2,18,12);c.beginPath();c.moveTo(5,10);c.lineTo(7,7);c.lineTo(10,10);c.lineTo(13,5);c.lineTo(16,8);c.stroke();
                c.beginPath();c.moveTo(10,14);c.lineTo(10,18);c.moveTo(6,18);c.lineTo(14,18);c.stroke();
            } else if (root.kind === "display") {
                // The Duo's two panels: a main display above the lit ScreenPad.
                c.strokeRect(2,2,16,9);
                c.strokeRect(1,14,18,5);
                c.beginPath();c.moveTo(10,11);c.lineTo(10,14);c.stroke();
                c.globalAlpha=.85;c.fillRect(3,16,14*Math.max(0,Math.min(1,root.level)),1.5);c.globalAlpha=1;
            } else if (root.kind.startsWith("bluetooth")) {
                c.beginPath(); c.moveTo(10, 1); c.lineTo(10, 19);
                c.moveTo(10, 1); c.lineTo(15, 5); c.lineTo(5, 15);
                c.moveTo(10, 19); c.lineTo(15, 15); c.lineTo(5, 5);
                c.stroke();
                if(root.kind === "bluetooth-connected"){c.beginPath();c.arc(3,10,1.5,0,Math.PI*2);c.arc(18,10,1.5,0,Math.PI*2);c.fill();}
                if(root.kind === "bluetooth-off"){c.clearRect(8,8,4,4);}
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
                // Four calibrated controls, aligned to the same 20px grid.
                for(let y of [4,10,16]){c.beginPath();c.moveTo(2,y);c.lineTo(18,y);c.stroke();}
                for(let p of [[7,4],[13,10],[7,16]]){c.clearRect(p[0]-3,p[1]-3,6,6);c.strokeRect(p[0]-2,p[1]-2,4,4);}
            }
        }
    }
}
