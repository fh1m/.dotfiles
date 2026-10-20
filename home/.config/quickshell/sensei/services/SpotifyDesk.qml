pragma Singleton
import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.services
import qs.config
Singleton {
 id:root
 Connections {target:YouTubeDesk;function onOwnsAudioChanged(){root.error="";root.statusError="";root.pendingPlaying=-1;root.pendingVolume=-1;root.skipPending="";skipTimeout.stop();root.statusAt=Date.now();}function onErrorChanged(){if(YouTubeDesk.error||YouTubeDesk.ownsAudio||YouTubeDesk.loading)root.error=YouTubeDesk.error;}}
 readonly property var player:Mpris.players.values.find(p=>playback.backend==="official" ? p.dbusName==="org.mpris.MediaPlayer2.spotify" : /spotify[_-]?player|go[_-]?librespot/i.test(p.dbusName))??null
 onPlayerChanged:Qt.callLater(()=>root.dispatch('status'))
 readonly property bool actualPlaying:playback.playing??player?.isPlaying??false
 readonly property bool playing:pendingPlaying<0?actualPlaying:pendingPlaying===1
 readonly property bool trackLoading:skipPending!==""||playback.loading===true
 property string skipPending:""
 property string skipTitle:""
 property string skipUri:""
 property double skipEventTime:0
 property string transportAction:""
 property string statusError:""
 property bool skipTimedOut:false
 Timer {id:skipTimeout;interval:root.playback.backend==='headless'?12000:4000;onTriggered:{root.skipPending="";root.skipTimedOut=true;root.error="Playback transition timed out. Check the current song before retrying.";root.dispatch("status");}}
 property int pendingPlaying:-1
 property int pendingVolume:-1
 readonly property int volume:pendingVolume>=0?pendingVolume:(playback.volume??Math.round((player?.volume??.7)*100))
 readonly property string title:playback.track?.title||player?.trackTitle||"Spotify"
 readonly property string artist:playback.track?.artist||player?.trackArtist||"Sensei, your soundtrack awaits"
 readonly property string album:playback.track?.album||player?.trackAlbum||""
 readonly property string artSource:playback.track?.art||player?.trackArtUrl||""
 property double statusAt:Date.now()
 property double positionClock:Date.now()
 readonly property real positionMs:YouTubeDesk.ownsAudio?YouTubeDesk.position:Math.max(0,Math.min(playback.track?.duration||Infinity,(playback.progress||0)+(playing?Math.max(0,positionClock-statusAt):0)))
 property string albumArt:"";property bool artExpanded:false;property string activeArtSource:""
 property var spotifyState:({ready:false,track:{},volume:70,shuffle:false,repeat:"off"})
 readonly property var playback:YouTubeDesk.ownsAudio?YouTubeDesk.snapshot:spotifyState
 property var account:({service:"starting",cachedLogin:false})
 property int page:0;property string libraryKind:"liked";property string searchKind:"tracks";property string query:""
 property string nextPage:"";property int totalRows:0;property var homeRows:[];property var libraryRows:[];property var playlistRows:[];property var spotifyQueueRows:[];readonly property var queueRows:YouTubeDesk.ownsAudio?YouTubeDesk.queue:spotifyQueueRows;property var devices:[];property var searchResults:({tracks:[],albums:[],artists:[],playlists:[]})
 property var libraryCache:({})
 property var contextItem:({});property var contextRows:[];property string lyrics:"";property string error:"";property string warning:"";property bool loading:false;property bool cataloguePending:false;property int catalogueAttempts:0
 property var actionQueue:[];property var requests:[];property string op:"";property var opArgs:[];property string activeQuery:""
 readonly property var visibleRows:contextItem.id?contextRows:page===0?(queueRows.length?queueRows:homeRows):page===1?queueRows:page===2?playlistRows:page===3?libraryRows:page===4?(searchResults[searchKind]||[]):[]
 property bool zen:false
 property bool musicBackdrop:false
 property bool fullscreen:false
 property string fullscreenOutput:""
 readonly property bool musicVisible:fullscreen||ShellState.dropdown==='spotify'
 readonly property bool lyricsVisible:fullscreen||(lyricsOpen&&page===0&&ShellState.dropdown==='spotify')
 function expand(){const origin=ShellState.screens.find(s=>s.name===(ShellState.dropdown==='spotify'?ShellState.dropdownOriginScreen:ShellState.focusedScreenName()));fullscreenOutput=(origin&&origin.height>=650?origin:ShellState.screens.find(s=>s.name===MachineProfile.primaryOutput)||origin)?.name||'';ShellState.closeAll();fullscreen=true;dispatch('queue');dispatch('devices');if(!playlistRows.length)dispatch('library',['playlists']);lyricsDelay.restart();}
 function collapse(restore){videosOpen=false;if(videoMode==='inline')videoSource="";fullscreen=false;if(restore){ShellState.dropdownOriginScreen=(ShellState.screens.find(s=>s.name===fullscreenOutput)||ShellState.screens.find(s=>s.name===MachineProfile.primaryOutput)||ShellState.screens[0])?.name||'';ShellState.dropdown='spotify';}}
 property bool spectrumEnabled:true
 property bool videoAudioLinked:false
 property string videoMode:'inline'
 property string videoDisplay:""
 property real videoX:48
 property real videoY:80
 property var videoWindows:({})
 readonly property string videoWindowOutput:{const requested=videoMode==='youtube'&&videoSlot.track===YouTubeDesk.track.id?videoSlot.output:videoDisplay;return (ShellState.screens.find(s=>s.name===requested)||ShellState.screens.find(s=>s.name===MachineProfile.primaryOutput)||ShellState.screens[0])?.name||'';}
 readonly property var videoWindow:videoWindows[YouTubeDesk.engineOutput||videoWindowOutput]||null
 property var videoSlot:({})
 property var videoOutput:null
 function attachVideo(sink){videoOutput=sink;}
 readonly property var videoPlayer:YouTubeDesk.nativeVideo?YouTubeDesk.nativePlayer:previewPlayer
 function showVideo(mode,output){
  if(mode==='inline'&&videoAudioLinked)mode='youtube';
  if(output)videoDisplay=output;
  if(!videoDisplay)videoDisplay=fullscreenOutput||ShellState.dropdownOriginScreen||ShellState.focusedScreenName();
  videoMode=mode;
  if(mode==='youtube'){page=YouTubeDesk.track.kind==='twitch'?8:7;videosOpen=false;ShellState.openDropdownOn('spotify',videoDisplay);}else if(mode==='inline'){if(!fullscreen)ShellState.openDropdown('spotify');videosOpen=true;}else videosOpen=false;
 }
 function closeVideo(keepAudio){const linked=videoAudioLinked;videoAudioLinked=false;videoSource='';videoMode='inline';videosOpen=false;videoOutput=null;videoPreviewError='';if(linked&&keepAudio!==true)YouTubeDesk.release();}
 MediaPlayer {id:previewPlayer;source:YouTubeDesk.nativeVideo?'':root.videoSource;autoPlay:true;videoOutput:YouTubeDesk.nativeVideo?null:root.videoOutput;audioOutput:AudioOutput {muted:true}
  onErrorOccurred:(code,message)=>{previewPlayer.stop();root.videoPreviewError='Video could not play. Try another candidate or YouTube.';root.videoSource='';}
  onMediaStatusChanged:if(mediaStatus===MediaPlayer.EndOfMedia){root.closeVideo(true);}
 }
 Timer {interval:15000;running:root.videoSource!==''&&!YouTubeDesk.nativeVideo&&previewPlayer.position===0;onTriggered:{root.videoSource='';root.videoPreviewError='Video did not start. Try another candidate or YouTube.';}}
 function toggleVideo(){if(videoAudioLinked)YouTubeDesk.action('toggle');else if(previewPlayer.playing)previewPlayer.pause();else previewPlayer.play();}
 property string videoSource:""
 property string videoId:""
 property string videoTitle:""
 property bool videoPreviewLoading:false
 property string videoPreviewError:""
 property string videoPreviewTrack:""
 function previewVideo(id){if(videoResolve.running)return;videoId=id;videoTitle=(videoData.rows||[]).find(r=>r.id===id)?.title||'Music video';videoPreviewTrack=lyricsKey;videoSource="";videoPreviewError="";videoPreviewLoading=true;videoResolve.command=['@HOME@/.local/bin/sensei-spotify','video-resolve',id];videoResolve.running=true;}
 Process {id:videoResolve;stdout:StdioCollector {onStreamFinished:{if(root.videoPreviewTrack!==root.lyricsKey||!root.videosOpen)return;try{const d=JSON.parse(text);root.videoSource=d.stream||'';root.videoPreviewError=d.warning||'';}catch(e){root.videoPreviewError='Preview unavailable. Use YouTube search.';}}}onExited:root.videoPreviewLoading=false}
 onVideosOpenChanged:if(!videosOpen&&videoMode==='inline'){videoSource="";videoPreviewError="";}
 property bool videosOpen:false
 property bool videosLoading:false
 property var videoData:({rows:[]})
 property string videoTrackKey:""
 function openVideos(refresh){videosOpen=true;if(videoFetch.running)return;videoTrackKey=lyricsKey;videosLoading=true;videoFetch.command=['@HOME@/.local/bin/sensei-spotify','music-videos',JSON.stringify(lyricTrack())].concat(refresh?['refresh']:[]);videoFetch.running=true;}
 Process {id:videoFetch;stdout:StdioCollector {onStreamFinished:{if(root.videoTrackKey!==root.lyricsKey)return;try{root.videoData=JSON.parse(text);}catch(e){root.videoData={rows:[],warning:'Video search unavailable; music keeps playing.'};}}}onExited:root.videosLoading=false}
 // Curated local receipt for Zondo; no full lyrics, signed media URLs or account data.
 FileView {id:zondoMusic;path:Quickshell.env('HOME')+'/.local/state/sensei-den/zondo-music.json';printErrors:false}
 function publishLyric(){const line=lyricsData?.synced&&lyricIndex>=0?lyricsData.lines[lyricIndex]?.text||'':'';zondoMusic.setText(JSON.stringify({at:Date.now(),playing:playing,title:title,line:line.trim().split(/\s+/).slice(0,8).join(' ')}));}
 onLyricIndexChanged:publishLyric()
 onPlayingChanged:publishLyric()
 property bool lyricsOpen:false
 property var lyricsData:({lines:[],plain:'',synced:false})
 property bool lyricsLoading:false
 property string lyricsError:''
 property string activeLyricsKey:''
 readonly property string lyricsKey:title+'|'+artist
 property real lyricPosition:0
 property int lyricOffset:0
 readonly property int lyricIndex:{let index=-1;const position=lyricPosition+lyricOffset;for(let i=0;i<(lyricsData.lines||[]).length;i++){if(lyricsData.lines[i].time>position)break;index=i;}return index;}
 function lyricTrack(){return {title:title,artist:artist,album:album,duration:playback.track?.duration||player?.length*1000||0};}
 function adjustLyrics(delta){lyricOffset=Math.max(-60000,Math.min(60000,lyricOffset+delta));action('lyric-offset',[JSON.stringify(lyricTrack()),String(lyricOffset)]);}
 function loadLyrics(refresh){if(!lyricsVisible||lyricsFetch.running||title==='Spotify')return;activeLyricsKey=lyricsKey;lyricPosition=positionMs;lyricsLoading=true;lyricsError='';const track={title:title,artist:artist,album:album,duration:playback.track?.duration||player?.length*1000||0};lyricsFetch.command=['@HOME@/.local/bin/sensei-spotify','synced-lyrics',JSON.stringify(track)].concat(refresh?['refresh']:[]);lyricsFetch.running=true;}
 onLyricsOpenChanged:if(lyricsOpen){lyricsData={lines:[],plain:'',synced:false};lyricsDelay.restart();}
 onLyricsKeyChanged:{videoData={rows:[]};videosOpen=false;lyricsData={lines:[],plain:'',synced:false};lyricOffset=0;if(lyricsVisible)lyricsDelay.restart();}
 Timer {id:lyricsDelay;interval:250;onTriggered:root.loadLyrics()}
 Process {id:lyricsFetch;stdout:StdioCollector {onStreamFinished:{if(root.activeLyricsKey!==root.lyricsKey)return;try{const d=JSON.parse(text);root.lyricsError=d.error||'';if(!d.error){root.lyricsData=d;root.lyricOffset=d.offset||0;}}catch(e){root.lyricsError='Sensei, lyrics could not be loaded.';}}}onExited:{root.lyricsLoading=false;if(root.lyricsVisible&&root.activeLyricsKey!==root.lyricsKey)lyricsDelay.restart();}}
 Timer {interval:root.lyricsVisible?250:1000;repeat:true;running:(root.lyricsVisible||root.lyricsData.synced)&&root.playing;triggeredOnStart:true;onTriggered:{root.positionClock=Date.now();root.lyricPosition=root.positionMs;}}
 function artworkUrl(value){const url=String(value||'');if(/^spotify:image:[a-f0-9]{40}$/i.test(url))return 'https://i.scdn.co/image/'+url.slice(14);return /^(https:\/\/|file:\/\/)/.test(url)?url:'';}
 function fmt(ms){let s=Math.floor(Math.max(0,ms)/1000);return Math.floor(s/60)+":"+String(s%60).padStart(2,'0');}
 function dispatch(name,args){if(name==='status'){if(!statusProc.running)statusProc.running=true;return;}if(name==='queue'){if(YouTubeDesk.ownsAudio)return;if(!queueProc.running)queueProc.running=true;return;}let job=[name].concat(args||[]);if(fetch.running){let key=JSON.stringify(job);let q=requests.filter(j=>JSON.stringify(j)!==key);q.push(job);requests=q.slice(-8);return;}op=name;opArgs=args||[];activeQuery=name==='search'?String((args||[])[0]||''):query;loading=true;fetch.command=["@HOME@/.local/bin/sensei-spotify"].concat(job);fetch.running=true;}
 function uniqueRows(rows){let seen={};return rows.filter(r=>{let key=r.uri||r.id;if(!key||seen[key])return false;seen[key]=true;return true;});}
 function same(a,b){return JSON.stringify(a)===JSON.stringify(b);}
 function accept(name,d){if(d.error){if(['home','queue','library','context','more','search','devices'].includes(name)){warning=d.error;}else error=d.error;return;}error="";warning=d.warning||"";if(d.partial!==undefined)cataloguePending=d.partial===true;if(name==='status')spotifyState=d;else if(name==='account')account=d;else if(name==='queue'){if(!same(spotifyQueueRows,d.rows||[]))spotifyQueueRows=d.rows||[];}else if(name==='home')homeRows=uniqueRows(d.rows||[]);else if(name==='library'){if(d.kind==='playlists')playlistRows=d.rows||[];else{let cache=Object.assign({},libraryCache);cache[d.kind]=d;libraryCache=cache;if(d.kind===libraryKind)libraryRows=d.rows||[];}if(!contextItem.id&&(d.kind==='playlists'&&page===2||d.kind===libraryKind&&page===3)){nextPage=d.next||'';totalRows=d.total||0;}}else if(name==='context'){if(contextItem.id!==d.item?.id)return;contextItem=Object.assign({},contextItem,d.item||{});contextRows=d.rows||[];nextPage=d.next||'';totalRows=d.total||0;}else if(name==='more'){if(d.target==='library'&&(page!==3||d.kind!==libraryKind))return;if(d.target==='playlists'&&page!==2)return;if(d.target==='context'&&d.contextId!==contextItem.id)return;nextPage=d.next||'';if(d.target==='context')contextRows=contextRows.concat(d.rows||[]);else if(d.target==='playlists')playlistRows=uniqueRows(playlistRows.concat(d.rows||[]));else libraryRows=uniqueRows(libraryRows.concat(d.rows||[]));}else if(name==='search'&&activeQuery===query)searchResults=d;else if(name==='devices')devices=d.rows||[];else if(name==='lyrics')lyrics=typeof d.text==='string'?d.text:JSON.stringify(d.text);}
 function more(){if(!nextPage||(fetch.running&&op==='more'))return;let target=contextItem.id?'context':page===2?'playlists':'library';let kind=page===2?'playlist':libraryKind==='albums'?'album':libraryKind==='artists'?'artist':'track';dispatch('more',[nextPage,contextItem.id?'track':kind,target,contextItem.id||'']);}
 function refresh(force){catalogueAttempts=0;contextItem={};nextPage="";if(page===0){dispatch('queue');dispatch('home');}else if(page===1)dispatch('queue');else if(page===2)dispatch('library',['playlists',force?'refresh':'']);else if(page===3)dispatch('library',[libraryKind,force?'refresh':'']);else if(page===4&&query.trim().length>=2)dispatch('search',[query,searchKind]);else if(page===5)dispatch('devices');else if(page===6)dispatch('account');}
 function browse(item){catalogueAttempts=0;if(!item.id)return;query="";searchDelay.stop();if(item.kind==='track'){play(item);return;}contextItem=item;contextRows=[];nextPage="";totalRows=0;dispatch('context',[item.kind,item.id]);}
 function play(item,sourceRows){if(['youtube','twitch'].includes(item.kind)){YouTubeDesk.play(item,item.kind==='twitch'||YouTubeDesk.watchMode);return;}if(YouTubeDesk.ownsAudio||YouTubeDesk.loading)YouTubeDesk.release();if(playback.backend==='headless'&&item.kind==='track'&&!contextItem.id&&(page===0||(page===3&&libraryKind==='liked'))){action('play-context-track',['collection','tracks',item.uri]);return;}if(item.kind!=='track'){action('play-context',[item.kind,item.id]);return;}if(!sourceRows&&contextItem.id&&(contextItem.kind==='playlist'||contextItem.kind==='album')){action('play-context-track',[contextItem.kind,contextItem.id,item.uri,JSON.stringify(contextRows.map(e=>e.uri))]);return;}const tracks=(sourceRows||visibleRows).filter(e=>e.kind==='track'&&e.uri);const index=tracks.findIndex(e=>e.id===item.id);if(index<0){action('play-track',[item.id]);return;}const run=tracks.slice(index,index+90);if(run.length>1)action('play-list',[JSON.stringify({uris:run.map(e=>e.uri),tracks:run,offset:0})]);else action('play-track',[item.id]);}
 function action(name,args){args=args||[];if(YouTubeDesk.ownsAudio&&['play','pause','toggle','next','previous','volume','volume-up','volume-down','seek-to','shuffle','repeat'].includes(name)){YouTubeDesk.action(name,args);return;}if((YouTubeDesk.ownsAudio||YouTubeDesk.loading)&&['play-track','play-context','play-context-track','play-list','liked-play','moment-resume','surprise','connect'].includes(name))YouTubeDesk.release();if(name==='next'||name==='previous'){if(skipPending||transport.running||trackLoading)return;skipTitle=title;skipUri=playback.track?.uri||"";skipEventTime=playback.eventTime||0;skipTimedOut=false;skipPending=name;skipTimeout.restart();}if(name==='volume-up'||name==='volume-down'){action('volume',[String(volume+(name==='volume-up'?5:-5))]);return;}if((name==='toggle'||name==='play'||name==='pause')&&player?.canTogglePlaying){const want=name==='toggle'?!playing:name==='play';pendingPlaying=want?1:0;sendAction(want?'play':'pause',[]);reconcile.restart();return;}if(name==='volume'){pendingVolume=Math.max(0,Math.min(100,Math.round(Number(args[0]))));volumeDelay.restart();volumeReconcile.restart();return;}if(name==='seek-to'){sliderAction=[name].concat(args||[]);sliderDelay.restart();return;}sendAction(name,args);}
 property var sliderAction:[]
 property var transportQueue:[]
 function sendAction(name,args){if(['play','pause','toggle','next','previous','volume','seek','seek-to','shuffle','repeat','play-list','play-track','play-context','play-context-track'].includes(name)){if((name==='next'||name==='previous')&&!(args||[]).length)args=[playing?'playing':'paused'];sendTransport(name,args);return;}let command=[name].concat(args||[]);if(act.running){let q=actionQueue;if(name==='volume'||name==='seek-to')q=q.filter(c=>c[0]!==name);actionQueue=q.concat([command]);return;}act.command=["@HOME@/.local/bin/sensei-spotify"].concat(command);act.running=true;}
 function sendTransport(name,args){let command=[name].concat(args||[]);if(transport.running){let q=transportQueue;if(['volume','seek-to','play','pause'].includes(name))q=q.filter(c=>name==='play'||name==='pause'? !['play','pause'].includes(c[0]):c[0]!==name);transportQueue=q.concat([command]);return;}transportAction=name;transport.command=['@HOME@/.local/bin/sensei-spotify-control'].concat(command);transport.running=true;}
 Process {id:transport;stdout:StdioCollector {onStreamFinished:{try{let d=JSON.parse(text);root.error=d.error||'';if(d.error){root.pendingPlaying=-1;root.skipPending='';skipTimeout.stop();}}catch(e){root.error='The playback control did not return a valid response.';root.skipPending='';skipTimeout.stop();}}}onExited:{if(root.transportQueue.length){let c=root.transportQueue[0];root.transportQueue=root.transportQueue.slice(1);Qt.callLater(()=>root.sendTransport(c[0],c.slice(1)));}else actionRefresh.restart();}}
 function selectBackend(value){YouTubeDesk.release();root.transportQueue=[];root.pendingPlaying=-1;root.skipPending="";skipTimeout.stop();sendTransport("backend",[value]);}
 function openOfficial(){sendTransport("launch",[]);}
 function login(){if(spotifyState.backend==='headless'){sendTransport('signin',[]);return;}Quickshell.execDetached(["@HOME@/.local/bin/sensei-terminal","--class","sensei-spotify-login","--title","Sensei · Spotify sign in","-e","@HOME@/.local/bin/sensei-spotify-login"]);}
 function repairBridge(){if(spotifyState.backend!=='official'){restart();return;}Quickshell.execDetached(['@HOME@/.local/bin/sensei-spotify-bridge-setup','--apply']);}
 function restart(){Quickshell.execDetached(["systemctl","--user","restart",spotifyState.backend==='headless'?"sensei-go-spotify.service":"sensei-spotify.service"]);dispatch('account');}
 FileView {path:'@HOME@/.config/sensei-den/music.json';watchChanges:true;printErrors:false;onFileChanged:{reload();root.transportQueue=[];root.dispatch('status');}onLoaded:root.dispatch('status')}
 FileView {id:nativeEvents;path:'@HOME@/.cache/sensei-spotify/native-event.json';watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:root.dispatch('status')}
 Component.onCompleted:Qt.callLater(()=>root.dispatch("status"))
 onPageChanged:{cataloguePending=false;query="";refresh(false);if(page===0&&lyricsOpen)lyricsDelay.restart();}
 onLibraryKindChanged:if(page===3){const cached=libraryCache[libraryKind];libraryRows=cached?.rows||[];refresh(false);}
 onSearchKindChanged:if(page===4&&query.trim().length>=3)searchDelay.restart();
 onQueryChanged:if(page===4){if(query.trim().length<3){searchDelay.stop();searchResults={tracks:[],albums:[],artists:[],playlists:[]};}else searchDelay.restart();}
 function loadArt(){if(YouTubeDesk.ownsAudio){albumArt=artSource;return;}if(!artSource||art.running)return;activeArtSource=artSource;art.command=["@HOME@/.local/bin/sensei-spotify-transport","art",artSource];art.running=true;}
 onArtSourceChanged:{if(artSource)loadArt();}
 Connections {target:root.player;ignoreUnknownSignals:true;function onVolumeChanged(){root.dispatch("status");}function onPositionChanged(){root.lyricPosition=root.positionMs;}function onTrackTitleChanged(){root.dispatch('status');if(root.musicVisible&&(root.fullscreen||root.page===0||root.page===1))root.dispatch('queue');}function onIsPlayingChanged(){if(root.pendingPlaying===(root.actualPlaying?1:0))root.pendingPlaying=-1;root.dispatch('status');}}
 Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==='spotify'){root.dispatch('status');if(!root.contextItem.id)root.refresh(false);else if(!root.contextRows.length)root.dispatch('context',[root.contextItem.kind,root.contextItem.id]);if(root.lyricsOpen)lyricsDelay.restart();}else if(!root.fullscreen){root.videosOpen=false;if(root.videoMode==='inline')root.videoSource='';}}}
 Process {id:queueProc;command:["@HOME@/.local/bin/sensei-spotify","queue"];stdout:StdioCollector {onStreamFinished:{try{root.accept("queue",JSON.parse(text));}catch(e){}}}}
 Process {id:statusProc;command:["@HOME@/.local/bin/sensei-spotify-control","status"];stdout:StdioCollector {onStreamFinished:{try{let d=JSON.parse(text);root.statusError=YouTubeDesk.ownsAudio?'':d.error||'';if(d.error)root.spotifyState=Object.assign({},root.spotifyState,{ready:false,playing:false,loading:false});if(!d.error){if((d.backend!==root.spotifyState.backend)||(d.localReleased&&!root.playback.localReleased)){root.transportQueue=[];root.pendingPlaying=-1;root.pendingVolume=-1;root.sliderAction=[];sliderDelay.stop();volumeDelay.stop();root.skipPending='';skipTimeout.stop();}root.spotifyState=d;root.statusAt=Date.now();root.positionClock=root.statusAt;if(root.skipPending&&!transport.running&&!d.loading&&d.eventTime>root.skipEventTime&&(d.eventUri!==root.skipUri||(root.skipPending==="previous"&&d.progress<1000))){root.skipPending="";skipTimeout.stop();}if(root.pendingVolume>=0&&Math.abs(d.volume-root.pendingVolume)<=1)root.pendingVolume=-1;if(root.pendingPlaying===(root.actualPlaying?1:0))root.pendingPlaying=-1;}}catch(e){}}}}
 Timer {id:reconcile;interval:2200;onTriggered:{root.pendingPlaying=-1;root.dispatch('status');}}
 Process {id:fetch;stdout:StdioCollector {onStreamFinished:{try{root.accept(root.op,JSON.parse(text));}catch(e){root.error='Sensei, Spotify returned an unreadable response.';}}}onExited:{root.loading=false;if(root.requests.length){let j=root.requests[0];root.requests=root.requests.slice(1);Qt.callLater(()=>root.dispatch(j[0],j.slice(1)));}}}
 Process {id:art;stdout:StdioCollector {onStreamFinished:{try{let d=JSON.parse(text);if(d.path&&root.activeArtSource===root.artSource)root.albumArt=d.path;}catch(e){}}}onExited:if(root.activeArtSource!==root.artSource)Qt.callLater(root.loadArt)}
 Process {id:act;stdout:StdioCollector {onStreamFinished:{try{let d=JSON.parse(text);root.error=d.error||'';if(d.warning)root.warning=d.warning;}catch(e){}}}onExited:{if(root.actionQueue.length){let c=root.actionQueue[0];root.actionQueue=root.actionQueue.slice(1);Qt.callLater(()=>root.sendAction(c[0],c.slice(1)));}else {actionRefresh.restart();if(root.page===2&&!root.contextItem.id)root.dispatch('library',['playlists','refresh']);if(root.page===3&&!root.contextItem.id)root.dispatch('library',[root.libraryKind,'refresh']);}}}
 Timer {interval:300;repeat:true;running:root.pendingVolume>=0||root.pendingPlaying>=0||root.skipPending!==""||root.playback.loading===true;onTriggered:root.dispatch("status")}
 Timer {id:volumeDelay;interval:70;onTriggered:root.sendAction('volume',[String(root.volume)])}
 Timer {id:volumeReconcile;interval:5500;onTriggered:{root.pendingVolume=-1;root.dispatch('status');}}
 Timer {id:sliderDelay;interval:90;onTriggered:root.sendAction(root.sliderAction[0],root.sliderAction.slice(1))}
 Timer {id:actionRefresh;interval:120;onTriggered:{root.dispatch('status');if(root.musicVisible&&(root.fullscreen||root.page===0||root.page===1))root.dispatch('queue');}}
 Timer {id:searchDelay;interval:500;onTriggered:if(root.query.trim().length>=3)root.dispatch('search',[root.query,root.searchKind])}
 Timer {interval:1000;repeat:true;running:root.musicVisible&&root.playing;onTriggered:{root.positionClock=Date.now();root.lyricPosition=root.positionMs;}}
 Timer {interval:5000;repeat:true;running:root.musicVisible&&root.playback.localReleased===true;onTriggered:root.dispatch('status')}
 Timer {interval:15000;repeat:true;running:root.musicVisible&&(root.fullscreen||root.page===0||root.page===1)&&root.playing;onTriggered:{root.dispatch('queue');if(root.fullscreen)root.dispatch('devices');}}
 Timer {interval:5000;repeat:true;running:root.musicVisible&&root.cataloguePending;onTriggered:{if(++root.catalogueAttempts>20){root.cataloguePending=false;root.warning='Track names are taking longer than expected. Saved rows remain available; refresh when ready.';return;}if(root.contextItem.id)root.dispatch('context',[root.contextItem.kind,root.contextItem.id]);else if(root.page===0)root.dispatch('home');else if(root.page===3)root.dispatch('library',[root.libraryKind]);}}
 Timer {interval:60000;repeat:true;running:!root.player;triggeredOnStart:true;onTriggered:root.dispatch('account')}
}
