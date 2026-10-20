// Pure policy: no compositor, filesystem, network or user text access.
var notes = [];
var activityAtlases = {};
function activitySprite(activity){return activityAtlases[activity]||null;}
function context(app) {
    app=String(app||'').toLowerCase();
    if (/nvim|neovim|code|cursor/.test(app)) return 'editor';
    if (/obsidian|zotero|noesis|sioyek|zathura/.test(app)) return 'study';
    if (/alacritty|kitty|terminal|foot/.test(app)) return 'terminal';
    return 'general';
}
function nextNote(app, recent, turn, random, blocked, favorites) {
    var ctx=context(app), kinds=['tip','wit','memory','wonder'], kind=kinds[turn%kinds.length];
    blocked=blocked||[];favorites=favorites||[];
    if(turn%4===3 && favorites.length)kind=favorites[Math.floor(random*favorites.length)];
    var pool=notes.filter(function(n,i){return n.kind===kind && blocked.indexOf(i)<0 && recent.indexOf(i)<0 && (!n.contexts.length||n.contexts.indexOf(ctx)>=0);});
    if (!pool.length) pool=notes.filter(function(n){return blocked.indexOf(notes.indexOf(n))<0 && recent.indexOf(notes.indexOf(n))<0;});
    if(!pool.length) return null;
    var note=pool[Math.min(pool.length-1,Math.floor(random*pool.length))];
    return {id:notes.indexOf(note),kind:note.kind,text:note.text};
}
function intersects(a,b) { return a.x<b.x+b.w && a.x+a.w>b.x && a.y<b.y+b.h && a.y+a.h>b.y; }
function canWalk(from,to) { return from.available && to.available && from.y===to.y && Math.abs(from.x-to.x)<=200; }
function place(width,height,w,h,windows,variant) {
    var xs=[.5,.2,.8,0,1,.35,.65].map(function(v){return Math.round(18+v*(width-w-36));}), ys=[.5,.25,.75,0,1].map(function(v){return Math.round(56+v*(height-h-118));});
    var candidates=[];
    for(var y=0;y<ys.length;y++) for(var x=0;x<xs.length;x++) candidates.push({x:xs[x],y:ys[y],w:w,h:h});
    var safe=candidates.filter(function(c){return c.x>=0 && c.y>=0 && c.x+c.w<=width && c.y+c.h<=height && !windows.some(function(win){return intersects(c,win);});});
    return safe.length ? {available:true,x:safe[variant%safe.length].x,y:safe[variant%safe.length].y} : {available:false,x:18,y:56};
}

// Weighted variety without consecutive repeats; no emotional inference or activity logging.
function nextActivity(previous, music, random, hidden, favorites) {
    hidden=hidden||[];favorites=favorites||[];
    var extra=Object.keys(activityAtlases).filter(function(x){return x!=='sing'&&x!=='phone';});
    var pool=music?['dance','dance','guitar','dance','stretch']:['read','sip','stretch','stargaze','juggle','robot','plane','sketch','explore','garden','sleep','think','wave','typing'];
    pool=pool.concat(music?extra.filter(function(x){return ['drums','bass','headphones','conduct'].indexOf(x)>=0;}):extra);
    pool=pool.concat(favorites.filter(function(x){return pool.indexOf(x)>=0;}));
    pool=pool.filter(function(x){return x!==previous&&hidden.indexOf(x)<0;});
    if(!pool.length)return "think";
    return pool[Math.min(pool.length-1,Math.floor(random*pool.length))];
}
function extendedPose(activity, frame) {
    var map={read:4,sip:5,stretch:6,stargaze:7,juggle:8,robot:9,plane:10,sketch:11,explore:12,garden:13,guitar:14,sleep:15};
    return activity==='dance'?frame%4:map[activity]===undefined?-1:map[activity];
}
// Animate only when the entire bounding corridor is exposed wallpaper.
function canTravel(from,to,w,h,windows) {
    if(!from.available||!to.available)return false;
    var corridor={x:Math.min(from.x,to.x),y:Math.min(from.y,to.y),w:Math.abs(to.x-from.x)+w,h:Math.abs(to.y-from.y)+h};
    return !windows.some(function(win){return intersects(corridor,win);});
}

// Curated after inspecting this actual wallpaper; no always-on vision inference.
function roofPlace(file,width,height,w,h,windows,variant) {
    if(!String(file).endsWith('/wallhaven-1q2p3v.png')||Math.abs(width/height-16/9)>.06)return null;
    var ledges=[[.15,.46],[.32,.55],[.46,.46],[.58,.65]];
    var q=ledges[Math.floor(variant/3)%ledges.length];
    var p={available:true,scene:'roof',x:Math.round(width*q[0]-w/2),y:Math.round(height*q[1]-h),w:w,h:h};
    if(p.x<0||p.y<56||p.x+w>width||p.y+h>height-50||windows.some(function(win){return intersects(p,win);}))return null;
    return p;
}

// Authored world perches, projected through the same viewport as the wallpaper.
function worldPlace(view,world,width,height,w,h,windows,variant) {
 if(!view||view.storyVersion===4||!world||!world.perches)return null;
 var points=world.perches[view.role]||[];
 for(var n=0;n<points.length;n++){
  var q=points[(n+variant)%points.length];
  var p={available:true,scene:view.role,x:Math.round((q[0]-view.x)/view.width*width-w/2),y:Math.round((q[1]-view.y)/view.height*height-h),w:w,h:h};
  if(p.x>=8&&p.y>=52&&p.x+w<=width-8&&p.y+h<=height-48&&!windows.some(function(win){return intersects(p,win);}))return p;
 }
 return null;
}

// A short, fresh line from the existing media widget, never a new lyrics request.
function singLine(receipt, now, last, random) {
    if(!receipt||!receipt.playing||(Number.isFinite(receipt.until)&&now>=receipt.until)||!Number.isFinite(receipt.at)||now-receipt.at<0||now-receipt.at>30000||random>.4)return '';
    var line=String(receipt.line||'').trim().slice(0,320);
    return !line||line===last?'':line;
}

function noticeTitle(entry) {
    return String(entry.summary||'New notification').trim().slice(0,160);
}
function noticeText(entry) {
    return String(entry.body&&entry.body!==entry.summary?entry.body:'').trim().slice(0,320);
}
function singingContinues(playing, dnd, now, end, lastLineAt) {
    return playing&&!dnd&&now<end&&now-lastLineAt<8000;
}

// Use ES5 array operations: Qt's JS engine does not provide Array.flatMap.
function nextNotice(sources, seen) {
    if(sources.some(function(n){return n.dnd===true;}))return null;
    var rows=[];
    sources.forEach(function(n){if(n.unread>0)rows=rows.concat(n.entries||[]);});
    rows=rows.filter(function(e){return seen.indexOf(e.id)<0;});
    rows.sort(function(a,b){return a.at-b.at;});
    return rows.length?rows[0]:null;
}
