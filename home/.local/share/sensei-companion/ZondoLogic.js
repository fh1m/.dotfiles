// Pure policy: no compositor, filesystem, network or user text access.
var notes = [];
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
function nextActivity(previous, music, random) {
    var pool=music?['dance','dance','guitar','dance','stretch']:['read','sip','stretch','stargaze','juggle','robot','plane','sketch','explore','garden','sleep','think','wave','typing'];
    pool=pool.filter(function(x){return x!==previous;});
    return pool[Math.min(pool.length-1,Math.floor(random*pool.length))];
}
function extendedPose(activity, frame) {
    var map={read:4,sip:5,stretch:6,stargaze:7,juggle:8,robot:9,plane:10,sketch:11,explore:12,garden:13,guitar:14,sleep:15};
    return activity==='dance'?frame%4:map[activity]===undefined?-1:map[activity];
}
