import QtQuick
import QtQuick.Controls
import QtMultimedia
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.services

Column {
    id:root
    spacing:12
    property var hostWindow:null
    property string query:""
    property int section:0
    property var results:[]
    property var saved:[]
    property int nextPage:-1
    property bool appendPage:false
    property bool privateCollection:false
    readonly property var collections:['playlists','watchlater','subscriptions','channels','history']
    function openLibrary(index,more){if(searcher.running)return;if(!more){section=index;results=[];nextPage=-1;}appendPage=!!more;searcher.command=['@HOME@/.local/bin/sensei-spotify','youtube-library',collections[index-3],String(more?nextPage:0)];searcher.running=true;}
    function activate(item,watch){if(item.kind==='twitch'){YouTubeDesk.watch(item);return;}if(item.kind!=='youtube'){query=item.url;privateCollection=!!item.private;root.search(false,false);return;}if(watch)YouTubeDesk.watch(item);else YouTubeDesk.play(item);}

    property string notice:"Search videos, music and lectures, or paste a public playlist."
    readonly property var rows:section===1?saved:section===2?YouTubeDesk.queue:results
    readonly property bool watching:YouTubeDesk.platform==='YouTube'&&SpotifyDesk.videoAudioLinked&&SpotifyDesk.videoSource!==''
    IpcHandler {enabled:root.visible&&!!root.hostWindow?.visible&&ShellState.dropdownOriginScreen===root.hostWindow?.screen?.name;target:'youtube-panel';function search(text:string):void{root.query=text;root.search(false);}function state():string{return JSON.stringify({results:root.results.length,saved:root.saved.length,queue:YouTubeDesk.queue.length,loading:searcher.running,watching:root.watching,notice:root.notice});}}
    function search(refresh,more){if(searcher.running||query.trim().length<2)return;section=0;appendPage=!!more;if(!more){results=[];nextPage=-1;}searcher.command=['@HOME@/.local/bin/sensei-spotify','youtube-search',query].concat(refresh?['refresh']:[]).concat(privateCollection?['private']:[]).concat(more?['offset='+nextPage]:[]);searcher.running=true;}
    function attachVideo(){
        if(!visible||!root.watching||SpotifyDesk.videoMode!=='youtube'||!hostWindow)return;
        const point=video.mapToItem(null,0,0),top=hostWindow.contentOriginY;
        const slot={x:Math.round(hostWindow.margins.left+point.x),y:Math.round(top+point.y),width:Math.round(video.width),height:Math.round(video.height),output:hostWindow.screen.name,track:YouTubeDesk.track.id};
        if(JSON.stringify(SpotifyDesk.videoSlot)!==JSON.stringify(slot))SpotifyDesk.videoSlot=slot;
    }
    Timer {interval:200;repeat:true;running:root.visible&&root.watching&&SpotifyDesk.videoMode==='youtube';onTriggered:root.attachVideo()}

    onVisibleChanged:attachVideo()
    Connections {target:SpotifyDesk;function onVideoModeChanged(){root.attachVideo();}function onVideoSourceChanged(){root.attachVideo();}}
    FileView {id:library;path:'@HOME@/.local/share/sensei-spotify/youtube-library.json';watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.saved=JSON.parse(text()).rows||[];}catch(e){root.saved=[];}}}
    Process {id:searcher;stdout:StdioCollector {onStreamFinished:{try{const d=JSON.parse(text);if(!d.error)root.results=root.appendPage?root.results.concat(d.rows||[]):d.rows||[];root.nextPage=d.next??-1;root.appendPage=false;root.notice=d.error||d.warning||'';}catch(e){root.notice='YouTube could not be reached. Saved items are still available.';}}}}
    Row {visible:!root.watching;width:parent.width;spacing:8
        Text {width:parent.width-300;text:'YouTube / the den media center';font.family:Appearance.font.heading;font.pixelSize:19;color:Theme.paper;elide:Text.ElideRight;anchors.verticalCenter:parent.verticalCenter}
        MusicButton {implicitWidth:170;implicitHeight:32;label:'Listening room';glyph:'\uf065';enabled:YouTubeDesk.ownsAudio;onActivated:SpotifyDesk.expand()}
        MusicButton {implicitWidth:122;implicitHeight:32;label:'Spotify';glyph:'\uf1bc';enabled:YouTubeDesk.ownsAudio;onActivated:{YouTubeDesk.release();SpotifyDesk.action('play');}}
    }
    MediaTransport {width:parent.width}
    Row {width:parent.width;spacing:8
        DeskTextField {width:parent.width-116;height:38;placeholderText:'Videos, music, robotics, lectures or a YouTube link…';text:root.query;onTextEdited:{root.query=text;root.privateCollection=false;}onAccepted:root.search(false)}
        MusicButton {implicitWidth:108;implicitHeight:38;label:'Search';enabled:!searcher.running&&root.query.trim().length>=2;onActivated:root.search(false)}
    }
    Row {spacing:8
        Repeater {model:['Results','Saved','Queue','My playlists','Watch Later','Subscriptions','Channels','History'];MusicButton {required property string modelData;required property int index;implicitWidth:Math.max(92,modelData.length*8+26);implicitHeight:30;textSize:12;glyph:'';label:modelData;selected:root.section===index;onActivated:{if(index>=3)root.openLibrary(index,false);else root.section=index;}}}
        MusicButton {implicitWidth:34;implicitHeight:30;glyph:'\uf021';Accessible.name:'Refresh YouTube results';enabled:!searcher.running;onActivated:{if(root.section>=3)root.openLibrary(root.section,false);else root.search(true);}}
    }
    Text {visible:!root.watching||searcher.running||!!YouTubeDesk.error;width:parent.width;text:YouTubeDesk.error||(YouTubeDesk.loading?'Preparing media · current playback stays until ready.':searcher.running?'Searching YouTube…':root.notice);wrapMode:Text.Wrap;maximumLineCount:2;elide:Text.ElideRight;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:YouTubeDesk.error?Theme.widgetAccent:Theme.paperMuted}
    MusicButton {visible:root.nextPage>=0&&(root.section===0||root.section>=3);implicitWidth:180;implicitHeight:30;label:'Load more from YouTube';enabled:!searcher.running;onActivated:{if(root.section>=3)root.openLibrary(root.section,true);else root.search(false,true);}}
    Row {
        id:body
        width:parent.width;height:Math.max(200,root.height-y-28);spacing:16
        Column {
            id:videoColumn
            visible:root.watching
            width:visible?Math.min(body.width*.74,Math.max(240,body.height-82)*16/9):0;height:body.height;spacing:10
            Rectangle {
                width:parent.width;height:width*9/16;color:Theme.ink;radius:8
                Item {id:video;anchors.fill:parent;visible:SpotifyDesk.videoMode==='youtube';MediaCaptions {}}

                Text {anchors.centerIn:parent;width:parent.width-40;visible:SpotifyDesk.videoMode!=='youtube';text:SpotifyDesk.videoMode==='mini'?'Video is in your always-on-top mini-player.':'Video is fullscreen on '+SpotifyDesk.videoDisplay;wrapMode:Text.Wrap;horizontalAlignment:Text.AlignHCenter;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.title;color:Theme.paperMuted}
            }
            Row {width:parent.width;spacing:8
                MusicButton {implicitWidth:42;implicitHeight:34;glyph:YouTubeDesk.playing?'\uf04c':'\uf04b';Accessible.name:'Play or pause video and audio';onActivated:YouTubeDesk.action('toggle')}
                MusicButton {implicitWidth:156;implicitHeight:34;label:'Mini-player';glyph:'\uf24d';onActivated:SpotifyDesk.showVideo('mini')}
                MusicButton {implicitWidth:34;implicitHeight:34;glyph:'\uf20a';Accessible.name:'Toggle captions';selected:YouTubeDesk.captionsEnabled;onActivated:{YouTubeDesk.captionsEnabled=!YouTubeDesk.captionsEnabled;if(YouTubeDesk.captionsEnabled&&!YouTubeDesk.transcript.length)YouTubeDesk.loadTranscript();}}
                MusicButton {implicitWidth:34;implicitHeight:34;glyph:'\uf15c';Accessible.name:'Open transcript';selected:YouTubeDesk.transcriptOpen;onActivated:{YouTubeDesk.transcriptOpen=!YouTubeDesk.transcriptOpen;if(YouTubeDesk.transcriptOpen&&!YouTubeDesk.transcript.length)YouTubeDesk.loadTranscript();}}
                MusicButton {implicitWidth:148;implicitHeight:34;label:'Fullscreen';glyph:'\uf065';onActivated:SpotifyDesk.showVideo('fullscreen')}
                MusicButton {visible:SpotifyDesk.videoMode!=='youtube';implicitWidth:156;implicitHeight:34;label:'Restore here';onActivated:SpotifyDesk.showVideo('youtube',root.hostWindow?.screen?.name)}
                ControlSlider {width:Math.max(140,parent.width-(SpotifyDesk.videoMode!=='youtube'?644:480));title:'Volume';level:YouTubeDesk.volume;onEdited:v=>YouTubeDesk.action('volume',[String(Math.round(v))])}
            }
            Row {width:parent.width;spacing:8
                DeskComboBox {width:100;height:28;model:['0.5×','0.75×','1×','1.25×','1.5×','1.75×','2×'];currentIndex:[.5,.75,1,1.25,1.5,1.75,2].indexOf(YouTubeDesk.speed);onActivated:YouTubeDesk.speed=[.5,.75,1,1.25,1.5,1.75,2][currentIndex];Accessible.name:'Playback speed'}
                DeskComboBox {width:100;height:28;model:['360p','480p','720p','1080p'];currentIndex:[360,480,720,1080].indexOf(YouTubeDesk.quality);onActivated:YouTubeDesk.changeQuality([360,480,720,1080][currentIndex]);Accessible.name:'Video quality · reloads at current position'}
                DeskComboBox {visible:YouTubeDesk.chapters.length>0;width:Math.max(120,parent.width-216);height:28;model:YouTubeDesk.chapters.map(c=>c.title);onActivated:YouTubeDesk.action('seek-to',[String(YouTubeDesk.chapters[currentIndex].time)]);Accessible.name:'Video chapters'}
            }
            Slider {visible:false;width:parent.width;height:22;from:0;to:Math.max(1,YouTubeDesk.duration);value:YouTubeDesk.position;onMoved:YouTubeDesk.action('seek-to',[String(Math.round(value))])}
            Text {visible:false;width:parent.width;text:YouTubeDesk.track.title+' · '+SpotifyDesk.fmt(YouTubeDesk.position)+' / '+SpotifyDesk.fmt(YouTubeDesk.duration);textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.paper}
        }
        GridView {
            id:grid
            visible:!videoColumn.visible||!YouTubeDesk.transcriptOpen;width:body.width-(videoColumn.visible?videoColumn.width+16:0)-(YouTubeDesk.transcriptOpen?body.width*.4+16:0);height:body.height;clip:true;model:root.rows
            cellWidth:videoColumn.visible?width:width/Math.max(1,Math.floor(width/260))
            cellHeight:videoColumn.visible?140:cellWidth+92
            reuseItems:true;cacheBuffer:200
            ScrollBar.vertical:DeskScrollBar {}
            delegate:ChamferPanel {
                id:resultCard
                required property var modelData
                width:grid.cellWidth-10;height:grid.cellHeight-10;fillColor:Theme.surfaceOne;borderColor:YouTubeDesk.track.id===modelData.id&&YouTubeDesk.ownsAudio?Theme.widgetAccent:Theme.rule;chamfer:6;scanlines:false
                readonly property bool compact:videoColumn.visible
                RoundedArtwork {id:thumbnail;x:10;y:10;width:resultCard.compact?88:parent.width-20;height:width;cornerRadius:5;source:modelData.art;asynchronous:true;fillMode:Image.PreserveAspectCrop;MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:root.activate(modelData,true)}}
                Text {x:resultCard.compact?110:10;y:resultCard.compact?10:thumbnail.y+thumbnail.height+8;width:parent.width-x-10;text:modelData.title;textFormat:Text.PlainText;elide:Text.ElideRight;maximumLineCount:2;wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.paper}
                Text {x:resultCard.compact?110:10;y:resultCard.compact?50:thumbnail.y+thumbnail.height+44;width:parent.width-x-10;text:modelData.artist+(modelData.duration?' · '+SpotifyDesk.fmt(modelData.duration):'');textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
                Row {anchors.right:parent.right;anchors.bottom:parent.bottom;anchors.margins:8;spacing:6
                    MusicButton {visible:root.section===2;implicitWidth:32;implicitHeight:28;glyph:'\uf062';Accessible.name:'Move earlier in queue';onActivated:YouTubeDesk.moveQueued(modelData,-1)}
                    MusicButton {visible:root.section===2;implicitWidth:32;implicitHeight:28;glyph:'\uf063';Accessible.name:'Move later in queue';onActivated:YouTubeDesk.moveQueued(modelData,1)}
                    MusicButton {implicitWidth:32;implicitHeight:28;glyph:root.section===2?'\uf00d':'\uf067';Accessible.name:root.section===2?'Remove from queue':'Add to queue';enabled:modelData.kind==='youtube';onActivated:{if(root.section===2)YouTubeDesk.removeQueued(modelData);else YouTubeDesk.enqueue(modelData);}}
                    MusicButton {implicitWidth:32;implicitHeight:28;glyph:root.section===1?'\uf00d':'\uf02e';Accessible.name:root.section===1?'Remove saved item':'Save item';enabled:modelData.kind==='youtube';onActivated:SpotifyDesk.action(root.section===1?'youtube-remove':'youtube-save',[root.section===1?modelData.id:JSON.stringify(modelData)])}
                    MusicButton {implicitWidth:32;implicitHeight:28;glyph:'\uf025';Accessible.name:'Listen without video';enabled:!YouTubeDesk.loading;onActivated:root.activate(modelData,false)}
                    MusicButton {implicitWidth:32;implicitHeight:28;glyph:modelData.kind==='youtube'?'\uf04b':'\uf07c';Accessible.name:modelData.kind==='youtube'?'Watch video with sound':'Open collection';enabled:!YouTubeDesk.loading;onActivated:root.activate(modelData,true)}
                }
            }
            Text {visible:!root.rows.length;anchors.centerIn:parent;width:parent.width-30;text:root.section===1?'Save videos and music here for another day.':root.section===2?'Use + to build a queue.':'Your den has room for music, robotics and the next rabbit hole.';wrapMode:Text.Wrap;horizontalAlignment:Text.AlignHCenter;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.section;color:Theme.paperMuted}
        }
        MediaTranscript {visible:YouTubeDesk.transcriptOpen;width:videoColumn.visible?body.width-videoColumn.width-16:body.width*.4-16;height:body.height}
    }
}
