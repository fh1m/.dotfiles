import QtQuick
import QtQuick.Controls
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

// Fixed output surface: same-output presentation reuses the player;
// cross-output handoff stops the old engine before restoring the destination.
PanelWindow {
    id:window
    readonly property bool inlineVideo:SpotifyDesk.videoMode==='youtube'&&SpotifyDesk.videoAudioLinked
    readonly property var slot:SpotifyDesk.videoSlot
    Component.onCompleted:{let copy=Object.assign({},SpotifyDesk.videoWindows);copy[output?.name]=window;SpotifyDesk.videoWindows=copy;}
    Component.onDestruction:{if(YouTubeDesk.engines[output?.name]===engineLoader.item)YouTubeDesk.forgetEngine(output?.name);if(SpotifyDesk.videoWindows[output?.name]===window){let copy=Object.assign({},SpotifyDesk.videoWindows);delete copy[output?.name];SpotifyDesk.videoWindows=copy;}}
    Loader {id:engineLoader;active:YouTubeDesk.usedDisplays.includes(window.output?.name);source:'../../services/MpvEngine.qml';onStatusChanged:if(status===Loader.Error&&window.output?.name===YouTubeDesk.engineOutput)YouTubeDesk.error='Native media module unavailable: run scripts/build-media-qml.sh.';onLoaded:{item.parent=video;item.width=Qt.binding(()=>video.width);item.height=Qt.binding(()=>video.height);YouTubeDesk.registerEngine(window.output?.name,item);}}
    readonly property bool full:SpotifyDesk.videoMode==='fullscreen'
    required property var modelData
    readonly property var output:modelData
    screen:output
    visible:window.output?.name===(SpotifyDesk.videoAudioLinked?YouTubeDesk.engineOutput:SpotifyDesk.videoWindowOutput)&&SpotifyDesk.videoSource!==''&&!ShellState.locked&&!!output&&(window.inlineVideo?(ShellState.dropdown==='spotify'&&SpotifyDesk.page===(YouTubeDesk.platform==='Twitch'?8:7)&&window.slot.track===YouTubeDesk.track.id&&window.slot.width>1):['mini','fullscreen'].includes(SpotifyDesk.videoMode))
    anchors {left:true;top:true;right:window.full;bottom:window.full}
    margins {left:window.inlineVideo?(window.slot.x||0):window.full?0:Math.max(0,Math.min(SpotifyDesk.videoX,(window.output?.width||1920)-window.width));top:window.inlineVideo?(window.slot.y||0):window.full?0:Math.max(0,Math.min(SpotifyDesk.videoY,(window.output?.height||1080)-window.height))}
    implicitWidth:window.inlineVideo?(window.slot.width||1):Math.min(680,(output?.width||1920)-32,Math.max(240,((output?.height||1080)-186)*16/9))
    implicitHeight:window.inlineVideo?(window.slot.height||1):window.implicitWidth*9/16+106
    exclusionMode:ExclusionMode.Ignore
    WlrLayershell.layer:WlrLayer.Overlay
    WlrLayershell.namespace:'sensei-music-video'
    WlrLayershell.keyboardFocus:visible&&!inlineVideo?WlrKeyboardFocus.OnDemand:WlrKeyboardFocus.None
    color:Theme.ink
    onVisibleChanged:{if(visible)attachDelay.restart();else if(SpotifyDesk.videoOutput===preview)SpotifyDesk.videoOutput=null;}
    onScreenChanged:if(visible)attachDelay.restart()
    Timer {id:attachDelay;interval:80;onTriggered:if(window.visible&&!SpotifyDesk.videoAudioLinked)SpotifyDesk.attachVideo(preview)}
    Connections {target:SpotifyDesk;function onVideoModeChanged(){if(window.visible)attachDelay.restart();}function onVideoAudioLinkedChanged(){if(window.visible)attachDelay.restart();}}
    function describe(){return JSON.stringify({visible:window.visible,mode:SpotifyDesk.videoMode,display:window.screen?.name,position:SpotifyDesk.videoPlayer.position,playing:SpotifyDesk.videoPlayer.playing,inline:window.inlineVideo,geometry:{x:window.margins.left,y:window.margins.top,width:window.width,height:window.height},size:String(SpotifyDesk.videoAudioLinked?YouTubeDesk.nativePlayer.videoSize:'preview'),renderUpdates:YouTubeDesk.nativePlayer.frameNumber||0,avsync:YouTubeDesk.nativePlayer.avsync||0,playingOutputs:Object.entries(YouTubeDesk.engines).filter(e=>e[1]?.playing).map(e=>e[0])});}
    Shortcut {sequence:'Escape';enabled:window.visible;onActivated:SpotifyDesk.showVideo('inline')}
    Rectangle {anchors.fill:parent;color:Theme.ink;border.width:window.full?0:1;border.color:Theme.rule;radius:window.full?0:8}
    Item {id:video;z:0;anchors.fill:parent;anchors.margins:window.full?0:1;anchors.topMargin:window.inlineVideo?0:54;anchors.bottomMargin:window.inlineVideo?0:52;VideoOutput {id:preview;anchors.fill:parent;visible:!SpotifyDesk.videoAudioLinked;fillMode:VideoOutput.PreserveAspectFit}
        MediaCaptions {z:10}}
    Item {anchors.fill:parent;focus:window.visible&&!window.inlineVideo
        Keys.onPressed:event=>{
            if(event.key===Qt.Key_Escape){SpotifyDesk.showVideo('inline');event.accepted=true;}
            else if(event.key===Qt.Key_Space||event.key===Qt.Key_K){SpotifyDesk.toggleVideo();event.accepted=true;}
            else if(event.key===Qt.Key_F){SpotifyDesk.showVideo(window.full?'mini':'fullscreen');event.accepted=true;}
            else if(SpotifyDesk.videoAudioLinked&&(event.key===Qt.Key_Left||event.key===Qt.Key_Right)){YouTubeDesk.action('seek-to',[String(YouTubeDesk.position+(event.key===Qt.Key_Right?10000:-10000))]);event.accepted=true;}
        }
    }
    Row {z:100;visible:!window.inlineVideo;x:12;anchors.bottom:parent.bottom;anchors.bottomMargin:8;width:parent.width-24;height:34;spacing:10
        MusicButton {implicitWidth:28;implicitHeight:32;glyph:"\uf048";Accessible.name:"Previous video";enabled:SpotifyDesk.videoAudioLinked;onActivated:YouTubeDesk.action("previous")}
        MusicButton {implicitWidth:32;implicitHeight:32;glyph:SpotifyDesk.videoPlayer.playing?"\uf04c":"\uf04b";Accessible.name:"Play or pause";onActivated:SpotifyDesk.toggleVideo()}
        MusicButton {implicitWidth:28;implicitHeight:32;glyph:"\uf051";Accessible.name:"Next video";enabled:SpotifyDesk.videoAudioLinked&&YouTubeDesk.index+1<YouTubeDesk.queue.length;onActivated:YouTubeDesk.action("next")}
        Text {width:50;anchors.verticalCenter:parent.verticalCenter;text:YouTubeDesk.track.live?'LIVE':SpotifyDesk.fmt(SpotifyDesk.videoPlayer.position);font.family:Appearance.font.data;font.pixelSize:12;color:Theme.paperMuted}
        Slider {width:Math.max(70,parent.width-424);height:34;enabled:!YouTubeDesk.track.live;from:0;to:Math.max(1,SpotifyDesk.videoPlayer.duration);value:SpotifyDesk.videoPlayer.position;onMoved:{if(SpotifyDesk.videoAudioLinked)YouTubeDesk.action('seek-to',[String(Math.round(value))]);else SpotifyDesk.videoPlayer.position=Math.round(value);}}
        ControlSlider {width:150;title:SpotifyDesk.videoAudioLinked?'Volume':'Silent preview';level:SpotifyDesk.videoAudioLinked?YouTubeDesk.volume:0;enabled:SpotifyDesk.videoAudioLinked;onEdited:v=>YouTubeDesk.action('volume',[String(Math.round(v))])}
    }
    Item {id:header;z:100;visible:!window.inlineVideo;x:12;y:8;width:parent.width-24;height:38
        property real startX:0
        property real startY:0
        Text {id:heading;width:parent.width-330;anchors.verticalCenter:parent.verticalCenter;text:SpotifyDesk.videoTitle;textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paper
            DragHandler {target:null;enabled:!window.full;onActiveChanged:if(active){header.startX=SpotifyDesk.videoX;header.startY=SpotifyDesk.videoY;}onActiveTranslationChanged:{SpotifyDesk.videoX=Math.max(0,Math.min(header.startX+activeTranslation.x,(window.output?.width||1920)-window.width));SpotifyDesk.videoY=Math.max(0,Math.min(header.startY+activeTranslation.y,(window.output?.height||1080)-window.height));}}
        }
        Row {anchors.right:parent.right;spacing:7
            DeskComboBox {width:158;height:34;model:ShellState.screens.map(s=>MachineProfile.role(s.name)+' · '+s.name);currentIndex:ShellState.screens.findIndex(s=>s.name===window.screen?.name);onActivated:{SpotifyDesk.videoDisplay=ShellState.screens[currentIndex].name;SpotifyDesk.videoX=48;SpotifyDesk.videoY=80;}Accessible.name:'Video display'}
            MusicButton {implicitWidth:32;implicitHeight:34;glyph:SpotifyDesk.videoPlayer.playing?'\uf04c':'\uf04b';Accessible.name:'Pause or resume video';onActivated:SpotifyDesk.toggleVideo()}
            MusicButton {implicitWidth:32;implicitHeight:34;glyph:'\uf066';Accessible.name:'Return video inside music widget';onActivated:SpotifyDesk.showVideo('inline')}
            MusicButton {implicitWidth:32;implicitHeight:34;glyph:window.full?'\uf24d':'\uf065';Accessible.name:window.full?'Video mini-player':'Fullscreen video';onActivated:SpotifyDesk.showVideo(window.full?'mini':'fullscreen')}
            MusicButton {implicitWidth:32;implicitHeight:34;glyph:'\uf00d';Accessible.name:'Close video';onActivated:SpotifyDesk.closeVideo()}
        }
    }
}
