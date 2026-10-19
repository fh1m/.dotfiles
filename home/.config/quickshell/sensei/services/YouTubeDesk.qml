pragma Singleton
import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

Singleton {
    id:root
    property bool ownsAudio:false
    property bool nativeVideo:false
    readonly property var nativePlayer:audioPlayer
    property var engines:({})
    property var usedDisplays:[]
    property string engineOutput:''
    property var currentMedia:({})
    property real desiredVolume:65
    property bool startPaused:false
    property bool loadPaused:false
    readonly property var audioPlayer:engines[engineOutput]||fallbackPlayer
    function registerEngine(output,player){let copy=Object.assign({},engines);copy[output]=player;engines=copy;if(output===engineOutput)loadCurrent();}
    function forgetEngine(output){let copy=Object.assign({},engines);delete copy[output];engines=copy;}
    function loadCurrent(){const player=engines[engineOutput];if(!player||!currentMedia.stream)return;player.volume=desiredVolume;player.playbackRate=speed;player.load(currentMedia.video||currentMedia.stream,currentMedia.video&&!currentMedia.combined?currentMedia.stream:'',!!currentMedia.video,pendingSeek,loadPaused);pendingSeek=0;}
    function selectEngine(output,resume,paused){loadPaused=!!paused;if(!output)return;if(engines[engineOutput]){desiredVolume=audioPlayer.volume;audioPlayer.stop();}pendingSeek=Math.max(0,resume||0);engineOutput=output;if(!usedDisplays.includes(output))usedDisplays=usedDisplays.concat([output]);else loadCurrent();}
    function relocate(){if(ownsAudio&&nativeVideo&&currentMedia.video&&SpotifyDesk.videoWindowOutput&&engineOutput!==SpotifyDesk.videoWindowOutput)selectEngine(SpotifyDesk.videoWindowOutput,position,!playing);}
    readonly property string platform:track.kind==='twitch'?'Twitch':'YouTube'
    property bool resolving:false
    property int generation:0
    property int requestGeneration:0
    property string error:""
    property var track:({})
    property var queue:[]
    property int index:-1
    property bool shuffle:false
    property string repeat:"off"
    property bool watchMode:false
    property int quality:1080
    property int pendingSeek:0
    function changeQuality(value){if(![360,480,720,1080].includes(value)||loading)return;quality=value;if(ownsAudio&&watchMode&&!track.live){pendingSeek=position;play(track,true,!playing);}}
    property real speed:1
    property var chapters:[]
    property var captionLanguages:[]
    property var transcript:[]
    property string captionLanguage:'en'
    property bool captionsEnabled:false
    property bool transcriptOpen:false
    property bool transcriptLoading:false
    property string transcriptNotice:''
    property string transcriptRequestKey:''
    readonly property int captionIndex:{let low=0,high=transcript.length-1,result=-1;while(low<=high){const middle=(low+high)>>1;if(transcript[middle].time<=position){result=middle;low=middle+1;}else high=middle-1;}return result;}
    function loadTranscript(){if(transcriptFetch.running||!track.id||track.kind==='twitch')return;transcriptRequestKey=track.id+'|'+captionLanguage;transcriptLoading=true;transcriptFetch.command=['@HOME@/.local/bin/sensei-spotify','youtube-transcript',track.id,captionLanguage].concat(track.private?['private']:[]);transcriptFetch.running=true;}
    Process {id:transcriptFetch;stdout:StdioCollector {onStreamFinished:{try{if(root.transcriptRequestKey!==root.track.id+'|'+root.captionLanguage)return;const d=JSON.parse(text);root.transcript=d.lines||[];root.captionLanguages=d.languages||root.captionLanguages;root.transcriptNotice=d.error||d.warning||'';}catch(e){root.transcriptNotice='Transcript unavailable; playback is unaffected.';}}}onExited:{root.transcriptLoading=false;if(root.transcriptRequestKey!==root.track.id+'|'+root.captionLanguage&&(root.transcriptOpen||root.captionsEnabled))Qt.callLater(root.loadTranscript);}}
    onSpeedChanged:if(engines[engineOutput])audioPlayer.playbackRate=speed
    property var pending:({})
    readonly property bool playing:audioPlayer.playing
    readonly property int position:audioPlayer.position
    readonly property int duration:audioPlayer.duration||track.duration||0
    readonly property int volume:Math.round(audioPlayer.volume)
    readonly property bool loading:resolving||pauseSpotify.running||(ownsAudio&&audioPlayer.loading===true)
    readonly property var snapshot:({ready:true,backend:track.kind==='twitch'?'twitch':'youtube',owner:platform,playing:playing,loading:loading,track:track,progress:position,volume:volume,shuffle:shuffle,repeat:repeat,device:platform,context:'youtube:queue'})
    // Resolve URLs outside the render process. MpvQt supplies one A/V clock;
    // absent optional module cannot take the rest of the shell down.
    MediaPlayer {id:fallbackPlayer;property real volume:65;property bool loading:false;property size videoSize:Qt.size(-1,-1);property int frameNumber:0;property real avsync:0}
    Connections {
        target:root.engines[root.engineOutput]||null
        ignoreUnknownSignals:true
        function onFailed(){root.error=root.platform+' playback could not continue. Press play to reconnect, or choose another item.';root.audioPlayer.stop();}
        function onEnded(){if(root.repeat==='track'){root.audioPlayer.position=0;root.audioPlayer.play();}else root.next(false);}
        function onLoaded(){if(root.pendingSeek>0){root.audioPlayer.position=root.pendingSeek;root.pendingSeek=0;}}
    }
    function updateVideo(){if(engines[engineOutput]&&ownsAudio&&nativeVideo)audioPlayer.setVideoEnabled(true);}
    Connections {target:SpotifyDesk;function onVideoModeChanged(){Qt.callLater(root.relocate);Qt.callLater(root.updateVideo);}function onMusicVisibleChanged(){if(root.nativeVideo&&root.ownsAudio&&SpotifyDesk.videoMode==='youtube'&&!SpotifyDesk.musicVisible)SpotifyDesk.videoMode='mini';Qt.callLater(root.updateVideo);}function onPageChanged(){Qt.callLater(root.updateVideo);}function onVideoWindowOutputChanged(){Qt.callLater(root.relocate);}}
    function watch(item){play(item,true);}
    function play(item,watchVideo,paused){startPaused=!!paused;
        if(resolving||pauseSpotify.running||!item?.id)return;generation++;requestGeneration=generation;
        if(!queue.some(r=>r.id===item.id))queue=queue.concat([item]);
        watchMode=!!watchVideo||item.kind==='twitch';error='';resolving=true;resolve.command=['@HOME@/.local/bin/sensei-spotify',item.kind==='twitch'?'twitch-watch':watchVideo?'youtube-watch':'youtube-audio',item.id].concat(watchMode?[String(quality)]:[]).concat(item.private?['private']:[]);resolve.running=true;
    }
    function removeQueued(item){queue=queue.filter(r=>r.id!==item.id);index=queue.findIndex(r=>r.id===track.id);}
    function moveQueued(item,direction){const from=queue.findIndex(r=>r.id===item.id),to=from+direction;if(from<0||to<0||to>=queue.length)return;let copy=queue.slice();copy.splice(to,0,copy.splice(from,1)[0]);queue=copy;index=queue.findIndex(r=>r.id===track.id);}
    function enqueue(item){if(!queue.some(r=>r.id===item.id))queue=queue.concat([item]);}
    function release(){generation++;pendingSeek=0;pending={};currentMedia={};if(SpotifyDesk.videoAudioLinked)SpotifyDesk.closeVideo(true);audioPlayer.stop();audioPlayer.source='';nativeVideo=false;ownsAudio=false;error='';}
    function begin(){
        if(!pending.stream)return;
        nativeVideo=!!pending.video;track=pending.track;if(track.kind==='twitch'){transcriptOpen=false;captionsEnabled=false;}chapters=pending.chapters||[];captionLanguages=pending.captionLanguages||[];transcript=[];transcriptNotice="";index=queue.findIndex(r=>r.id===track.id);ownsAudio=true;
        if(pending.video){SpotifyDesk.videoAudioLinked=true;SpotifyDesk.videoId=track.id;SpotifyDesk.videoTitle=track.title;SpotifyDesk.videoMode=ShellState.dropdown==='spotify'?'youtube':'mini';SpotifyDesk.videoDisplay=ShellState.dropdownOriginScreen||SpotifyDesk.videoDisplay;SpotifyDesk.videoSource=pending.video;SpotifyDesk.page=track.kind==='twitch'?8:7;}else if(SpotifyDesk.videoAudioLinked)SpotifyDesk.closeVideo(true);
        currentMedia=pending;pending={};selectEngine(SpotifyDesk.videoWindowOutput,pendingSeek,startPaused);Qt.callLater(updateVideo);if(captionsEnabled||transcriptOpen)Qt.callLater(loadTranscript);
    }
    function next(back){
        if(resolving||!queue.length)return;
        if(back&&position>3000){audioPlayer.position=0;return;}
        let target=shuffle&&queue.length>1?(index+1+Math.floor(Math.random()*(queue.length-1)))%queue.length:index+(back?-1:1);
        if(target<0||target>=queue.length){if(repeat==='context')target=(target+queue.length)%queue.length;else return;}
        play(queue[target],watchMode);
    }
    function action(name,args){
        args=args||[];
        if(name==='toggle'){if(playing)audioPlayer.pause();else if(error)play(track,watchMode);else audioPlayer.play();}
        else if(name==='play'){if(error)play(track,watchMode);else audioPlayer.play();}else if(name==='pause')audioPlayer.pause();
        else if(name==='next')next(false);else if(name==='previous')next(true);
        else if(name==='volume')audioPlayer.volume=Math.max(0,Math.min(100,Number(args[0])));
        else if(name==='volume-up')audioPlayer.volume=Math.min(100,audioPlayer.volume+5);
        else if(name==='volume-down')audioPlayer.volume=Math.max(0,audioPlayer.volume-5);
        else if(name==='seek-to')audioPlayer.position=Math.max(0,Math.min(duration,Number(args[0])));
        else if(name==='shuffle')shuffle=!shuffle;
        else if(name==='repeat')repeat=repeat==='off'?'context':repeat==='context'?'track':'off';
    }
    Process {
        id:resolve
        stdout:StdioCollector {onStreamFinished:{
            try {if(root.requestGeneration!==root.generation)return;const d=JSON.parse(text);if(d.error||!d.stream){root.error=d.error||'YouTube stream unavailable.';return;}
                root.pending=d;
                // Resolve first. A failed search never stops existing Spotify audio.
                if(SpotifyDesk.spotifyState.playing){pauseSpotify.running=true;}else root.begin();
            }catch(e){root.error='YouTube returned an unreadable stream.';}
        }}
        onExited:root.resolving=false
    }
    Process {
        id:pauseSpotify
        command:['@HOME@/.local/bin/sensei-spotify-control','pause']
        property bool accepted:false
        onStarted:accepted=false
        stdout:StdioCollector {onStreamFinished:{try{pauseSpotify.accepted=!JSON.parse(text).error;}catch(e){pauseSpotify.accepted=false;}}}
        onExited:if(accepted)root.begin();else {root.pending={};root.error='Spotify could not pause. YouTube was not started to avoid overlapping audio.';}
    }
    Timer {interval:15000;running:root.ownsAudio&&audioPlayer.loading===true;onTriggered:{root.error='YouTube did not start. Retry this item or return to Spotify.';audioPlayer.stop();}}
}
