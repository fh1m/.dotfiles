import QtQuick
import qs.config
import qs.services
Item {z:10;
    id:root
    visible:SpotifyDesk.videoAudioLinked&&YouTubeDesk.captionsEnabled&&YouTubeDesk.captionIndex>=0
    anchors.fill:parent
    Rectangle {
        anchors.horizontalCenter:parent.horizontalCenter;anchors.bottom:parent.bottom;anchors.bottomMargin:14
        width:Math.min(parent.width-32,words.implicitWidth+28);height:words.implicitHeight+16;radius:6;color:'#cc000000'
        Text {id:words;anchors.centerIn:parent;width:Math.min(root.width-60,implicitWidth);text:YouTubeDesk.transcript[YouTubeDesk.captionIndex]?.text||'';textFormat:Text.PlainText;wrapMode:Text.Wrap;horizontalAlignment:Text.AlignHCenter;font.family:Appearance.font.ui;font.pixelSize:Math.max(15,Math.min(30,root.width*.025));font.weight:Font.Medium;color:Theme.paper}
    }
}
