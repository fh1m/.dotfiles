import QtQuick
import qs.components
import QtQuick.Controls
import qs.config
import qs.services
Column {
 id:root
 property bool follow:true
 property bool immersive:false
 property bool controlsVisible:true
 onControlsVisibleChanged:Qt.callLater(root.followLine)
 spacing:10
 onVisibleChanged:if(visible)Qt.callLater(root.followLine)
 onWidthChanged:Qt.callLater(root.followLine)
 onHeightChanged:Qt.callLater(root.followLine)
 function followLine(){if(visible&&follow&&SpotifyDesk.lyricIndex>=0)lines.positionViewAtIndex(SpotifyDesk.lyricIndex,ListView.Center);}
 Row {visible:root.controlsVisible;width:parent.width;spacing:8
 Text { textFormat: Text.PlainText;width:parent.width-286;anchors.verticalCenter:parent.verticalCenter;text:SpotifyDesk.lyricsLoading?'Loading lyrics…':SpotifyDesk.lyricsData.synced?'Live lyrics · '+(SpotifyDesk.lyricsData.provider||''):'Lyrics · '+(SpotifyDesk.lyricsData.provider||'');font.family:Appearance.font.forText(text);font.pixelSize:13;color:Theme.widgetMuted;elide:Text.ElideRight}
 MusicButton {accentColor:Theme.widgetAccent;implicitWidth:92;implicitHeight:30;label:'Follow';selected:root.follow;onActivated:{root.follow=true;root.followLine();}}
 MusicButton {accentColor:Theme.widgetAccent;implicitWidth:82;implicitHeight:30;label:'− 0.25s';onActivated:SpotifyDesk.adjustLyrics(-250)}
 MusicButton {accentColor:Theme.widgetAccent;implicitWidth:88;implicitHeight:30;label:'+ 0.25s';onActivated:SpotifyDesk.adjustLyrics(250)}
 }
 Text {visible:root.controlsVisible; textFormat: Text.PlainText;width:parent.width;height:18;text:SpotifyDesk.lyricsError||SpotifyDesk.lyricsData.notice||(SpotifyDesk.lyricsData.synced?'Click a line to seek · timing offset '+(SpotifyDesk.lyricOffset>=0?'+':'')+SpotifyDesk.lyricOffset+' ms':SpotifyDesk.lyricsLoading?'Sensei, finding this song…':'Timing is unavailable for this song.');font.family:Appearance.font.forText(text);font.pixelSize:11;color:SpotifyDesk.lyricsError?Theme.widgetAccent:Theme.widgetMuted;elide:Text.ElideRight}
 Row {visible:root.controlsVisible;width:parent.width;spacing:8
 MusicButton {implicitWidth:82;implicitHeight:30;glyph:'\uf021';label:'Retry';enabled:!SpotifyDesk.lyricsLoading;onActivated:SpotifyDesk.loadLyrics(true)}
 MusicButton {implicitWidth:128;implicitHeight:30;glyph:'\uf07c';label:'Local file';onActivated:SpotifyDesk.action('lyrics-folder',[JSON.stringify(SpotifyDesk.lyricTrack())])}
 Text {anchors.verticalCenter:parent.verticalCenter;width:parent.width-226;text:SpotifyDesk.lyricsData.instrumental?'INSTRUMENTAL':SpotifyDesk.lyricsData.synced?'TIMED':SpotifyDesk.lyricsData.plain?'PLAIN TEXT':'NO MATCH';font.family:Appearance.font.forText(text);font.pixelSize:10;color:Theme.widgetMuted;elide:Text.ElideRight}
 }
 ChamferPanel {width:parent.width;height:Math.max(140,root.height-(root.controlsVisible?106:0));fillColor:root.immersive?"transparent":Theme.widgetSurface;borderColor:root.immersive?"transparent":Theme.widgetBorder;chamfer:6;scanlines:false
 ListView {id:lines;boundsBehavior:Flickable.StopAtBounds;anchors.fill:parent;anchors.margins:12;clip:true;spacing:8;visible:SpotifyDesk.lyricsData.synced;model:SpotifyDesk.lyricsData.lines||[];topMargin:height*.35;bottomMargin:height*.35
 Behavior on contentY {enabled:root.follow;NumberAnimation {duration:240;easing.type:Easing.OutCubic}}
 onDraggingChanged:if(dragging)root.follow=false
 WheelHandler {onWheel:event=>{root.follow=false;event.accepted=false;}}
 ScrollBar.vertical:ScrollBar {onPressedChanged:if(pressed)root.follow=false}
 delegate:Rectangle {id:line;required property var modelData;required property int index;width:lines.width;height:Math.max(root.immersive?72:48,words.implicitHeight+22);radius:6;color:!root.immersive&&index===SpotifyDesk.lyricIndex?Theme.alpha(Theme.widgetAccent,.12):'transparent'
 Rectangle {visible:!root.immersive&&line.index===SpotifyDesk.lyricIndex;width:3;height:parent.height;color:Theme.widgetAccent;radius:1}
 readonly property bool current:index===SpotifyDesk.lyricIndex
 readonly property real start:Number(modelData.time)||0
 readonly property real finish:Number((SpotifyDesk.lyricsData.lines||[])[index+1]?.time)||Number(SpotifyDesk.playback.track?.duration)||start+4000
 readonly property real progress:current?Math.max(0,Math.min(1,(SpotifyDesk.lyricPosition+SpotifyDesk.lyricOffset-start)/Math.max(1,finish-start))):index<SpotifyDesk.lyricIndex?1:0
 Text {textFormat:Text.PlainText;id:words;x:16;y:11;width:parent.width-30;text:line.modelData.text||'♪';wrapMode:Text.Wrap;font.family:Appearance.font.forText(text);font.pixelSize:root.immersive?Math.max(23,Math.min(40,root.width*.052)):19;font.weight:Font.DemiBold;color:Theme.alpha(Theme.paper,line.current ? .65 : line.index<SpotifyDesk.lyricIndex ? .28 : .42);renderType:Text.QtRendering}
 Item {x:words.x;y:words.y;width:words.width;height:words.height;clip:true;visible:line.current
  Item {width:parent.width*line.progress;height:parent.height;clip:true;Behavior on width {enabled:root.visible&&SpotifyDesk.playing;NumberAnimation {duration:240;easing.type:Easing.Linear}}
   Text {width:words.width;text:words.text;textFormat:Text.PlainText;wrapMode:words.wrapMode;font:words.font;color:Theme.paper;renderType:Text.QtRendering}
  }
 }
 MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:{root.follow=true;SpotifyDesk.action('seek-to',[String(line.modelData.time)]);}}
 }
 }
 ScrollView {anchors.fill:parent;anchors.margins:14;visible:!SpotifyDesk.lyricsData.synced
 Text { textFormat: Text.PlainText;width:parent.width;text:SpotifyDesk.lyricsData.plain||SpotifyDesk.lyricsError||SpotifyDesk.lyricsData.notice||(SpotifyDesk.lyricsLoading?'Sensei, finding your lyrics…':'No timed lyrics are available for this track.');wrapMode:Text.Wrap;font.family:Appearance.font.forText(text);font.pixelSize:root.immersive?Math.max(24,Math.min(32,root.width*.025)):18;font.weight:root.immersive?Font.Medium:Font.Normal;lineHeight:1.5;color:root.immersive?'#fff6fb':Theme.widgetText}
 }
 }
 Connections {target:SpotifyDesk;function onLyricIndexChanged(){Qt.callLater(root.followLine);}function onLyricsDataChanged(){root.follow=true;Qt.callLater(root.followLine);}}
}
