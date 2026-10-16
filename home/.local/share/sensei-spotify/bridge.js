// Narrow local integration. Never exports session/OAuth credentials.
(async function senseiBridge(){
 const endpoint='http://127.0.0.1:__PORT__',secret='__SECRET__';
 while(!globalThis.Spicetify?.Platform?.RootlistAPI)await new Promise(r=>setTimeout(r,500));
 const P=Spicetify.Platform;
 const post=async(path,data)=>{const r=await fetch(endpoint+path,{method:'POST',headers:{'Authorization':'Bearer '+secret,'Content-Type':'application/json'},body:JSON.stringify(data)});if(!r.ok)throw new Error('Bridge '+r.status);return r.json();};
 const image=x=>{const a=x?.images||x?.coverArt?.sources||x?.visuals?.avatarImage?.sources||[];return a[0]?.url||'';};
 function row(raw){
  const x=raw?.item?.data||raw?.item||raw?.track?.data||raw?.track||raw?.data||raw;
  if(!x?.uri)return null;
  const kind=x.uri.split(':')[1];if(!['track','album','artist','playlist','collection'].includes(kind))return null;
  const album=x.album||x.albumOfTrack||{};const artists=Array.isArray(x.artists)?x.artists:(x.artists?.items||[]);
  return {id:x.uri.split(':').pop(),uri:x.uri,kind:kind==='collection'?'playlist':kind,title:x.name||x.profile?.name||'Untitled',artist:artists.map(a=>a.name||a.profile?.name||'').filter(Boolean).join(', ')||x.owner?.displayName||x.owner?.display_name||kind,album:album.name||'',albumId:album.uri?.split(':').pop()||'',art:image(x)||image(album),duration:x.duration?.milliseconds??x.duration?.totalMilliseconds??x.duration_ms??0,explicit:x.isExplicit??false,description:String(x.description||'').replace(/<[^>]+>/g,''),count:x.totalLength??x.totalCount??0};
 }
 const rows=items=>(items||[]).map(row).filter(Boolean);
 const graphql=async(name,variables)=>{const def=Spicetify.GraphQL.Definitions[name];if(!def)throw new Error('Spotify update: '+name+' is unavailable');const d=await Spicetify.GraphQL.Request(def,variables);if(d.errors?.length)throw new Error(d.errors.map(x=>x.message).join('; '));return d.data||d;};
 const offset=args=>Math.max(0,Math.min(100000,Number(args)||0));
 const page=(data,kind,at)=>{const r=rows(data.items);const reported=data.totalLength||data.totalCount||0;const total=Math.max(reported,at+r.length);const more=reported>0?at+r.length<reported:r.length>=100;return {kind,rows:r,total,totalKnown:reported>0,next:more&&r.length?'desktop:'+kind+':'+(at+r.length):'',source:'Spotify desktop',complete:!more};};
 async function library(kind,at=0){
  if(kind==='playlists'){
   const tree=await P.RootlistAPI.getContents();const all=[];
   function walk(items){for(const x of items||[]){if(x.type==='folder')walk(x.items);else {const r=row(x);if(r?.kind==='playlist')all.push(r);}}}walk(tree.items);
   return {kind,rows:all,total:all.length,next:'',source:'Spotify desktop',complete:true};
  }
  if(kind==='liked')return page(await P.LibraryAPI.getTracks({limit:100,offset:at}),kind,at);
  if(kind==='recent'||kind==='top'){
   const d=await P.PlayHistoryAPI.getContents();let r=rows(d.items);
   if(kind==='top'){const frequencies=new Map();for(const item of r){const old=frequencies.get(item.uri)||{item,count:0};old.count++;frequencies.set(item.uri,old);}r=Array.from(frequencies.values()).sort((a,b)=>b.count-a.count).map(x=>x.item);}
   return {kind,rows:r,total:r.length,next:'',source:'Spotify desktop history',warning:kind==='top'?'Ranked by available recent history, not Spotify long-term top tracks.':''};
  }
  if(kind==='albums'||kind==='artists'){
   const filter=Array.from({length:40},(_,i)=>String(i)).find(id=>P.LibraryAPI.getFilterLabel(id)===kind.slice(0,-1));
   if(filter===undefined)throw new Error('This Spotify version does not expose the '+kind+' filter');
   const d=await P.LibraryAPI.getContents({limit:100,offset:at,filters:[filter]});
   return page(d,kind,at);
  }
  throw new Error('Unsupported library collection');
 }
 async function context(kind,id,at=0){
  if(!['playlist','album','artist'].includes(kind)||!/^[A-Za-z0-9]{1,64}$/.test(id))throw new Error('Invalid Spotify context');
  const uri='spotify:'+kind+':'+id;
  if(kind==='playlist'){
   const d=await P.PlaylistAPI.getContents(uri,{offset:at,limit:100});
   const m=await P.PlaylistAPI.getMetadata(uri);const r=page(d,'context',at);
   r.item=row(m)||{id,uri,kind,title:'Playlist'};r.next=r.next?'desktop:context:'+kind+':'+id+':'+(at+r.rows.length):'';return r;
  }
  if(kind==='album'){
   const d=await graphql('getAlbum',{uri,locale:'en',offset:at,limit:100});const album=d.albumUnion||d.album;
   const tracks=album?.tracksV2||album?.tracks;const r=rows((tracks?.items||[]).map(x=>x.track||x));
   return {item:row(album)||{id,uri,kind,title:'Album'},rows:r,total:tracks?.totalCount??r.length,next:'',source:'Spotify desktop'};
  }
  const d=await graphql('queryArtistOverview',{uri,locale:'en',includePrerelease:false});const artist=d.artistUnion||d.artist;
  const r=rows((artist?.discography?.topTracks?.items||[]).map(x=>x.track));
  return {item:row(artist)||{id,uri,kind,title:'Artist'},rows:r,total:r.length,next:'',source:'Spotify desktop'};
 }
 async function handle(op,args){
  if(op==='probe'){
   if(args[0]==='filters')return P.LibraryAPI.getStaticallyKnownFilters();
   if(args[0]==='mutations'){const out={};for(const [api,method] of [['PlaylistAPI','add'],['RootlistAPI','createPlaylist'],['ConnectAPI','transferToRemote'],['ConnectAPI','transferPlayback'],['LibraryAPI','add']])out[api+'.'+method]=String(P[api][method]).slice(0,1200);return out;}
   return {connected:true,version:Spicetify.Config?.version,library:!!P.LibraryAPI,playlists:!!P.PlaylistAPI,queue:!!P.PlayerAPI?.getQueue,search:!!Spicetify.GraphQL?.Definitions?.searchModalResults};
  }
  if(op==='library')return library(args[0],offset(args[1]));
  if(op==='context')return context(args[0],args[1],offset(args[2]));
  if(op==='queue'){const q=await P.PlayerAPI.getQueue();return {rows:rows([...(q.queued||[]),...(q.nextUp||[])]),current:row(q.current),source:'Spotify desktop'};}
  if(op==='search'){
   const q=String(args[0]||'').trim().slice(0,200);if(q.length<3)return {tracks:[],albums:[],artists:[],playlists:[]};
   const d=await graphql('searchModalResults',{searchTerm:q,limit:40,numberOfTopResults:40,offset:0,includeAuthors:false});
   const items=rows((d.searchV2?.topResultsV2?.itemsV2||[]));const result={tracks:[],albums:[],artists:[],playlists:[],source:'Spotify desktop'};
   for(const item of items)result[item.kind+'s']?.push(item);return result;
  }
  if(op==='devices'){
   const d=P.ConnectAPI.getState();const devices=d.devices||d.connectState?.devices||[];
   return {rows:(Array.isArray(devices)?devices:Object.values(devices)).map(x=>({id:x.id||x.deviceId,name:x.name||x.deviceName,type:x.type||x.deviceType,is_active:x.isActive||x.isLocal||false,volume_percent:Math.round((x.volume??0)*100)})),source:'Spotify desktop'};
  }
  if(op==='play-context-track'){
   const [kind,id,track]=args;if(!['playlist','album'].includes(kind)||!/^[A-Za-z0-9]{22}$/.test(id)||!/^spotify:track:[A-Za-z0-9]{22}$/.test(track))throw new Error('Invalid track selection');
   await P.PlayerAPI.play({uri:'spotify:'+kind+':'+id},{featureIdentifier:'your_library',featureVersion:'sensei-local'},{skipTo:{uri:track}});return {ok:true};
  }
  if(op==='play-list'){
   const d=JSON.parse(args[0]);const uris=(d.uris||[]).slice(0,100);if(!uris.length||uris.some(u=>!/^spotify:track:[A-Za-z0-9]{22}$/.test(u)))throw new Error('Invalid song selection');
   await P.PlayerAPI.play({uri:'spotify:internal:dummy',pages:[{items:uris.map(uri=>({uri}))}]},{featureIdentifier:'your_library',featureVersion:'sensei-local'},{skipTo:{index:Math.max(0,Math.min(uris.length-1,Number(d.offset)||0))}});return {ok:true};
  }
  const current=()=>P.PlayerAPI.getState()?.item?.uri||Spicetify.Player.data?.item?.uri;
  const trackUri=u=>{if(!/^spotify:track:[A-Za-z0-9]{22}$/.test(u||''))throw new Error('Choose a valid song first');return u;};
  if(op==='liked-play'){await P.PlayerAPI.play({uri:'spotify:collection:tracks'},{featureIdentifier:'your_library',featureVersion:'sensei-local'},{});return {ok:true};}
  if(op==='enqueue'||op==='queue-add'){await P.PlayerAPI.addToQueue([{uri:trackUri(args[0])}]);return {ok:true};}
  if(op==='like'||op==='unlike'){await P.LibraryAPI[op==='like'?'add':'remove']({uris:[trackUri(args[0]||current())]});return {ok:true};}
  if(op==='playlist-add'){
   if(!/^[A-Za-z0-9]{22}$/.test(args[0]))throw new Error('Choose an editable playlist');
   await P.PlaylistAPI.add('spotify:playlist:'+args[0],[trackUri(args[1])],{after:'end'});return {ok:true};
  }
  if(op==='playlist-create'){
   const name=String(args[0]||'').trim().slice(0,100);if(!name)throw new Error('Enter a playlist name');
   const uri=await P.RootlistAPI.createPlaylist(name,{after:'start'});if(!uri)throw new Error('Spotify did not create the playlist');return {ok:true,uri};
  }
  if(op==='connect'){
   const id=String(args[0]||'');const state=P.ConnectAPI.getState();const devices=state.devices||[];
   const known=(Array.isArray(devices)?devices:Object.values(devices)).some(d=>(d.id||d.deviceId)===id);
   if(!known)throw new Error('Device is no longer available; refresh Devices');
   await P.ConnectAPI.transferPlayback(id,{});return {ok:true};
  }
  throw new Error('Open this action in Spotify; no Web API fallback was attempted.');
 }
 while(true){try{const c=await post('/poll',{});if(c.id){let result;try{result=await handle(c.operation,c.args||[]);}catch(e){result={error:String(e.message||e).slice(0,250)};}await post('/result',{id:c.id,result});}}catch(e){await new Promise(r=>setTimeout(r,4000));}}
})();
