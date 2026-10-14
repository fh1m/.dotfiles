import QtQuick
import qs.config
import qs.services
import qs.components
ChamferPanel {
 id:root;required property var entry;property int number:0
 signal playRequested();signal browseRequested();signal queueRequested()
 readonly property bool currentTrack:entry.kind==='track'&&entry.id===SpotifyDesk.playback.track?.id
 width:parent?.width??680;height:58;chamfer:6;scanlines:false;fillColor:currentTrack?Theme.blend(Theme.widgetSurface,Theme.widgetAccent,.12):hover.hovered?Theme.widgetRaised:Theme.widgetSurface;borderColor:currentTrack?Theme.alpha(Theme.widgetAccent,.6):Theme.widgetBorder
 Behavior on fillColor {ColorAnimation {duration:140}}
 Behavior on borderColor {ColorAnimation {duration:140}}
 HoverHandler {id:hover}
 RoundedArtwork {id:cover;cornerRadius:5;x:7;y:7;width:44;height:44;source:root.entry.art||'';sourceSize:Qt.size(88,88);fillMode:Image.PreserveAspectCrop;asynchronous:true;visible:status===Image.Ready}
 Text {anchors.centerIn:cover;visible:!cover.visible;text:root.entry.kind==='playlist'?'\uf03a':root.entry.kind==='artist'?'\uf007':'\uf001';color:Theme.widgetMuted;font.family:Appearance.font.icons;font.pixelSize:20}
 Column {x:62;y:10;width:parent.width-222;spacing:4
 Text {width:parent.width;text:root.entry.title||'Untitled';elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetText}
 Text {width:parent.width;text:(root.entry.artist||'')+(root.entry.album?' · '+root.entry.album:'')+(root.entry.explicit?' · E':'');elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
 }
 Text {anchors.right:buttons.left;anchors.rightMargin:10;anchors.verticalCenter:parent.verticalCenter;text:root.entry.duration?SpotifyDesk.fmt(root.entry.duration):root.entry.count?root.entry.count+' songs':'';font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
 Row {id:buttons;anchors.right:parent.right;anchors.rightMargin:8;anchors.verticalCenter:parent.verticalCenter;spacing:6
 ControlTile {implicitWidth:28;implicitHeight:28;accentColor:Theme.widgetAccent;glyph:root.entry.kind==='track'?'\uf067':'\uf03a';Accessible.name:root.entry.kind==='track'?'Add to queue':'Open collection';onActivated:root.entry.kind==='track'?root.queueRequested():root.browseRequested()}
 ControlTile {implicitWidth:28;implicitHeight:28;accentColor:Theme.widgetAccent;glyph:'\uf04b';Accessible.name:'Play '+root.entry.title;onActivated:root.playRequested()}

 }
 MouseArea {x:0;y:0;width:parent.width-170;height:parent.height;cursorShape:Qt.PointingHandCursor;onClicked:root.entry.kind==='track'?root.playRequested():root.browseRequested()}
 TapHandler {acceptedButtons:Qt.RightButton;onTapped:root.entry.kind==='track'?root.queueRequested():root.browseRequested()}
}
