import QtQuick
import QtQuick.Controls
import qs.components
import qs.config
import qs.services

ChamferPanel {height:64;fillColor:Theme.surfaceOne;borderColor:Theme.rule;chamfer:6;scanlines:false
        Row {anchors.fill:parent;anchors.margins:10;spacing:10
            RoundedArtwork {width:44;height:44;cornerRadius:5;source:SpotifyDesk.albumArt;asynchronous:true;fillMode:Image.PreserveAspectCrop}
            Column {width:Math.max(100,parent.width-progress.width-684);anchors.verticalCenter:parent.verticalCenter;spacing:5
                Text {width:parent.width;text:SpotifyDesk.title;textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.paper}
                Text {width:parent.width;text:SpotifyDesk.artist+' · '+(YouTubeDesk.ownsAudio?YouTubeDesk.platform.toUpperCase():'SPOTIFY');textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.caption;color:Theme.paperMuted}
            }
            MusicButton {implicitWidth:38;implicitHeight:38;glyph:'\uf048';Accessible.name:'Previous';enabled:!SpotifyDesk.trackLoading;onActivated:SpotifyDesk.action('previous')}
            MusicButton {implicitWidth:48;implicitHeight:38;glyph:SpotifyDesk.playing?'\uf04c':'\uf04b';Accessible.name:SpotifyDesk.playing?'Pause':'Play';selected:SpotifyDesk.playing;onActivated:SpotifyDesk.action('toggle')}
            MusicButton {implicitWidth:38;implicitHeight:38;glyph:'\uf051';Accessible.name:'Next';enabled:!SpotifyDesk.trackLoading;onActivated:SpotifyDesk.action('next')}
            Slider {id:progress;visible:!YouTubeDesk.ownsAudio||!YouTubeDesk.track.live;width:Math.max(120,parent.width*.22);enabled:!YouTubeDesk.ownsAudio||!YouTubeDesk.track.live;height:38;from:0;to:Math.max(1,SpotifyDesk.playback.track?.duration||0);value:SpotifyDesk.positionMs;onMoved:SpotifyDesk.action('seek-to',[String(Math.round(value))])}
            Text {visible:YouTubeDesk.ownsAudio&&!!YouTubeDesk.track.live;width:progress.width;anchors.verticalCenter:parent.verticalCenter;text:'● LIVE';font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetAccent;horizontalAlignment:Text.AlignHCenter}
            Text {anchors.verticalCenter:parent.verticalCenter;text:SpotifyDesk.fmt(SpotifyDesk.positionMs);font.family:Appearance.font.data;font.pixelSize:11;color:Theme.paperMuted}
            MusicButton {implicitWidth:32;implicitHeight:32;glyph:'\uf074';Accessible.name:'Shuffle';selected:SpotifyDesk.playback.shuffle===true;onActivated:SpotifyDesk.action('shuffle')}
            MusicButton {implicitWidth:32;implicitHeight:32;glyph:'\uf01e';Accessible.name:'Repeat: '+(SpotifyDesk.playback.repeat||'off');selected:(SpotifyDesk.playback.repeat||'off')!=='off';onActivated:SpotifyDesk.action('repeat')}
            ControlSlider {width:200;title:'Volume';level:SpotifyDesk.volume;onEdited:v=>SpotifyDesk.action('volume',[String(Math.round(v))])}
        }
    }
