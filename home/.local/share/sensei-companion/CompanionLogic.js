// Pure policy: no compositor, filesystem, network or user text access.
var notes = [];
function context(app) {
    app=String(app||'').toLowerCase();
    if (/nvim|neovim|code|cursor/.test(app)) return 'editor';
    if (/obsidian|zotero|noesis|sioyek|zathura/.test(app)) return 'study';
    if (/alacritty|kitty|terminal|foot/.test(app)) return 'terminal';
    return 'general';
}
function nextNote(app, recent, turn, random) {
    var ctx=context(app), kind=turn%3===2?'wit':'tip';
    var pool=notes.filter(function(n,i){return n.kind===kind && recent.indexOf(i)<0 && (!n.contexts.length||n.contexts.indexOf(ctx)>=0);});
    if (!pool.length) pool=notes.filter(function(n){return n.kind===kind;});
    var note=pool[Math.min(pool.length-1,Math.floor(random*pool.length))];
    return {id:notes.indexOf(note),kind:note.kind,text:note.text};
}
function intersects(a,b) { return a.x<b.x+b.w && a.x+a.w>b.x && a.y<b.y+b.h && a.y+a.h>b.y; }
function canWalk(from,to) { return from.available && to.available && from.y===to.y && Math.abs(from.x-to.x)<=200; }
function place(width,height,w,h,windows,variant) {
    var xs=[width-w-18,width-w-158,18,158,Math.round((width-w)/2)], ys=[height-h-62,56];
    var candidates=[];
    for(var y=0;y<ys.length;y++) for(var x=0;x<xs.length;x++) candidates.push({x:xs[x],y:ys[y],w:w,h:h});
    var safe=candidates.filter(function(c){return c.x>=0 && c.y>=0 && c.x+c.w<=width && c.y+c.h<=height && !windows.some(function(win){return intersects(c,win);});});
    return safe.length ? {available:true,x:safe[variant%safe.length].x,y:safe[variant%safe.length].y} : {available:false,x:18,y:56};
}
