import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.components
import qs.config
import qs.services

// Presentation only. Transport, catalogue, lyrics and request budgets stay in SpotifyDesk.
PanelWindow {
    id: window
    readonly property var destination: ShellState.screens.find(s=>s.name===SpotifyDesk.fullscreenOutput)
        || ShellState.screens.find(s=>s.name===MachineProfile.primaryOutput) || ShellState.screens[0]
    screen: destination
    visible: SpotifyDesk.fullscreen && !!destination
    anchors {top:true;bottom:true;left:true;right:true}
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: SpotifyDesk.musicBackdrop ? WlrLayer.Bottom : WlrLayer.Top
    WlrLayershell.namespace: "sensei-music-fullscreen"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: Theme.ink
    MusicVideos {parent:window.contentItem;fullscreenHost:true}
    property color wash: "#402131"
    property color edge: "#171019"
    property string sampledArt: ""
    property int collection: 0
    property bool collectionOpen:false
    property bool queuePinned:false
    Timer {interval:12000;running:window.visible&&window.collectionOpen&&!window.queuePinned&&!listHover.hovered;onTriggered:window.collectionOpen=false}
    property bool showTools:true
    property bool focusArmed:false
    HyprlandFocusGrab {active:window.visible&&window.focusArmed&&!SpotifyDesk.musicBackdrop;windows:[window];onCleared:window.focusArmed=false}
    TapHandler {onTapped:{if(!SpotifyDesk.musicBackdrop)window.focusArmed=true;}}
    Item {width:parent.width;height:84;HoverHandler {id:toolbarHover}}
    Timer {interval:3500;running:window.visible;onTriggered:window.showTools=false}
    readonly property var rows: collection===0 ? SpotifyDesk.queueRows : SpotifyDesk.contextItem.id ? SpotifyDesk.contextRows : SpotifyDesk.playlistRows
    function sample(){if(!visible||palette.running||!SpotifyDesk.albumArt)return;sampledArt=SpotifyDesk.albumArt;palette.command=[Quickshell.env('HOME')+'/.local/bin/sensei-music-palette',sampledArt];palette.running=true;}
    onVisibleChanged: if(visible){focusArmed=true;showTools=true;stage.forceActiveFocus();sample();}else focusArmed=false;
    Connections {target:SpotifyDesk;function onAlbumArtChanged(){if(!SpotifyDesk.albumArt){window.wash='#402131';window.edge='#171019';}window.sample();}}
    Process {id:palette;stdout:StdioCollector {onStreamFinished:{if(window.sampledArt!==SpotifyDesk.albumArt)return;try{const p=JSON.parse(text);window.wash=p.wash;window.edge=p.edge;}catch(e){}}}onExited:if(window.sampledArt!==SpotifyDesk.albumArt)window.sample()}
    IpcHandler {target:"music-fullscreen";function state():string{return JSON.stringify({visible:window.visible,output:window.screen?.name,width:window.width,height:window.height,rows:window.rows.length,collection:window.collection,collectionOpen:window.collectionOpen,zen:SpotifyDesk.zen,backdrop:SpotifyDesk.musicBackdrop,focusArmed:window.focusArmed,seek:seek.value,duration:SpotifyDesk.playback.track?.duration,position:SpotifyDesk.positionMs,lyrics:SpotifyDesk.lyricsData.lines?.length||0,wash:String(window.wash)});}function mode(name:string):void {SpotifyDesk.zen=name==='focus';}function backdrop(enabled:bool):void {SpotifyDesk.musicBackdrop=enabled;}function display(name:string):void {if(ShellState.screens.some(s=>s.name===name))SpotifyDesk.fullscreenOutput=name;}function collection(index:int):void{window.collectionOpen=true;window.collection=Math.max(0,Math.min(1,index));}}
    Rectangle {anchors.fill:parent;gradient:Gradient {orientation:Gradient.Horizontal;GradientStop {position:0;color:window.wash}GradientStop {position:.65;color:window.edge}GradientStop {position:1;color:Theme.ink}}}
    FocusScope {
        id:stage
        anchors.fill:parent
        focus:true
        Keys.onEscapePressed:if(SpotifyDesk.zen)SpotifyDesk.zen=false;else SpotifyDesk.collapse(true)
        Keys.onPressed:event=>{if(event.key===Qt.Key_F){SpotifyDesk.zen=!SpotifyDesk.zen;event.accepted=true;}else if(event.key===Qt.Key_F11){SpotifyDesk.collapse(true);event.accepted=true;}}
        // Only act on unhandled Space; text fields and buttons retain their own keys.
        Keys.onSpacePressed:event=>{SpotifyDesk.action('toggle');event.accepted=true;}
        readonly property int gutter: Math.max(18,Math.min(44,width*.025))
        readonly property real bodyTop: 88
        readonly property real bodyHeight:height-bodyTop-54
        readonly property real cardWidth:Math.min(390,width*.28)
        readonly property real listWidth:window.collectionOpen?Math.min(590,width*.36):0
        readonly property real lyricWidth:width-2*gutter-cardWidth-listWidth-(window.collectionOpen?40:20)
        Rectangle {visible:!SpotifyDesk.zen;x:stage.gutter;y:26;width:3;height:28;color:Theme.signalRed;radius:1}
        Text {visible:!SpotifyDesk.zen;x:stage.gutter+16;y:23;text:'LISTENING ROOM';font.family:Appearance.font.heading;font.pixelSize:20;font.weight:Font.DemiBold;color:Theme.paper}
        Text {visible:!SpotifyDesk.zen;x:stage.gutter+16;y:51;text:SpotifyDesk.playing?'Your soundtrack. Room to breathe.':'Paused · the room is yours.';font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paperMuted}
        Row {anchors.right:parent.right;anchors.rightMargin:stage.gutter; y:27;spacing:8
            opacity:1 // Exit and display controls must never disappear during pointer travel.
            enabled:opacity>.5
            Behavior on opacity {NumberAnimation {duration:200}}
            DeskComboBox {width:180;height:38;model:ShellState.screens.map(s=>s.name+' · '+MachineProfile.role(s.name));currentIndex:ShellState.screens.findIndex(s=>s.name===window.screen?.name);onActivated:SpotifyDesk.fullscreenOutput=ShellState.screens[currentIndex].name;Accessible.name:'Move listening room to display'}
            MusicButton {implicitWidth:116;label:window.collectionOpen?'Hide queue':'Queue';glyph:'\uf03a';selected:window.collectionOpen;onActivated:window.collectionOpen=!window.collectionOpen}
            MusicButton {visible:window.collectionOpen;implicitWidth:38;glyph:'\uf08d';selected:window.queuePinned;Accessible.name:'Pin queue open';onActivated:window.queuePinned=!window.queuePinned}
            MusicButton {implicitWidth:36;glyph:'\uf16a';Accessible.name:'Find music videos';onActivated:SpotifyDesk.openVideos(false)}
            MusicButton {implicitWidth:36;glyph:'\uf080';Accessible.name:'Toggle audio spectrum';selected:SpotifyDesk.spectrumEnabled;onActivated:SpotifyDesk.spectrumEnabled=!SpotifyDesk.spectrumEnabled}
            MusicButton {implicitWidth:116;label:'Focus';glyph:'\uf186';selected:SpotifyDesk.zen;onActivated:SpotifyDesk.zen=!SpotifyDesk.zen}
            MusicButton {implicitWidth:116;label:'Backdrop';glyph:'\uf24d';selected:SpotifyDesk.musicBackdrop;onActivated:SpotifyDesk.musicBackdrop=!SpotifyDesk.musicBackdrop}
            MusicButton {visible:!SpotifyDesk.playback.ready;implicitWidth:136;implicitHeight:34;label:'Open Spotify';glyph:'\uf1bc';onActivated:SpotifyDesk.openOfficial()}
            MusicButton {implicitWidth:36;implicitHeight:34;glyph:'\uf066';Accessible.name:'Restore music widget';onActivated:SpotifyDesk.collapse(true)}
            MusicButton {implicitWidth:36;implicitHeight:34;glyph:'\uf00d';Accessible.name:'Close listening room';onActivated:SpotifyDesk.collapse(false)}
        }
        // Short displays can scroll the player without hiding its controls.
        ScrollView {id:player;visible:!SpotifyDesk.zen;x:stage.gutter;y:stage.bodyTop;width:stage.cardWidth;height:stage.bodyHeight;clip:true;contentWidth:availableWidth
            Column {width:player.availableWidth;spacing:16
                RoundedArtwork {width:parent.width;height:width;cornerRadius:14;source:SpotifyDesk.albumArt;sourceSize:Qt.size(800,800);fillMode:Image.PreserveAspectCrop;asynchronous:true
                    Rectangle {anchors.fill:parent;visible:SpotifyDesk.albumArt==='';color:Theme.surfaceOne;radius:14;Text {anchors.centerIn:parent;text:'\uf001';font.family:Appearance.font.icons;font.pixelSize:64;color:Theme.widgetMuted}}
                }
                Text {width:parent.width;text:SpotifyDesk.title;textFormat:Text.PlainText;wrapMode:Text.Wrap;maximumLineCount:3;elide:Text.ElideRight;font.family:Appearance.font.heading;font.pixelSize:26;font.weight:Font.DemiBold;color:Theme.paper}
                Text {width:parent.width;text:SpotifyDesk.artist;textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:15;color:Theme.paperMuted}
                Text {width:parent.width;text:SpotifyDesk.album;textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetMuted}
                MusicButton {width:parent.width;implicitHeight:32;glyph:'\uf025';label:SpotifyDesk.devices.find(d=>d.is_active)?.name||'Playback devices';Accessible.name:'Playback device: '+label;onActivated:{SpotifyDesk.collapse(true);SpotifyDesk.page=5;}}
                Slider {id:seek;width:parent.width;height:24;enabled:SpotifyDesk.playback.capabilities?.CanSeek??true;from:0;to:1;Binding {target:seek;property:'value';value:SpotifyDesk.positionMs/Math.max(1,SpotifyDesk.playback.track?.duration||0);when:!seek.pressed;restoreMode:Binding.RestoreNone}onMoved:SpotifyDesk.action('seek-to',[String(Math.round(value*(SpotifyDesk.playback.track?.duration||0)))]);background:Rectangle {x:seek.leftPadding;y:seek.topPadding+seek.availableHeight/2-2;width:seek.availableWidth;height:4;radius:2;color:Theme.rule;Rectangle {width:parent.width*seek.visualPosition;height:4;radius:2;color:Theme.signalRed}}handle:Rectangle {x:seek.leftPadding+seek.visualPosition*(seek.availableWidth-width);y:seek.topPadding+seek.availableHeight/2-5;width:10;height:10;radius:5;color:Theme.paper}}

                Row {width:parent.width
                    Text {width:parent.width/2;text:SpotifyDesk.fmt(SpotifyDesk.positionMs);color:Theme.paperMuted;font.family:Appearance.font.data;font.pixelSize:12}
                    Text {width:parent.width/2;text:SpotifyDesk.fmt(SpotifyDesk.playback.track?.duration||0);horizontalAlignment:Text.AlignRight;color:Theme.paperMuted;font.family:Appearance.font.data;font.pixelSize:12}
                }
                Row {spacing:10;anchors.horizontalCenter:parent.horizontalCenter
                    MusicButton {implicitWidth:62;implicitHeight:44;glyph:'\uf048';Accessible.name:'Previous track';enabled:!SpotifyDesk.trackLoading;onActivated:SpotifyDesk.action('previous')}
                    MusicButton {implicitWidth:84;implicitHeight:44;glyph:SpotifyDesk.playing?'\uf04c':'\uf04b';Accessible.name:SpotifyDesk.playing?'Pause':'Play';selected:SpotifyDesk.playing;onActivated:SpotifyDesk.action('toggle')}
                    MusicButton {implicitWidth:62;implicitHeight:44;glyph:'\uf051';Accessible.name:'Next track';enabled:!SpotifyDesk.trackLoading;onActivated:SpotifyDesk.action('next')}
                }
                Row {spacing:8;width:parent.width
                    MusicButton {implicitWidth:(parent.width-8)/2;implicitHeight:32;label:'Shuffle';glyph:'\uf074';selected:SpotifyDesk.playback.shuffle??false;onActivated:SpotifyDesk.action('shuffle')}
                    MusicButton {implicitWidth:(parent.width-8)/2;implicitHeight:32;label:'Repeat '+(SpotifyDesk.playback.repeat||'off');glyph:'\uf01e';onActivated:SpotifyDesk.action('repeat')}
                }
                MusicSpectrum {width:parent.width;height:44;visible:SpotifyDesk.spectrumEnabled}
                ControlSlider {width:parent.width;title:YouTubeDesk.ownsAudio?'YouTube volume':'Spotify volume';level:SpotifyDesk.volume;onEdited:v=>SpotifyDesk.action('volume',[String(Math.round(v))])}
            }
        }
        Rectangle {id:lyricCard;visible:!SpotifyDesk.zen;x:player.x+player.width+20;y:stage.bodyTop;width:stage.lyricWidth;height:stage.bodyHeight;radius:12;color:"transparent";border.color:"transparent"
            LyricsFollower {anchors.fill:parent;anchors.margins:16;immersive:true}
        }
        Rectangle {id:listCard;visible:!SpotifyDesk.zen&&window.collectionOpen;x:lyricCard.x+lyricCard.width+20;y:stage.bodyTop;width:stage.listWidth;height:stage.bodyHeight;radius:12;color:Theme.alpha(Theme.ink,.9);border.color:Theme.rule
            HoverHandler {id:listHover}
            Row {id:tabs;x:14;y:14;spacing:8
                MusicButton {implicitWidth:106;implicitHeight:32;label:'Queue';glyph:'\uf03a';selected:window.collection===0;onActivated:window.collection=0}
                MusicButton {implicitWidth:130;implicitHeight:32;label:'Playlists';glyph:'\uf001';selected:window.collection===1;onActivated:{window.collection=1;if(!SpotifyDesk.playlistRows.length)SpotifyDesk.dispatch('library',['playlists']);}}
                MusicButton {implicitWidth:32;implicitHeight:32;glyph:'\uf021';Accessible.name:'Refresh collection';onActivated:{if(window.collection===0)SpotifyDesk.dispatch('queue');else if(SpotifyDesk.contextItem.id)SpotifyDesk.dispatch('context',[SpotifyDesk.contextItem.kind,SpotifyDesk.contextItem.id]);else SpotifyDesk.dispatch('library',['playlists','refresh']);}}
            }
            Item {id:collectionTitle;x:14;y:58;width:parent.width-28;height:38
                Text {width:parent.width-(back.visible?80:0);anchors.verticalCenter:parent.verticalCenter;text:window.collection===0?'Up next · '+window.rows.length:SpotifyDesk.contextItem.title||'Your playlists · '+window.rows.length;textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:14;color:Theme.paperMuted}
                MusicButton {id:back;anchors.right:parent.right;visible:window.collection===1&&!!SpotifyDesk.contextItem.id;implicitWidth:76;implicitHeight:30;label:'Back';glyph:'\uf060';onActivated:SpotifyDesk.contextItem={}}
            }
            ListView {id:tracks;x:14;y:104;width:parent.width-28;height:parent.height-y-48;clip:true;spacing:6;model:window.rows;ScrollBar.vertical:ScrollBar {}
                delegate:SpotifyRow {required property var modelData;width:tracks.width;entry:modelData;onBrowseRequested:{window.collection=1;SpotifyDesk.browse(entry);}onPlayRequested:{if(window.collection===0)SpotifyDesk.play(entry,SpotifyDesk.queueRows);else SpotifyDesk.play(entry);}onQueueRequested:{if(['youtube','twitch'].includes(entry.kind))YouTubeDesk.enqueue(entry);else SpotifyDesk.action('queue-add',[entry.uri||entry.id]);}}
                Text {anchors.centerIn:parent;visible:tracks.count===0;width:parent.width-24;text:SpotifyDesk.loading?'Loading your music…':window.collection===0?'The queue is quiet. Choose a playlist to begin.':'No playlists loaded. Refresh or open Spotify to reconnect.';wrapMode:Text.Wrap;horizontalAlignment:Text.AlignHCenter;font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetMuted}
            }
            MusicButton {anchors.bottom:parent.bottom;anchors.bottomMargin:10;anchors.horizontalCenter:parent.horizontalCenter;visible:window.collection===1&&!!SpotifyDesk.contextItem.id&&!!SpotifyDesk.nextPage;implicitWidth:140;implicitHeight:30;label:'Load more tracks';enabled:!SpotifyDesk.loading;onActivated:SpotifyDesk.more()}
        }
        Row {
            visible:SpotifyDesk.zen
            anchors.centerIn:parent
            spacing:Math.max(30,stage.width*.04)
            readonly property real artSize:Math.max(160,Math.min(490,stage.height-210,stage.width*.34))
            RoundedArtwork {width:parent.artSize;height:width;cornerRadius:18;source:SpotifyDesk.albumArt;sourceSize:Qt.size(1000,1000);fillMode:Image.PreserveAspectCrop;asynchronous:true}
            Column {anchors.verticalCenter:parent.verticalCenter;width:Math.min(640,stage.width*.4);spacing:22
                Text {text:SpotifyDesk.playing?'NOW PLAYING':'PAUSED';font.family:Appearance.font.ui;font.pixelSize:12;font.letterSpacing:3;color:Theme.paperMuted}
                Text {width:parent.width;text:SpotifyDesk.title;textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:Appearance.font.heading;font.pixelSize:Math.min(48,stage.width*.03);font.weight:Font.DemiBold;color:Theme.paper}
                Text {width:parent.width;text:SpotifyDesk.artist;textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:22;color:Theme.paperMuted}
                Text {width:parent.width;text:SpotifyDesk.album;textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:14;color:Theme.widgetMuted}
                Rectangle {width:parent.width;height:2;color:Theme.alpha(Theme.paper,.12);Rectangle {height:2;width:parent.width*Math.min(1,SpotifyDesk.positionMs/Math.max(1,SpotifyDesk.playback.track?.duration||1));color:Theme.alpha(Theme.paper,.65)}}
                MusicSpectrum {width:parent.width;height:50;visible:SpotifyDesk.spectrumEnabled;accent:Theme.paperMuted}
                Text {text:SpotifyDesk.fmt(SpotifyDesk.positionMs)+' / '+SpotifyDesk.fmt(SpotifyDesk.playback.track?.duration||0);font.family:Appearance.font.data;font.pixelSize:12;color:Theme.paperMuted}
            }
        }
        Text {visible:!SpotifyDesk.zen;x:stage.gutter;y:parent.height-34;width:parent.width-2*stage.gutter;text:SpotifyDesk.error||SpotifyDesk.statusError||SpotifyDesk.warning||'Esc / F11  restore widget     ·     Space  play / pause     ·     Tab  move between controls';textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:12;color:SpotifyDesk.error||SpotifyDesk.statusError?Theme.signalRed:Theme.paperMuted}
    }
}
