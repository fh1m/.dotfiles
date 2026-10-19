import QtQuick
import Quickshell.Io
import QtMultimedia
import QtQuick.Controls
import qs.config
import qs.components
import qs.services

Popup {
    id:root
    IpcHandler {enabled:root.visible;target:root.fullscreenHost?'music-video-fullscreen':'music-video-widget';function state():string{return JSON.stringify({playing:player.playing,position:player.position,duration:player.duration,mediaStatus:player.mediaStatus,buffer:player.bufferProgress,seekable:player.seekable,videoSize:String(video.videoSink.videoSize),hasVideo:player.hasVideo,error:SpotifyDesk.videoPreviewError,sourceActive:SpotifyDesk.videoSource!=="",width:root.width,height:root.height});}}
    property bool fullscreenHost:false
    property bool showVideo:SpotifyDesk.videoSource!==""||SpotifyDesk.videoPreviewLoading||SpotifyDesk.videoPreviewError!==""
    width:Math.min(720,parent?.width-32||720)
    height:Math.min(showVideo?730:510,parent?.height-32||730)
    x:(parent.width-width)/2
    y:(parent.height-height)/2
    visible:SpotifyDesk.videosOpen&&fullscreenHost===SpotifyDesk.fullscreen
    onClosed:if(fullscreenHost===SpotifyDesk.fullscreen)SpotifyDesk.videosOpen=false
    modal:true;focus:true;padding:18
    closePolicy:Popup.CloseOnEscape|Popup.CloseOnPressOutside
    background:ChamferPanel {fillColor:Theme.ink;borderColor:Theme.rule;borderWidth:1;chamfer:Theme.radiusPanel;scanlines:false}
    contentItem:Column {
        spacing:12
        Row {width:parent.width;spacing:8
            Text {width:parent.width-42;text:'Music videos';font.family:Appearance.font.heading;font.pixelSize:19;color:Theme.paper}
            MusicButton {implicitWidth:32;implicitHeight:28;glyph:'\uf00d';Accessible.name:'Close video search';onActivated:root.close()}
        }
        Text {width:parent.width;text:SpotifyDesk.title+' · '+SpotifyDesk.artist;textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paperMuted}
        Row {spacing:8
            MusicButton {implicitWidth:138;implicitHeight:30;label:'YouTube';glyph:'\uf16a';onActivated:SpotifyDesk.action('video-browser',[JSON.stringify(SpotifyDesk.lyricTrack())])}
            MusicButton {implicitWidth:96;implicitHeight:30;label:'Refresh';glyph:'\uf021';enabled:!SpotifyDesk.videosLoading;onActivated:SpotifyDesk.openVideos(true)}
        }
        Rectangle {
            visible:root.showVideo;width:parent.width;height:visible?Math.min(300,root.height*.4):0;color:Theme.ink;radius:8
            VideoOutput {id:video;anchors.fill:parent;fillMode:VideoOutput.PreserveAspectFit}
            Text {anchors.top:parent.top;anchors.left:parent.left;anchors.margins:8;width:parent.width-16;text:SpotifyDesk.videoTitle;textFormat:Text.PlainText;elide:Text.ElideRight;color:Theme.paper;font.family:Appearance.font.ui;font.pixelSize:11;visible:SpotifyDesk.videoSource!=="";style:Text.Outline;styleColor:Theme.ink}
            Timer {interval:15000;running:root.visible&&SpotifyDesk.videoSource!==""&&player.position===0;onTriggered:{SpotifyDesk.videoSource="";SpotifyDesk.videoPreviewError='Video did not start. Try another candidate or YouTube.';}}
            MediaPlayer {id:player;source:root.visible?SpotifyDesk.videoSource:"";autoPlay:true;videoOutput:video;audioOutput:AudioOutput {muted:true}
                onErrorOccurred:(error,message)=>{SpotifyDesk.videoPreviewError='Video could not play. Try another candidate or YouTube.';SpotifyDesk.videoSource="";}
            }
            Text {anchors.centerIn:parent;width:parent.width-30;text:SpotifyDesk.videoPreviewLoading?'Preparing silent preview…':SpotifyDesk.videoPreviewError;textFormat:Text.PlainText;wrapMode:Text.Wrap;horizontalAlignment:Text.AlignHCenter;color:Theme.paperMuted;font.family:Appearance.font.ui;font.pixelSize:12;visible:!SpotifyDesk.videoSource}
            Row {anchors.right:parent.right;anchors.bottom:parent.bottom;anchors.margins:8;spacing:6;visible:SpotifyDesk.videoSource!==""
                MusicButton {implicitWidth:36;implicitHeight:28;glyph:player.playing?'\uf04c':'\uf04b';Accessible.name:'Pause or resume silent video';onActivated:player.playing?player.pause():player.play()}
                MusicButton {implicitWidth:36;implicitHeight:28;glyph:'\uf08e';Accessible.name:'Pop out silent video';onActivated:SpotifyDesk.action('video-play',[SpotifyDesk.videoId])}
                MusicButton {implicitWidth:36;implicitHeight:28;glyph:'\uf00d';Accessible.name:'Close video preview';onActivated:SpotifyDesk.videoSource=""}
            }
        }
        ListView {
            width:parent.width;height:Math.max(70,root.availableHeight-145-(root.showVideo?Math.min(300,root.height*.4)+12:0));clip:true;spacing:8
            model:SpotifyDesk.videoData.rows||[]
            ScrollBar.vertical:DeskScrollBar {}
            delegate:ChamferPanel {
                required property var modelData
                width:ListView.view.width;height:64;fillColor:Theme.surfaceOne;borderColor:Theme.rule;chamfer:6;scanlines:false
                Column {x:10;y:10;width:parent.width-140;spacing:7
                    Text {width:parent.width;text:modelData.title;textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paper}
                    Text {width:parent.width;text:modelData.channel+(modelData.duration?' · '+SpotifyDesk.fmt(modelData.duration*1000):'');textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:10;color:Theme.paperMuted}
                }
                MusicButton {anchors.right:parent.right;anchors.rightMargin:10;anchors.verticalCenter:parent.verticalCenter;implicitWidth:112;implicitHeight:30;label:'Preview';glyph:'\uf04b';enabled:!SpotifyDesk.videoPreviewLoading;onActivated:SpotifyDesk.previewVideo(modelData.id)}
            }
            Text {visible:!(SpotifyDesk.videoData.rows||[]).length;anchors.centerIn:parent;width:parent.width-20;text:SpotifyDesk.videosLoading?'Finding music videos…':'Use YouTube search if no candidates are available.';wrapMode:Text.Wrap;horizontalAlignment:Text.AlignHCenter;font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.paperMuted}
        }
        Text {width:parent.width;text:SpotifyDesk.videoData.warning||'Silent previews keep Spotify as the soundtrack. Recordings may have different timing.';wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.paperMuted}
    }
}
