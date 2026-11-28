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
    property string query:''
    property int section:0
    property bool useAccount:false
    property var rows:[]
    // Only the newest tab/search may publish rows or change its status line.
    property int requestSerial:0
    property var activeRequest:null
    property var pendingRequest:null
    property int bookmarkSerial:0
    property bool bookmarkChanged:false
    property string notice:'Live channels, followed creators and recordings. Nothing starts automatically.'
    readonly property bool watching:SpotifyDesk.videoAudioLinked&&YouTubeDesk.platform==='Twitch'&&SpotifyDesk.videoSource!==''
    function browse(section){
        if(!Number.isInteger(section)||section<0||section>4)return;
        const term=section===2?query.trim():'';
        root.section=section;
        rows=[];
        notice='';
        ++requestSerial;
        if(section===2&&!term.length){pendingRequest=null;return;}
        const command=['@HOME@/.local/bin/sensei-spotify'].concat(section===4?['twitch-account']:section===3?['twitch-saved']:['twitch-browse',section===1?'following':section===2?'search':'discover',term]);
        pendingRequest={serial:requestSerial,command:command};
        pumpBrowse();
    }
    function pumpBrowse(){
        if(fetch.running||!pendingRequest)return;
        activeRequest=pendingRequest;
        pendingRequest=null;
        fetch.command=activeRequest.command;
        fetch.running=true;
    }
    function setBookmark(row){
        if(bookmark.running||!row||!rows.includes(row))return;
        bookmarkSerial=requestSerial;
        bookmarkChanged=false;
        const remove=root.section===3;
        bookmark.command=['@HOME@/.local/bin/sensei-spotify',remove?'twitch-remove':'twitch-save',remove?row.id:JSON.stringify(row)];
        bookmark.running=true;
    }
    function attach(){
        if(!visible||!root.watching||SpotifyDesk.videoMode!=='youtube'||!hostWindow)return;
        const point=video.mapToItem(null,0,0),top=hostWindow.contentOriginY;
        const slot={x:Math.round(hostWindow.margins.left+point.x),y:Math.round(top+point.y),width:Math.round(video.width),height:Math.round(video.height),output:hostWindow.screen.name,track:YouTubeDesk.track.id};
        if(JSON.stringify(SpotifyDesk.videoSlot)!==JSON.stringify(slot))SpotifyDesk.videoSlot=slot;
    }
    Timer {interval:200;repeat:true;running:root.visible&&root.watching&&SpotifyDesk.videoMode==='youtube';onTriggered:root.attach()}

    onVisibleChanged:if(visible){attach();if(!rows.length&&!fetch.running&&section!==2)browse(section);}
    Connections {target:SpotifyDesk;function onVideoModeChanged(){root.attach();}function onVideoSourceChanged(){root.attach();}}
    IpcHandler {enabled:root.visible&&!!root.hostWindow?.visible&&ShellState.dropdownOriginScreen===root.hostWindow?.screen?.name;target:'twitch-panel';function browse(section:int):void{root.browse(section);}function search(query:string):void{root.query=query;root.browse(2);}function state():string{return JSON.stringify({rows:root.rows.length,notice:root.notice,watching:root.watching,loading:fetch.running});}}
    Process {
        id:fetch
        stdout:StdioCollector {onStreamFinished:{
            if(root.activeRequest?.serial!==root.requestSerial)return;
            try{
                const d=JSON.parse(text);
                if(!d.error)root.rows=d.rows||[];
                root.notice=(d.login?'Signed in as '+d.login+' · ':'')+(d.error||d.warning||'');
            }catch(e){root.notice='Twitch is unavailable. Your current playback is unchanged.';}
        }}
        onExited:Qt.callLater(root.pumpBrowse)
    }
    Process {
        id:bookmark
        stdout:StdioCollector {onStreamFinished:{
            let message='Could not update the bookmark.';
            try{
                const d=JSON.parse(text);
                root.bookmarkChanged=!d.error;
                message=d.error||(root.section===3?'Removed from Saved.':'Saved locally.');
            }catch(e){}
            if(root.bookmarkSerial===root.requestSerial)root.notice=message;
        }}
        onExited:if(root.bookmarkChanged&&root.section===3)root.browse(3)
    }
    Row {width:parent.width;spacing:12
        Text {width:parent.width-282;text:'Twitch / live from somewhere';font.family:Appearance.font.heading;font.pixelSize:19;color:Theme.paper;anchors.verticalCenter:parent.verticalCenter}
        MusicButton {implicitWidth:110;implicitHeight:34;label:'Spotify';glyph:'\uf1bc';onActivated:{YouTubeDesk.release();SpotifyDesk.action('play');}}
        MusicButton {implicitWidth:148;implicitHeight:34;label:'Mini-player';glyph:'\uf24d';enabled:root.watching;onActivated:SpotifyDesk.showVideo('mini')}
    }
    MediaTransport {width:parent.width}
    Row {spacing:8
        Repeater {model:['Live now','Following','Search','Saved','Account'];MusicButton {required property string modelData;required property int index;implicitWidth:118;implicitHeight:32;glyph:'';label:modelData;selected:root.section===index;onActivated:root.browse(index)}}
        MusicButton {implicitWidth:170;implicitHeight:32;glyph:'\uf007';label:'Account playback';selected:root.useAccount;Accessible.name:'Use Chrome sign-in for the next stream';onActivated:root.useAccount=!root.useAccount}
        MusicButton {implicitWidth:34;implicitHeight:32;glyph:'\uf021';Accessible.name:'Refresh Twitch';enabled:!fetch.running;onActivated:root.browse(root.section)}
    }
    Row {width:parent.width;spacing:8
        DeskTextField {width:parent.width-116;height:38;text:root.query;placeholderText:'Find channels or paste a twitch.tv channel / recording link…';onTextEdited:root.query=text;onAccepted:root.browse(2)}
        MusicButton {implicitWidth:108;implicitHeight:38;label:'Search';glyph:'\uf002';enabled:root.query.trim().length>0;onActivated:root.browse(2)}
    }
    Text {width:parent.width;text:YouTubeDesk.platform==='Twitch'&&YouTubeDesk.error?YouTubeDesk.error:fetch.running||root.pendingRequest?'Loading Twitch…':root.notice;textFormat:Text.PlainText;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.paperMuted;wrapMode:Text.Wrap;maximumLineCount:2;elide:Text.ElideRight}
    Row {width:parent.width;height:Math.max(230,root.height-y-60);spacing:14
        Column {id:watchColumn;visible:root.watching;width:visible?Math.min(parent.width*.74,Math.max(240,parent.height-100)*16/9):0;height:parent.height;spacing:10
            Rectangle {width:parent.width;height:width*9/16;color:Theme.ink;radius:8
                Item {id:video;anchors.fill:parent;visible:SpotifyDesk.videoMode==='youtube'}
                Text {anchors.centerIn:parent;visible:SpotifyDesk.videoMode!=='youtube';text:'Video continues in the '+SpotifyDesk.videoMode+' player.';font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.section;color:Theme.paperMuted}
            }
            Text {width:parent.width;text:YouTubeDesk.track.title||'';textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.section;color:Theme.paper}
            Row {width:parent.width;spacing:8
                MusicButton {implicitWidth:42;implicitHeight:34;glyph:YouTubeDesk.playing?'\uf04c':'\uf04b';Accessible.name:'Play or pause Twitch';onActivated:YouTubeDesk.action('toggle')}
                MusicButton {implicitWidth:156;implicitHeight:34;label:'Fullscreen';glyph:'\uf065';onActivated:SpotifyDesk.showVideo('fullscreen')}
                MusicButton {implicitWidth:156;implicitHeight:34;label:'Restore here';glyph:'\uf066';onActivated:SpotifyDesk.showVideo('youtube',root.hostWindow?.screen?.name)}
                ControlSlider {width:180;title:'Volume';level:YouTubeDesk.volume;onEdited:v=>YouTubeDesk.action('volume',[String(Math.round(v))])}
                MusicButton {implicitWidth:34;implicitHeight:34;glyph:'\uf00d';Accessible.name:'Stop Twitch';onActivated:YouTubeDesk.release()}
            }
            Slider {visible:!YouTubeDesk.track.live;width:parent.width;height:22;from:0;to:Math.max(1,YouTubeDesk.duration);value:YouTubeDesk.position;onMoved:YouTubeDesk.action('seek-to',[String(Math.round(value))])}
        }
        ListView {width:parent.width-(root.watching?watchColumn.width+14:0);height:parent.height;clip:true;spacing:8;model:root.rows;ScrollBar.vertical:DeskScrollBar {}
            delegate:ChamferPanel {required property var modelData;width:ListView.view.width;height:118;fillColor:Theme.surfaceOne;borderColor:Theme.rule;chamfer:6;scanlines:false
                RoundedArtwork {x:10;y:12;width:70;height:70;cornerRadius:8;source:modelData.art;asynchronous:true;fillMode:Image.PreserveAspectCrop}
                Text {x:92;y:12;width:parent.width-104;text:modelData.artist;textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.section;color:Theme.paper}
                Text {x:92;y:35;width:parent.width-104;text:modelData.title;textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.paperMuted}
                Text {x:92;y:57;width:parent.width-104;text:modelData.live?'LIVE · '+Number(modelData.viewers||0).toLocaleString()+' viewers · '+(modelData.album||''):modelData.id.startsWith('videos/')?'Recording':'Channel · may be offline';font.family:Appearance.font.data;font.pixelSize:10;color:modelData.live?Theme.widgetAccent:Theme.paperMuted;elide:Text.ElideRight}
                Row {anchors.right:parent.right;anchors.bottom:parent.bottom;anchors.margins:8;spacing:8
                    MusicButton {implicitWidth:34;implicitHeight:28;glyph:root.section===3?'\uf00d':'\uf02e';Accessible.name:root.section===3?'Remove local bookmark':'Save channel locally';enabled:!bookmark.running;onActivated:root.setBookmark(modelData)}
                    MusicButton {implicitWidth:98;implicitHeight:28;label:'Watch';glyph:'\uf04b';enabled:!YouTubeDesk.loading;onActivated:YouTubeDesk.watch(Object.assign({},modelData,{private:root.useAccount}))}
                }
            }
            Text {visible:root.rows.length===0;anchors.centerIn:parent;text:'Choose Live now, Following or search for a channel.';width:parent.width-32;wrapMode:Text.Wrap;horizontalAlignment:Text.AlignHCenter;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.section;color:Theme.paperMuted}
        }
    }
    Text {width:parent.width;text:'Twitch video stays native. Chat, subscriptions and account changes remain on Twitch; no messages are sent from this widget.';wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
}
