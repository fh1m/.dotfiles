import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.components
DropdownFrame {
 headerAccent:Theme.widgetAccent
 id:root;title:"\uf1bc Spotify studio";katakana:"МУЗЫКА";implicitWidth:1080;fillColor:Theme.widgetGlass
 IpcHandler {target:"spotifyview";function state():string{return JSON.stringify({count:musicList.count,visible:musicList.visible,query:SpotifyDesk.query,contextId:SpotifyDesk.contextItem.id||"",loading:SpotifyDesk.loading,error:SpotifyDesk.error});}function filter(text:string):void{SpotifyDesk.query=text;}}
 property int page:SpotifyDesk.page
 readonly property real position:SpotifyDesk.positionMs
 readonly property real duration:SpotifyDesk.playback.track?.duration||SpotifyDesk.player?.length*1000||1
 property string playlistToAdd:""
 property real contentWidth:root.width-28
 Popup {
 id:artViewer;parent:Overlay.overlay;visible:SpotifyDesk.artExpanded;onClosed:SpotifyDesk.artExpanded=false;width:Math.min(700,parent.width-32);height:Math.min(750,parent.height-32);x:(parent.width-width)/2;y:(parent.height-height)/2;modal:true;focus:true;padding:16;closePolicy:Popup.CloseOnEscape|Popup.CloseOnPressOutside
 background:ChamferPanel {fillColor:Theme.widgetGlass;chamfer:Appearance.chamfer.panel;borderColor:Theme.widgetBorder;borderWidth:1;scanlines:false}
 contentItem:Column {spacing:10
 RoundedArtwork {cornerRadius:12;width:artViewer.availableWidth;height:artViewer.availableHeight-65;source:SpotifyDesk.albumArt;sourceSize:Qt.size(1024,1024);fillMode:Image.PreserveAspectFit;asynchronous:true}
 Row {width:parent.width;Text {width:parent.width-100;text:SpotifyDesk.title+' - '+SpotifyDesk.artist;elide:Text.ElideRight;font.family:Appearance.font.data;font.pixelSize:13;color:Theme.widgetText}ControlTile {accentColor:Theme.widgetAccent;implicitWidth:96;implicitHeight:30;label:'Close';onActivated:artViewer.close()}}
 }
 }
 Column {width:parent.width;spacing:12
 Row {spacing:7;Repeater {model:['Now playing','Queue','Playlists','Library','Search','Devices','Account'];ControlTile {accentColor:Theme.widgetAccent;required property string modelData;required property int index;implicitWidth:Math.floor((root.width-28-42)/7);implicitHeight:32;label:modelData;selected:SpotifyDesk.page===index;onActivated:SpotifyDesk.page=index}}}
 Row {width:parent.width;spacing:16
 ChamferPanel {id:playerPane;width:342;height:Math.max(670,playerContents.implicitHeight+28);fillColor:Theme.alpha(Theme.widgetSurface,.85);borderColor:Theme.widgetBorder;chamfer:6;scanlines:false
 Column {id:playerContents;anchors.fill:parent;anchors.margins:14;spacing:12
 ChamferPanel {width:312;height:312;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder;chamfer:6;scanlines:false
 RoundedArtwork {cornerRadius:10;anchors.fill:parent;anchors.margins:1;source:SpotifyDesk.albumArt;sourceSize:Qt.size(640,640);fillMode:Image.PreserveAspectCrop;asynchronous:true}
 MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:SpotifyDesk.artExpanded=true}
 Text {anchors.centerIn:parent;visible:SpotifyDesk.albumArt==='';text:'\uf1bc';font.family:Appearance.font.icons;font.pixelSize:88;color:Theme.widgetMuted}
 Rectangle {anchors.bottom:parent.bottom;anchors.right:parent.right;anchors.margins:7;width:24;height:24;radius:12;color:Theme.widgetSurface;Text {anchors.centerIn:parent;text:'\uf1bc';font.family:Appearance.font.icons;font.pixelSize:17;color:SpotifyDesk.playing?Theme.widgetAccent:Theme.widgetMuted}}
 }
 Text {width:312;text:SpotifyDesk.title;wrapMode:Text.Wrap;maximumLineCount:2;elide:Text.ElideRight;font.family:Appearance.font.data;font.pixelSize:17;font.weight:600;color:Theme.widgetText}
 Text {width:312;text:SpotifyDesk.artist;wrapMode:Text.Wrap;maximumLineCount:2;elide:Text.ElideRight;font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetMuted}
 Text {width:312;text:SpotifyDesk.album;elide:Text.ElideRight;font.family:Appearance.font.data;font.pixelSize:11;color:Theme.widgetMuted}
 Slider {id:seek;width:312;height:24;from:0;to:Math.max(1,root.duration);Binding {target:seek;property:'value';value:root.position;when:!seek.pressed;restoreMode:Binding.RestoreNone}onMoved:SpotifyDesk.action('seek-to',[String(Math.round(value))]);background:Rectangle {x:seek.leftPadding;y:seek.topPadding+seek.availableHeight/2-2;width:seek.availableWidth;height:4;radius:5;color:Theme.widgetBorder;Rectangle {width:parent.width*seek.visualPosition;height:4;radius:5;color:Theme.widgetAccent}}handle:Rectangle {x:seek.leftPadding+seek.visualPosition*(seek.availableWidth-width);y:seek.topPadding+seek.availableHeight/2-6;width:12;height:12;radius:6;color:Theme.widgetAccent}}
 Row {width:312;Text {width:156;text:SpotifyDesk.fmt(root.position);font.family:Appearance.font.data;font.pixelSize:11;color:Theme.widgetMuted}Text {width:156;horizontalAlignment:Text.AlignRight;text:SpotifyDesk.fmt(root.duration);font.family:Appearance.font.data;font.pixelSize:11;color:Theme.widgetMuted}}
 Row {spacing:8;Repeater {model:[{glyph:'\uf048',action:'previous'},{glyph:SpotifyDesk.playing?'\uf04c':'\uf04b',action:'toggle'},{glyph:'\uf051',action:'next'}];ControlTile {accentColor:Theme.widgetAccent;required property var modelData;implicitWidth:98;implicitHeight:38;glyph:modelData.glyph;selected:modelData.action==='toggle'?SpotifyDesk.playing:SpotifyDesk.skipPending===modelData.action;onActivated:SpotifyDesk.action(modelData.action)}}}
 Row {spacing:7;ControlTile {accentColor:Theme.widgetAccent;implicitWidth:152;implicitHeight:30;label:'Shuffle';glyph:'\uf074';selected:SpotifyDesk.playback.shuffle;onActivated:SpotifyDesk.action('shuffle')}ControlTile {accentColor:Theme.widgetAccent;implicitWidth:152;implicitHeight:30;label:'Repeat '+(SpotifyDesk.playback.repeat||'off');onActivated:SpotifyDesk.action('repeat')}}
 ControlSlider {accentColor:Theme.widgetAccent;width:312;title:'Spotify volume';level:SpotifyDesk.volume;onEdited:v=>SpotifyDesk.action('volume',[String(Math.round(v))])}
 }
 }
 Column {width:parent.width-358;spacing:10
 Item {width:parent.width;height:34
 Text {anchors.left:parent.left;anchors.verticalCenter:parent.verticalCenter;text:SpotifyDesk.contextItem.id?(SpotifyDesk.contextItem.title||'Loading collection…'):root.page===0?(SpotifyDesk.queueRows.length?'Up next · '+SpotifyDesk.queueRows.length+' songs':'Your recent rotation'):root.page===1?'Up next · '+SpotifyDesk.queueRows.length+' songs':root.page===2?'Your playlists':root.page===3?'Your music library':root.page===4?'Discover your next favourite':root.page===5?'Spotify Connect devices':'Your music account';font.family:Appearance.font.data;font.pixelSize:16;color:Theme.widgetText;elide:Text.ElideRight;width:parent.width-120}
 ControlTile {accentColor:Theme.widgetAccent;anchors.right:parent.right;implicitWidth:100;implicitHeight:30;label:SpotifyDesk.contextItem.id?'Back':'Refresh';glyph:SpotifyDesk.contextItem.id?'\uf060':'\uf021';onActivated:SpotifyDesk.refresh(true)}
 }
 Row {visible:root.page===0;spacing:8
 ControlTile {accentColor:Theme.widgetAccent;implicitWidth:(parent.parent.width-24)/4;implicitHeight:30;glyph:'\uf004';label:'Save song';enabled:!!SpotifyDesk.playback.track?.id;onActivated:SpotifyDesk.action('like')}
 ControlTile {accentColor:Theme.widgetAccent;implicitWidth:(parent.parent.width-24)/4;implicitHeight:30;label:'Remove liked';enabled:!!SpotifyDesk.playback.track?.id;onActivated:SpotifyDesk.action('unlike')}
 ControlTile {accentColor:Theme.widgetAccent;implicitWidth:(parent.parent.width-24)/4;implicitHeight:30;glyph:'\uf025';label:'Liked songs';onActivated:SpotifyDesk.action('liked-play')}
 ControlTile {accentColor:Theme.widgetAccent;implicitWidth:(parent.parent.width-24)/4;implicitHeight:30;glyph:'\uf15c';label:'Lyrics';selected:SpotifyDesk.lyricsOpen;onActivated:SpotifyDesk.lyricsOpen=!SpotifyDesk.lyricsOpen}
 }
 ChamferPanel {visible:root.page===0;width:parent.width;height:68;fillColor:Theme.alpha(Theme.widgetSurface,.6);borderColor:Theme.widgetBorder;chamfer:6;scanlines:false
 Column {anchors.fill:parent;anchors.margins:10;spacing:7;Text {width:parent.width;text:(SpotifyDesk.skipPending?'Switching track…':SpotifyDesk.playing?'Playing':'Paused')+' · '+(SpotifyDesk.playback.device||'Sensei · ZenBook Duo')+' · Premium streaming';font.family:Appearance.font.data;font.pixelSize:12;color:SpotifyDesk.playing?Theme.widgetAccent:Theme.widgetMuted;elide:Text.ElideRight}Text {width:parent.width;text:'Ctrl + Space  play / pause     •     right-click music badge to toggle';font.family:Appearance.font.data;font.pixelSize:11;color:Theme.widgetMuted;elide:Text.ElideRight}}
 }
 Row {visible:root.page===3;spacing:6;Repeater {model:[{key:'liked',label:'Liked'},{key:'albums',label:'Albums'},{key:'artists',label:'Artists'},{key:'recent',label:'Recent'},{key:'top',label:'Top tracks'}];ControlTile {accentColor:Theme.widgetAccent;required property var modelData;implicitWidth:(parent.parent.width-24)/5;implicitHeight:30;label:modelData.label;selected:SpotifyDesk.libraryKind===modelData.key;onActivated:SpotifyDesk.libraryKind=modelData.key}}}
 DeskTextField {visible:root.page===2||root.page===3||root.page===4;width:parent.width;height:36;placeholderText:root.page===4?'Search songs, artists, albums and playlists…':'Filter your music…';text:SpotifyDesk.query;onTextEdited:SpotifyDesk.query=text}
 Row {visible:root.page===4;spacing:7;Repeater {model:['tracks','albums','artists','playlists'];ControlTile {accentColor:Theme.widgetAccent;required property string modelData;implicitWidth:(parent.parent.width-21)/4;implicitHeight:30;label:modelData[0].toUpperCase()+modelData.slice(1);selected:SpotifyDesk.searchKind===modelData;onActivated:SpotifyDesk.searchKind=modelData}}}
 Row {visible:root.page===2;spacing:8
 DeskTextField {id:playlistName;width:parent.parent.width-354;height:32;placeholderText:'New private playlist name'}
 ControlTile {accentColor:Theme.widgetAccent;implicitWidth:140;implicitHeight:32;label:'Create playlist';enabled:playlistName.text.trim()!=='';onActivated:{SpotifyDesk.action('playlist-create',[playlistName.text.trim()]);playlistName.text='';}}
 ControlTile {accentColor:Theme.widgetAccent;implicitWidth:198;implicitHeight:32;label:'Add current to selected';enabled:root.playlistToAdd!==''&&!!SpotifyDesk.playback.track?.uri;onActivated:SpotifyDesk.action('playlist-add',[root.playlistToAdd,SpotifyDesk.playback.track.uri])}
 }
 Row {visible:!!SpotifyDesk.contextItem.id;spacing:8
 ControlTile {accentColor:Theme.widgetAccent;implicitWidth:160;implicitHeight:30;label:'Play collection';glyph:'\uf04b';onActivated:SpotifyDesk.play(SpotifyDesk.contextItem)}
 Text {width:parent.parent.width-168;anchors.verticalCenter:parent.verticalCenter;text:SpotifyDesk.contextRows.length+' songs · '+(SpotifyDesk.contextItem.description||SpotifyDesk.contextItem.artist||'');elide:Text.ElideRight;font.family:Appearance.font.data;font.pixelSize:11;color:Theme.widgetMuted}
 }
 ListView {id:musicList;visible:root.page<5&&!(root.page===0&&SpotifyDesk.lyricsOpen);width:parent.width;height:Math.max(100,playerPane.height-musicList.y-0-(loadMore.visible?42:0));clip:true;spacing:6;reuseItems:true;cacheBuffer:120
 model:SpotifyDesk.visibleRows.filter(e=>root.page===4||!SpotifyDesk.query||((e.title||'')+' '+(e.artist||'')+' '+(e.album||'')).toLowerCase().includes(SpotifyDesk.query.toLowerCase()))
 delegate:SpotifyRow {required property var modelData;required property int index;width:musicList.width;entry:modelData;number:index+1;onPlayRequested:SpotifyDesk.play(modelData);onBrowseRequested:{if(modelData.kind==='playlist')root.playlistToAdd=modelData.id;SpotifyDesk.browse(modelData);}onQueueRequested:SpotifyDesk.action('enqueue',[modelData.uri])}
 ScrollBar.vertical:DeskScrollBar {}
 Text {visible:musicList.count===0;anchors.centerIn:parent;width:parent.width-40;horizontalAlignment:Text.AlignHCenter;wrapMode:Text.Wrap;text:SpotifyDesk.loading?'Sensei, loading your music…':root.page===4?'Type a song, artist, album or playlist above.':SpotifyDesk.error?SpotifyDesk.error:SpotifyDesk.contextItem.id?'This collection returned no playable songs. Choose another collection or refresh.':'Sensei, choose a playlist or liked songs to start your soundtrack.';font.family:Appearance.font.data;font.pixelSize:13;color:Theme.widgetMuted}
 }
 ControlTile {id:loadMore;visible:root.page>=2&&root.page<=3&&SpotifyDesk.nextPage!=='';accentColor:Theme.widgetAccent;implicitWidth:parent.width;implicitHeight:32;label:'Load more · '+SpotifyDesk.visibleRows.length+' of '+SpotifyDesk.totalRows+' songs / collections';enabled:!SpotifyDesk.loading;onActivated:SpotifyDesk.more()}
 LyricsFollower {id:lyricsPanel;visible:root.page===0&&SpotifyDesk.lyricsOpen;width:parent.width;height:Math.max(220,playerPane.height-y)}
 ListView {id:deviceList;visible:root.page===5;width:parent.width;height:playerPane.height-deviceList.y;model:SpotifyDesk.devices;spacing:8;clip:true;ScrollBar.vertical:DeskScrollBar {}
 delegate:ChamferPanel {required property var modelData;width:deviceList.width;height:76;fillColor:Theme.alpha(Theme.widgetSurface,.6);borderColor:(SpotifyDesk.playback.selectedDeviceId?SpotifyDesk.playback.selectedDeviceId===modelData.id:modelData.is_active)?Theme.widgetAccent:Theme.widgetBorder;chamfer:6;scanlines:false
 Column {x:12;y:12;width:parent.width-200;spacing:7;Text {width:parent.width;text:modelData.name||'Spotify device';font.family:Appearance.font.data;font.pixelSize:14;color:Theme.widgetText;elide:Text.ElideRight}Text {text:(modelData.is_active?'Active · ':'')+(modelData.type||'device')+' · volume '+(modelData.volume_percent??0)+'%';font.family:Appearance.font.data;font.pixelSize:11;color:Theme.widgetMuted}}
 ControlTile {accentColor:Theme.widgetAccent;anchors.right:parent.right;anchors.rightMargin:12;anchors.verticalCenter:parent.verticalCenter;implicitWidth:156;implicitHeight:32;label:SpotifyDesk.playback.selectedDeviceId===modelData.id?(modelData.is_active?'Selected · active':'Selected · waiting'):modelData.is_active?'Active elsewhere':'Listen here';selected:SpotifyDesk.playback.selectedDeviceId?SpotifyDesk.playback.selectedDeviceId===modelData.id:modelData.is_active;enabled:!!modelData.id;onActivated:SpotifyDesk.action('connect',[modelData.id])}
 }
 }
 Column {visible:root.page===6;width:parent.width;spacing:14
 ChamferPanel {width:parent.width;height:176;fillColor:Theme.alpha(Theme.widgetSurface,.7);borderColor:Theme.widgetBorder;chamfer:6;scanlines:false
 Column {anchors.fill:parent;anchors.margins:18;spacing:13
 Text {text:'Sensei, your music lives here.';font.family:Appearance.font.data;font.pixelSize:18;color:Theme.widgetText}
 Text {width:parent.width;text:'Player  spotify-player '+SpotifyDesk.account.version+'\nService  '+SpotifyDesk.account.service+'\nConnect name  Sensei · ZenBook Duo\nLogin  '+(SpotifyDesk.account.cachedLogin?'Saved on this laptop':'Sign in once in your browser');font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetMuted;lineHeight:1.45}
 }
 }
 Row {spacing:10;ControlTile {accentColor:Theme.widgetAccent;implicitWidth:(parent.parent.width-20)/3;label:'Sign in / reconnect';glyph:'\uf1bc';onActivated:SpotifyDesk.login()}ControlTile {accentColor:Theme.widgetAccent;implicitWidth:(parent.parent.width-20)/3;label:'Restart music service';glyph:'\uf021';onActivated:SpotifyDesk.restart()}ControlTile {accentColor:Theme.widgetAccent;implicitWidth:(parent.parent.width-20)/3;label:'Open Spotify web';glyph:'\uf08e';onActivated:Quickshell.execDetached(['xdg-open','https://open.spotify.com/'])}}
 ChamferPanel {width:parent.width;height:250;fillColor:Theme.alpha(Theme.widgetSurface,.7);borderColor:Theme.widgetBorder;chamfer:6;scanlines:false
 Column {anchors.fill:parent;anchors.margins:18;spacing:14
 Text {width:parent.width;text:'Ready in the background';font.family:Appearance.font.data;font.pixelSize:16;color:Theme.widgetText}
 Text {width:parent.width;text:'The player starts with your desktop and stays paused until you choose music. No browser or terminal stays open for playback.\n\nAlbum art is cached; playlists and library refresh on demand. Playback status arrives through desktop media signals. Queue refreshes only while this widget is open and music is playing.\n\nSpotify Premium is required. Account access and available catalogue features depend on Spotify. Offline downloads are not supported by this client.';wrapMode:Text.Wrap;font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetMuted;lineHeight:1.3}
 }
 }
 }
 }
 }
 Text {width:parent.width;text:SpotifyDesk.error||SpotifyDesk.warning||(SpotifyDesk.loading?'Sensei, loading your music…':'Sensei, your soundtrack is ready.');font.family:Appearance.font.data;font.pixelSize:11;color:SpotifyDesk.error?Theme.widgetAccent:Theme.widgetMuted;wrapMode:Text.Wrap;maximumLineCount:2;elide:Text.ElideRight}
 }
}
