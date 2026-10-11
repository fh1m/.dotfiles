import QtQuick
import qs.components
import QtQuick.Controls
import qs.config
import qs.services
Column {
 id:root
 property bool follow:true
 spacing:10
 function followLine(){if(follow&&SpotifyDesk.lyricIndex>=0)lines.positionViewAtIndex(SpotifyDesk.lyricIndex,ListView.Center);}
 Row {width:parent.width;spacing:8
 Text {width:parent.width-286;anchors.verticalCenter:parent.verticalCenter;text:SpotifyDesk.lyricsLoading?'Loading lyrics…':SpotifyDesk.lyricsData.synced?'Live lyrics · '+(SpotifyDesk.lyricsData.provider||''):'Lyrics · '+(SpotifyDesk.lyricsData.provider||'');font.family:Appearance.font.data;font.pixelSize:13;color:Theme.widgetMuted;elide:Text.ElideRight}
 ControlTile {accentColor:Theme.widgetAccent;implicitWidth:92;implicitHeight:30;label:'Follow';selected:root.follow;onActivated:{root.follow=true;root.followLine();}}
 ControlTile {accentColor:Theme.widgetAccent;implicitWidth:82;implicitHeight:30;label:'− 0.25s';onActivated:SpotifyDesk.lyricOffset-=250}
 ControlTile {accentColor:Theme.widgetAccent;implicitWidth:88;implicitHeight:30;label:'+ 0.25s';onActivated:SpotifyDesk.lyricOffset+=250}
 }
 Text {width:parent.width;height:18;text:SpotifyDesk.lyricsError||SpotifyDesk.lyricsData.notice||(SpotifyDesk.lyricsData.synced?'Click a line to seek · timing offset '+(SpotifyDesk.lyricOffset>=0?'+':'')+SpotifyDesk.lyricOffset+' ms':SpotifyDesk.lyricsLoading?'Sensei, finding this song…':'Timing is unavailable for this song.');font.family:Appearance.font.data;font.pixelSize:11;color:SpotifyDesk.lyricsError?Theme.widgetAccent:Theme.widgetMuted;elide:Text.ElideRight}
 ChamferPanel {width:parent.width;height:Math.max(140,root.height-68);fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder;chamfer:6;scanlines:false
 ListView {id:lines;anchors.fill:parent;anchors.margins:12;clip:true;spacing:8;visible:SpotifyDesk.lyricsData.synced;model:SpotifyDesk.lyricsData.lines||[];topMargin:height*.35;bottomMargin:height*.35
 Behavior on contentY {enabled:root.follow;NumberAnimation {duration:240;easing.type:Easing.OutCubic}}
 onDraggingChanged:if(dragging)root.follow=false
 WheelHandler {onWheel:event=>{root.follow=false;event.accepted=false;}}
 ScrollBar.vertical:ScrollBar {onPressedChanged:if(pressed)root.follow=false}
 delegate:Rectangle {id:line;required property var modelData;required property int index;width:lines.width;height:Math.max(48,words.implicitHeight+22);radius:6;color:index===SpotifyDesk.lyricIndex?Theme.alpha(Theme.widgetAccent,.12):'transparent'
 Rectangle {visible:line.index===SpotifyDesk.lyricIndex;width:3;height:parent.height;color:Theme.widgetAccent;radius:1}
 Text {id:words;x:16;y:11;width:parent.width-30;text:line.modelData.text||'♪';wrapMode:Text.Wrap;font.family:/[\u0980-\u09ff]/.test(text)?'Noto Sans Bengali':Appearance.font.data;font.pixelSize:18;font.weight:500;color:line.index===SpotifyDesk.lyricIndex?Theme.widgetAccent:line.index<SpotifyDesk.lyricIndex?Theme.widgetMuted:Theme.widgetText;renderType:Text.QtRendering;Behavior on color {ColorAnimation {duration:180}}}
 MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:{root.follow=true;SpotifyDesk.action('seek-to',[String(line.modelData.time)]);}}
 }
 }
 ScrollView {anchors.fill:parent;anchors.margins:14;visible:!SpotifyDesk.lyricsData.synced
 Text {width:parent.width;text:SpotifyDesk.lyricsData.plain||SpotifyDesk.lyricsError||SpotifyDesk.lyricsData.notice||(SpotifyDesk.lyricsLoading?'Sensei, finding your lyrics…':'No timed lyrics are available for this track.');wrapMode:Text.Wrap;font.family:Appearance.font.data;font.pixelSize:16;color:Theme.widgetText}
 }
 }
 Connections {target:SpotifyDesk;function onLyricIndexChanged(){Qt.callLater(root.followLine);}function onLyricsDataChanged(){root.follow=true;Qt.callLater(root.followLine);}}
}
