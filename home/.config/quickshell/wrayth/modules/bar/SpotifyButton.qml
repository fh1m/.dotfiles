import QtQuick
import QtQuick.Shapes
import qs.components
import qs.config
import qs.services
Item {
 Behavior on width {NumberAnimation {duration:180;easing.type:Easing.OutCubic}}
 id:root;implicitHeight:36;implicitWidth:Math.max(180,Math.min(570,titleMeasure.implicitWidth+94));clip:true
 Text { renderType: Text.QtRendering; renderTypeQuality: 104;id:titleMeasure;visible:false;text:(SpotifyDesk.trackLoading?'LOADING · ':'')+SpotifyDesk.title+' - '+SpotifyDesk.artist;font.family:Appearance.font.data;font.pixelSize:13;font.letterSpacing:Appearance.size.ticker*Appearance.tickerTracking}
 Shape {anchors.fill:parent;preferredRendererType:Shape.GeometryRenderer
 ShapePath {fillColor:ShellState.dropdown==='spotify'?Theme.alpha(Theme.spotifyGreen,.07):Theme.alpha(Theme.deep,.7);strokeWidth:1;strokeColor:"#000000";startX:14;startY:.5
 PathLine {x:root.width-.5;y:.5}
 PathLine {x:root.width-14;y:root.height-.5}
 PathLine {x:.5;y:root.height-.5}
 PathLine {x:14;y:.5}
 }
 }
 RoundedArtwork {id:art;cornerRadius:15;anchors.left:parent.left;anchors.leftMargin:22;anchors.verticalCenter:parent.verticalCenter;width:30;height:30;opacity:SpotifyDesk.trackLoading?.48:1;rotation:SpotifyDesk.playing&&!SpotifyDesk.trackLoading&&visible?(MotionClock.ms%12000)*.03:0
 source:SpotifyDesk.albumArt;sourceSize:Qt.size(120,120);fillMode:Image.PreserveAspectCrop;asynchronous:true;visible:status===Image.Ready}
 Text { renderType: Text.QtRendering; renderTypeQuality: 104;anchors.centerIn:art;visible:!art.visible;text:"\uf001";font.family:Appearance.font.icons;font.pixelSize:16;color:Theme.dim}
 Text {renderType:Text.NativeRendering;anchors.centerIn:art;visible:SpotifyDesk.trackLoading;text:"\uf110";font.family:Appearance.font.icons;font.pixelSize:19;color:Theme.spotifyGreen;rotation:(MotionClock.ms%900)*.4}
 Ticker {anchors.left:art.right;anchors.leftMargin:12;anchors.right:parent.right;anchors.rightMargin:20;anchors.verticalCenter:parent.verticalCenter;height:24;scrollOnlyOverflow:true;loopGap:28;scrollEnabled:SpotifyDesk.playing&&!SpotifyDesk.trackLoading;text:SpotifyDesk.trackLoading?'LOADING · '+SpotifyDesk.title:SpotifyDesk.title==='Spotify'?'Spotify · Sensei’s soundtrack':SpotifyDesk.title+' - '+SpotifyDesk.artist;foreground:SpotifyDesk.trackLoading?Theme.signal:SpotifyDesk.playing?Theme.spotifyGreen:Theme.dim;pixelSize:13;speed:25;fade:8}
 MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;acceptedButtons:Qt.LeftButton|Qt.RightButton|Qt.MiddleButton;onClicked:e=>{if(e.button===Qt.RightButton||e.button===Qt.MiddleButton)SpotifyDesk.action('toggle');else{ShellState.dropdownAnchorX=root.mapToItem(null,0,0).x;ShellState.toggleDropdown('spotify');}}}
}
