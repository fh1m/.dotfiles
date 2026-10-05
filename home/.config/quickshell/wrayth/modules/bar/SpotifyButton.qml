import QtQuick
import QtQuick.Shapes
import qs.components
import qs.config
import qs.services
Item {
 Behavior on width {NumberAnimation {duration:180;easing.type:Easing.OutCubic}}
 id:root;implicitHeight:36;implicitWidth:Math.max(180,Math.min(420,titleMeasure.implicitWidth+94));clip:true
 Text { renderType: Text.QtRendering; renderTypeQuality: 104;id:titleMeasure;visible:false;text:(SpotifyDesk.trackLoading?'LOADING · ':'')+SpotifyDesk.title+' - '+SpotifyDesk.artist;font.family:Appearance.font.barUi;font.pixelSize:13}
 Rectangle { anchors.fill:parent; color:Theme.ink }
 Rectangle { anchors.left:parent.left; anchors.leftMargin:2; anchors.verticalCenter:parent.verticalCenter; width:2; height:24; color:SpotifyDesk.playing?Theme.signalRed:Theme.rule }
 RoundedArtwork {id:art;cornerRadius:4;anchors.left:parent.left;anchors.leftMargin:12;anchors.verticalCenter:parent.verticalCenter;width:28;height:28;rotation:0;opacity:SpotifyDesk.trackLoading?.48:1
 source:SpotifyDesk.albumArt;sourceSize:Qt.size(120,120);fillMode:Image.PreserveAspectCrop;asynchronous:true;visible:status===Image.Ready}
 Text { renderType: Text.QtRendering; renderTypeQuality: 104;anchors.centerIn:art;visible:!art.visible;text:"\uf001";font.family:Appearance.font.icons;font.pixelSize:16;color:Theme.dim}
 Text {id:loadingGlyph;renderType:Text.NativeRendering;anchors.centerIn:art;visible:SpotifyDesk.trackLoading;text:"\uf110";font.family:Appearance.font.icons;font.pixelSize:19;color:Theme.signalRed;rotation:0
 NumberAnimation on rotation {from:0;to:360;duration:900;loops:Animation.Infinite;running:loadingGlyph.visible}
 }
 Rectangle {
  anchors.centerIn: art; width: 19; height: 19; radius: 10
  color: "#d0090807"; visible: !SpotifyDesk.playing && !SpotifyDesk.trackLoading && art.visible
  Text { anchors.centerIn: parent; text: "\uf04b"; font.family: Appearance.font.icons; font.pixelSize: 11; color: Theme.paper }
 }
 Ticker {anchors.left:art.right;anchors.leftMargin:9;anchors.right:parent.right;anchors.rightMargin:12;anchors.verticalCenter:parent.verticalCenter;height:24;scrollOnlyOverflow:true;loopGap:28;scrollEnabled:SpotifyDesk.playing&&!SpotifyDesk.trackLoading;text:SpotifyDesk.trackLoading?'Loading · '+SpotifyDesk.title:SpotifyDesk.title==='Spotify'?'Spotify · Sensei’s soundtrack':SpotifyDesk.title+' - '+SpotifyDesk.artist;foreground:SpotifyDesk.playing?Theme.signalRed:Theme.paperMuted;fontFamily:Appearance.font.barUi;pixelSize:12;speed:25;fade:8}
 MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;acceptedButtons:Qt.LeftButton|Qt.RightButton|Qt.MiddleButton;onClicked:e=>{if(e.button===Qt.RightButton||e.button===Qt.MiddleButton)SpotifyDesk.action('toggle');else{ShellState.dropdownAnchorX=root.mapToItem(null,0,0).x;ShellState.toggleDropdown('spotify');}}}
}
