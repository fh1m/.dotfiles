// Pure local guest policy. No generated dialogue is attributed as a real quotation.
var introduction='Zondo as Sensei of fh1m, I have a message for Him';
function paginate(text, limit) {
    var words=String(text||'').trim().split(/\s+/),out=[],line='';
    words.forEach(function(word){
        if(line&&line.length+word.length+1>limit){out.push(line);line='';}
        // Data validation bounds tokens; splitting keeps arbitrary input safe too.
        while(word.length>limit){if(line){out.push(line);line='';}out.push(word.slice(0,limit));word=word.slice(limit);}
        if(word)line+=(line?' ':'')+word;
    });
    if(line)out.push(line);
    return out;
}
function pages(guest, quote) {
    var out=[{speaker:guest.name,kind:'staged dialogue',text:introduction,source:''}];
    function add(text,speaker,kind,source){paginate(text,220).forEach(function(t){out.push({speaker:speaker,kind:kind,text:t,source:source||''});});}
    add(quote.text,guest.name,'quotation',quote.source);
    add(quote.context,'Reading together','context · our reading',quote.source);
    add(guest.story,'About '+guest.name,'life & work · summary',guest.storySource||quote.source);
    add(quote.question,'Zondo','a question for us',quote.source);
    return out;
}
function choose(guests, history, requested, random) {
    var candidates=guests.map(function(g,i){return i;});
    if(requested){candidates=candidates.filter(function(i){return guests[i].id===requested;});if(!candidates.length)return null;}
    else if(candidates.length>1)candidates=candidates.filter(function(i){return guests[i].id!==history.guest;});
    if(!candidates.length)return null;
    var g=candidates[Math.min(candidates.length-1,Math.floor(Math.max(0,random)*candidates.length))];
    var recent=history.quotes||[],qs=guests[g].quotes||[],available=qs.map(function(q,i){return i;}).filter(function(i){return recent.indexOf(qs[i].id)<0;});
    if(!available.length)available=qs.map(function(q,i){return i;}).filter(function(i){return qs.length===1||qs[i].id!==recent[recent.length-1];});
    if(!available.length)return null;
    return {guest:g,quote:available[Math.min(available.length-1,Math.floor(Math.max(0,random)*available.length))]};
}
function duration(page) {
    return Math.max(7000,Math.min(22000,3500+String(page.text||'').split(/\s+/).length*300));
}
function intersects(a,b) {return a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y;}
function place(width,height,w,h,obstacles,variant) {
    if(w>width-24||h>height-100)return {available:false,x:12,y:52};
    var xs=[(width-w)/2,12,width-w-12],ys=[height-h-48,52,(height-h)/2];
    for(var n=0;n<9;n++){
        var i=(n+variant)%9,c={x:Math.round(xs[i%3]),y:Math.round(ys[Math.floor(i/3)]),w:w,h:h};
        if(c.y>=52&&c.y+h<=height-48&&!obstacles.some(function(o){return intersects(c,o);}))return {available:true,x:c.x,y:c.y};
    }
    return {available:false,x:12,y:52};
}
