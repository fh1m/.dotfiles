import QtQuick
import QtQuick.Controls
import Quickshell
import qs.components
import qs.config
import qs.services
DropdownFrame {
 headerAccent:Theme.widgetAccent
 id:root;property bool showTranscript:false;title:'󰭹 XKCD · Sensei’s intermission';katakana:'';implicitWidth:740;fillColor:Theme.widgetGlass
 focus:true
 Component.onCompleted:{DesktopExtras.loadComic();Qt.callLater(()=>root.forceActiveFocus());}
 Column {width:parent.width;spacing:10
  Row {spacing:8
   ControlTile {implicitWidth:95;label:'← Previous';enabled:!DesktopExtras.comicLoading&&(DesktopExtras.comic.num||1)>1;onActivated:DesktopExtras.loadComic(DesktopExtras.comic.num===405?403:DesktopExtras.comic.num-1)}
   ControlTile {implicitWidth:95;label:'Next →';enabled:!DesktopExtras.comicLoading&&DesktopExtras.comic.num<DesktopExtras.comic.latest;onActivated:DesktopExtras.loadComic(DesktopExtras.comic.num===403?405:DesktopExtras.comic.num+1)}
   ControlTile {implicitWidth:95;label:'Latest';onActivated:DesktopExtras.loadComic('latest')}
   ControlTile {implicitWidth:95;label:'Random';onActivated:DesktopExtras.loadComic('random')}
   ControlTile {implicitWidth:95;label:'Open web';onActivated:Quickshell.execDetached(['xdg-open',DesktopExtras.comic.url||'https://xkcd.com'])}
   ControlTile {implicitWidth:95;visible:!!DesktopExtras.comic.transcript;label:root.showTranscript?'Caption':'Transcript';onActivated:root.showTranscript=!root.showTranscript}
  }
  Text {width:parent.width;textFormat:Text.PlainText;text:DesktopExtras.comicLoading?'Sensei, fetching your comic…':'#'+(DesktopExtras.comic.num||'—')+' · '+(DesktopExtras.comic.title||'')+' · '+(DesktopExtras.comic.date||'');font.family:Appearance.font.ui;font.pixelSize:15;color:Theme.widgetText;wrapMode:Text.Wrap}
  Rectangle {width:parent.width;height:390;color:'#ffffff';radius:6
   Image {anchors.fill:parent;anchors.margins:12;source:DesktopExtras.comic.image||'';fillMode:Image.PreserveAspectFit;asynchronous:true}
   MouseArea {anchors.fill:parent;property real startX:0;onPressed:mouse=>startX=mouse.x;onReleased:mouse=>{if(mouse.x-startX>70&&DesktopExtras.comic.num>1)DesktopExtras.loadComic(DesktopExtras.comic.num-1);else if(startX-mouse.x>70&&DesktopExtras.comic.num<DesktopExtras.comic.latest)DesktopExtras.loadComic(DesktopExtras.comic.num+1);}}
  }
  ScrollView {width:parent.width;height:95;clip:true
   TextArea {readOnly:true;wrapMode:Text.Wrap;textFormat:TextEdit.PlainText;text:DesktopExtras.comicError||(root.showTranscript?DesktopExtras.comic.transcript:DesktopExtras.comic.alt)||'';font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetText;background:ChamferPanel {fillColor:Theme.widgetSurface;chamfer:6;scanlines:false}}
  }
  Text {width:parent.width;text:'← / → or swipe to browse · XKCD by Randall Munroe';font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
 }
 Keys.onLeftPressed:if(DesktopExtras.comic.num>1)DesktopExtras.loadComic(DesktopExtras.comic.num-1)
 Keys.onRightPressed:if(DesktopExtras.comic.num<DesktopExtras.comic.latest)DesktopExtras.loadComic(DesktopExtras.comic.num+1)
}
