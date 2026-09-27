pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.services
Singleton {
 id:root
 readonly property var player:Mpris.players.values.find(p=>/spotify[_-]?player/i.test(p.dbusName))??null
 readonly property bool actualPlaying:playback.playing??player?.isPlaying??false
 readonly property bool playing:pendingPlaying<0?actualPlaying:pendingPlaying===1
 property string skipPending:""
 property string skipTitle:""
 onTitleChanged:if(skipPending&&title!==skipTitle){skipPending="";skipTimeout.stop();}
 Timer {id:skipTimeout;interval:4000;onTriggered:{root.skipPending="";root.dispatch("status");}}
 property int pendingPlaying:-1
 property int pendingVolume:-1
 readonly property int volume:pendingVolume>=0?pendingVolume:(playback.volume??0)
 readonly property string title:playback.track?.title||player?.trackTitle||"Spotify"
 readonly property string artist:playback.track?.artist||player?.trackArtist||"Sensei, your soundtrack awaits"
 readonly property string album:playback.track?.album||player?.trackAlbum||""
 readonly property string artSource:playback.track?.art||player?.trackArtUrl||""
 property double statusAt:Date.now()
 property double positionClock:Date.now()
 readonly property real positionMs:Math.max(0,Math.min(playback.track?.duration||Infinity,(playback.progress||0)+(playing?Math.max(0,positionClock-statusAt):0)))
 property string albumArt:"";property bool artExpanded:false;property string activeArtSource:""
 property var playback:({ready:false,track:{},volume:70,shuffle:false,repeat:"off"})
 property var account:({service:"starting",cachedLogin:false})
 property int page:0;property string libraryKind:"liked";property string searchKind:"tracks";property string query:""
 property string nextPage:"";property int totalRows:0;property var homeRows:[];property var libraryRows:[];property var playlistRows:[];property var queueRows:[];property var devices:[];property var searchResults:({tracks:[],albums:[],artists:[],playlists:[]})
 property var libraryCache:({})
 property var contextItem:({});property var contextRows:[];property string lyrics:"";property string error:"";property string warning:"";property bool loading:false
 property var actionQueue:[];property var requests:[];property string op:"";property var opArgs:[];property string activeQuery:""
 readonly property var visibleRows:contextItem.id?contextRows:page===0?(queueRows.length?queueRows:homeRows):page===1?queueRows:page===2?playlistRows:page===3?libraryRows:page===4?(searchResults[searchKind]||[]):[]
 property bool lyricsOpen:false
 property var lyricsData:({lines:[],plain:'',synced:false})
 property bool lyricsLoading:false
 property string lyricsError:''
 property string activeLyricsKey:''
 readonly property string lyricsKey:title+'|'+artist
 property real lyricPosition:0
 property int lyricOffset:0
 readonly property int lyricIndex:{let index=-1;const position=lyricPosition+lyricOffset;for(let i=0;i<(lyricsData.lines||[]).length;i++){if(lyricsData.lines[i].time>position)break;index=i;}return index;}
 function loadLyrics(){if(!lyricsOpen||page!==0||ShellState.dropdown!=='spotify'||lyricsFetch.running||title==='Spotify')return;activeLyricsKey=lyricsKey;lyricPosition=positionMs;lyricsLoading=true;lyricsError='';const track={title:title,artist:artist,album:album,duration:playback.track?.duration||player?.length*1000||0};lyricsFetch.command=['@HOME@/.local/bin/sensei-spotify','synced-lyrics',JSON.stringify(track)];lyricsFetch.running=true;}
 onLyricsOpenChanged:if(lyricsOpen){lyricsData={lines:[],plain:'',synced:false};lyricsDelay.restart();}
 onLyricsKeyChanged:{lyricsData={lines:[],plain:'',synced:false};lyricOffset=0;if(lyricsOpen)lyricsDelay.restart();}
 Timer {id:lyricsDelay;interval:250;onTriggered:root.loadLyrics()}
 Process {id:lyricsFetch;stdout:StdioCollector {onStreamFinished:{if(root.activeLyricsKey!==root.lyricsKey)return;try{const d=JSON.parse(text);root.lyricsError=d.error||'';if(!d.error)root.lyricsData=d;}catch(e){root.lyricsError='Sensei, lyrics could not be loaded.';}}}onExited:{root.lyricsLoading=false;if(root.lyricsOpen&&root.activeLyricsKey!==root.lyricsKey)lyricsDelay.restart();}}
 Timer {interval:250;repeat:true;running:root.lyricsOpen&&root.page===0&&ShellState.dropdown==='spotify'&&root.playing;triggeredOnStart:true;onTriggered:{root.positionClock=Date.now();root.lyricPosition=root.positionMs;}}
 function fmt(ms){let s=Math.floor(Math.max(0,ms)/1000);return Math.floor(s/60)+":"+String(s%60).padStart(2,'0');}
 function dispatch(name,args){if(name==='status'){if(!statusProc.running)statusProc.running=true;return;}if(name==='queue'){if(!queueProc.running)queueProc.running=true;return;}let job=[name].concat(args||[]);if(fetch.running){let q=requests.filter(j=>j[0]!==name);q.push(job);requests=q;return;}op=name;opArgs=args||[];activeQuery=name==='search'?String((args||[])[0]||''):query;loading=true;fetch.command=["@HOME@/.local/bin/sensei-spotify"].concat(job);fetch.running=true;}
 function uniqueRows(rows){let seen={};return rows.filter(r=>{let key=r.uri||r.id;if(!key||seen[key])return false;seen[key]=true;return true;});}
 function same(a,b){return JSON.stringify(a)===JSON.stringify(b);}
 function accept(name,d){if(d.error){error=d.error;return;}error="";warning=d.warning||"";if(name==='status')playback=d;else if(name==='account')account=d;else if(name==='queue'){if(!same(queueRows,d.rows||[]))queueRows=d.rows||[];}else if(name==='home')homeRows=uniqueRows(d.rows||[]);else if(name==='library'){if(d.kind==='playlists')playlistRows=d.rows||[];else{let cache=Object.assign({},libraryCache);cache[d.kind]=d;libraryCache=cache;if(d.kind===libraryKind)libraryRows=d.rows||[];}if(!contextItem.id&&(d.kind==='playlists'&&page===2||d.kind===libraryKind&&page===3)){nextPage=d.next||'';totalRows=d.total||0;}}else if(name==='context'){if(contextItem.id!==d.item?.id)return;contextItem=d.item||{};contextRows=uniqueRows(d.rows||[]);nextPage=d.next||'';totalRows=d.total||0;}else if(name==='more'){if(d.target==='context'&&d.contextId!==contextItem.id)return;nextPage=d.next||'';if(d.target==='context')contextRows=uniqueRows(contextRows.concat(d.rows||[]));else if(d.target==='playlists')playlistRows=uniqueRows(playlistRows.concat(d.rows||[]));else libraryRows=uniqueRows(libraryRows.concat(d.rows||[]));}else if(name==='search'&&activeQuery===query)searchResults=d;else if(name==='devices')devices=d.rows||[];else if(name==='lyrics')lyrics=typeof d.text==='string'?d.text:JSON.stringify(d.text);}
 function more(){if(!nextPage)return;let target=contextItem.id?'context':page===2?'playlists':'library';let kind=page===2?'playlist':libraryKind==='albums'?'album':libraryKind==='artists'?'artist':'track';dispatch('more',[nextPage,contextItem.id?'track':kind,target,contextItem.id||'']);}
 function refresh(force){contextItem={};nextPage="";if(page===0){dispatch('queue');dispatch('home');}else if(page===1)dispatch('queue');else if(page===2)dispatch('library',['playlists',force?'refresh':'']);else if(page===3)dispatch('library',[libraryKind,force?'refresh':'']);else if(page===4&&query.trim().length>=2)dispatch('search',[query]);else if(page===5)dispatch('devices');else dispatch('account');}
 function browse(item){if(!item.id)return;query="";searchDelay.stop();if(item.kind==='track'){play(item);return;}contextItem=item;contextRows=[];nextPage="";totalRows=0;dispatch('context',[item.kind,item.id]);}
 function play(item){if(item.kind!=='track'){action('play-context',[item.kind,item.id]);return;}if(contextItem.id&&(contextItem.kind==='playlist'||contextItem.kind==='album')){action('play-context-track',[contextItem.kind,contextItem.id,item.uri,JSON.stringify(contextRows)]);return;}const tracks=visibleRows.filter(e=>e.kind==='track'&&e.uri).slice(0,100);const index=tracks.findIndex(e=>e.id===item.id);if(index>=0&&tracks.length>1)action('play-list',[JSON.stringify({uris:tracks.map(e=>e.uri),tracks:tracks,offset:index})]);else action('play-track',[item.id]);}
 function action(name,args){args=args||[];if(name==='next'||name==='previous'){skipTitle=title;skipPending=name;skipTimeout.restart();}if(name==='volume-up'||name==='volume-down'){action('volume',[String(volume+(name==='volume-up'?5:-5))]);return;}if((name==='toggle'||name==='play'||name==='pause')&&player?.canTogglePlaying){const want=name==='toggle'?!playing:name==='play';pendingPlaying=want?1:0;sendAction(want?'play':'pause',[]);reconcile.restart();return;}if(name==='volume'){pendingVolume=Math.max(0,Math.min(100,Math.round(Number(args[0]))));volumeDelay.restart();volumeReconcile.restart();return;}if(name==='seek-to'){sliderAction=[name].concat(args||[]);sliderDelay.restart();return;}sendAction(name,args);}
 property var sliderAction:[]
 property var transportQueue:[]
 function sendAction(name,args){if(['play','pause','toggle','next','previous','volume','seek','seek-to','shuffle','repeat','play-list','play-track','play-context','play-context-track'].includes(name)){if((name==='next'||name==='previous')&&!(args||[]).length)args=[playing?'playing':'paused'];sendTransport(name,args);return;}let command=[name].concat(args||[]);if(act.running){let q=actionQueue;if(name==='volume'||name==='seek-to')q=q.filter(c=>c[0]!==name);actionQueue=q.concat([command]);return;}act.command=["@HOME@/.local/bin/sensei-spotify"].concat(command);act.running=true;}
 function sendTransport(name,args){let command=[name].concat(args||[]);if(transport.running){let q=transportQueue;if(['volume','seek-to','play','pause'].includes(name))q=q.filter(c=>name==='play'||name==='pause'? !['play','pause'].includes(c[0]):c[0]!==name);transportQueue=q.concat([command]);return;}transport.command=['@HOME@/.local/bin/sensei-spotify-transport'].concat(command);transport.running=true;}
 Process {id:transport;stdout:StdioCollector {onStreamFinished:{try{let d=JSON.parse(text);root.error=d.error||'';if(d.error){root.pendingPlaying=-1;root.skipPending='';}}catch(e){root.error='Sensei, the playback control did not return a valid response.';}}}onExited:{if(root.transportQueue.length){let c=root.transportQueue[0];root.transportQueue=root.transportQueue.slice(1);Qt.callLater(()=>root.sendTransport(c[0],c.slice(1)));}else actionRefresh.restart();}}
 function login(){Quickshell.execDetached(["kitty","--class","sensei-spotify-login","--title","Sensei · Spotify sign in","-e","@HOME@/.local/bin/sensei-spotify-login"]);}
 function restart(){Quickshell.execDetached(["systemctl","--user","restart","sensei-spotify.service"]);dispatch('account');}
 FileView {id:nativeEvents;path:'@HOME@/.cache/sensei-spotify/native-event.json';watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:root.dispatch('status')}
 Component.onCompleted:Qt.callLater(()=>root.dispatch("status"))
 onPageChanged:{query="";refresh(false);if(page===0&&lyricsOpen)lyricsDelay.restart();}
 onLibraryKindChanged:if(page===3){const cached=libraryCache[libraryKind];libraryRows=cached?.rows||[];refresh(false);}
 onQueryChanged:if(page===4){if(query.trim().length<2){searchDelay.stop();searchResults={tracks:[],albums:[],artists:[],playlists:[]};}else searchDelay.restart();}
 function loadArt(){if(!artSource||art.running)return;activeArtSource=artSource;art.command=["@HOME@/.local/bin/sensei-spotify-transport","art",artSource];art.running=true;}
 onArtSourceChanged:{if(!artSource)albumArt="";else loadArt();}
 Connections {target:root.player;ignoreUnknownSignals:true;function onVolumeChanged(){root.dispatch("status");}function onPositionChanged(){root.lyricPosition=root.positionMs;}function onTrackTitleChanged(){root.dispatch('status');if(ShellState.dropdown==='spotify'&&(root.page===0||root.page===1))root.dispatch('queue');}function onIsPlayingChanged(){if(root.pendingPlaying===(root.actualPlaying?1:0))root.pendingPlaying=-1;root.dispatch('status');}}
 Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==='spotify'){root.dispatch('status');if(!root.contextItem.id)root.refresh(false);else if(!root.contextRows.length)root.dispatch('context',[root.contextItem.kind,root.contextItem.id]);if(root.lyricsOpen)lyricsDelay.restart();}}}
 Process {id:queueProc;command:["@HOME@/.local/bin/sensei-spotify","queue"];stdout:StdioCollector {onStreamFinished:{try{root.accept("queue",JSON.parse(text));}catch(e){}}}}
 Process {id:statusProc;command:["@HOME@/.local/bin/sensei-spotify-transport","status"];stdout:StdioCollector {onStreamFinished:{try{let d=JSON.parse(text);if(!d.error){root.playback=d;root.statusAt=Date.now();root.positionClock=root.statusAt;if(root.pendingVolume>=0&&Math.abs(d.volume-root.pendingVolume)<=1)root.pendingVolume=-1;if(root.pendingPlaying===(root.actualPlaying?1:0))root.pendingPlaying=-1;}}catch(e){}}}}
 Timer {id:reconcile;interval:2200;onTriggered:{root.pendingPlaying=-1;root.dispatch('status');}}
 Process {id:fetch;stdout:StdioCollector {onStreamFinished:{try{root.accept(root.op,JSON.parse(text));}catch(e){root.error='Sensei, Spotify returned an unreadable response.';}}}onExited:{root.loading=false;if(root.requests.length){let j=root.requests[0];root.requests=root.requests.slice(1);Qt.callLater(()=>root.dispatch(j[0],j.slice(1)));}}}
 Process {id:art;stdout:StdioCollector {onStreamFinished:{try{let d=JSON.parse(text);if(d.path&&root.activeArtSource===root.artSource)root.albumArt=d.path;}catch(e){}}}onExited:if(root.activeArtSource!==root.artSource)Qt.callLater(root.loadArt)}
 Process {id:act;stdout:StdioCollector {onStreamFinished:{try{let d=JSON.parse(text);root.error=d.error||'';}catch(e){}}}onExited:{if(root.actionQueue.length){let c=root.actionQueue[0];root.actionQueue=root.actionQueue.slice(1);Qt.callLater(()=>root.sendAction(c[0],c.slice(1)));}else actionRefresh.restart();}}
 Timer {interval:300;repeat:true;running:root.pendingVolume>=0||root.pendingPlaying>=0;onTriggered:root.dispatch("status")}
 Timer {id:volumeDelay;interval:70;onTriggered:root.sendAction('volume',[String(root.volume)])}
 Timer {id:volumeReconcile;interval:5500;onTriggered:{root.pendingVolume=-1;root.dispatch('status');}}
 Timer {id:sliderDelay;interval:90;onTriggered:root.sendAction(root.sliderAction[0],root.sliderAction.slice(1))}
 Timer {id:actionRefresh;interval:120;onTriggered:{root.dispatch('status');if(ShellState.dropdown==='spotify'&&(root.page===0||root.page===1))root.dispatch('queue');}}
 Timer {id:searchDelay;interval:300;onTriggered:if(root.query.trim().length>=2)root.dispatch('search',[root.query])}
 Timer {interval:1000;repeat:true;running:ShellState.dropdown==='spotify'&&root.playing;onTriggered:{root.positionClock=Date.now();root.lyricPosition=root.positionMs;}}
 Timer {interval:15000;repeat:true;running:ShellState.dropdown==='spotify'&&(root.page===0||root.page===1)&&root.playing;onTriggered:root.dispatch('queue')}
 Timer {interval:60000;repeat:true;running:!root.player;triggeredOnStart:true;onTriggered:root.dispatch('account')}
}
