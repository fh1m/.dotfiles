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
// These lenses are our original prompts, never historical advice or quotations.
var lenses=[
 {id:'try',name:'Make it concrete',lead:'One small move: ',tail:' Keep the result, not just the intention.',question:'What did we actually make or notice?'},
 {id:'tiny',name:'The smallest version',lead:'Shrink this until it fits one sitting: ',tail:' One example is enough to begin.',question:'What is the smallest honest version of this?'},
 {id:'predict',name:'Prediction before hindsight',lead:'Before trying this, write what you expect: ',tail:' Compare that prediction with what happens.',question:'What would surprise us enough to revise the prediction?'},
 {id:'rival',name:'Give the rival a chance',lead:'Try this, then describe a competing explanation: ',tail:' Look for a detail that distinguishes the two.',question:'Which observation would tell the explanations apart?'},
 {id:'sketch',name:'Draw the invisible part',lead:'Make a rough sketch while you do this: ',tail:' Arrows, timing, relationships or a tiny storyboard will do.',question:'What became clearer when it had a shape?'},
 {id:'teach',name:'Teach the little deskbuddy',lead:'Try this, then explain it to Zondo without impressive vocabulary: ',tail:' He has excellent ears and no patience for hand-waving.',question:'Which step would I have to pretend to understand?'},
 {id:'limits',name:'Where the idea stops',lead:'Explore one limit while doing this: ',tail:' Change a condition, context or constraint. Keep the awkward result too.',question:'When would this useful idea become the wrong advice?'},
 {id:'transfer',name:'Take it somewhere else',lead:'Try this in a second medium, project or setting: ',tail:' Preserve the useful principle; change the surface.',question:'What transferred, and what only looked transferable?'},
 {id:'return',name:'A note to future fh1m',lead:'Return to this after a pause: ',tail:' Leave one artifact and the exact place to resume. No streak required.',question:'What could future us reconstruct without this card?'}
];
function entries(guest) {
    var result=(guest.quotes||[]).slice();
    (guest.topics||[]).forEach(function(t){
        result.push({id:t.id+'-story',kind:'story',title:t.title,text:t.story,question:t.question,context:t.task,source:t.source});
        lenses.forEach(function(l){result.push({id:t.id+'-'+l.id,kind:'workshop',title:t.title+' · '+l.name,text:l.lead+t.task+l.tail,question:l.question,context:t.story,source:t.source});});
    });
    return result;
}
function pages(guest, quote) {
    var out=[{speaker:guest.name,kind:'staged dialogue',text:introduction,source:''}];
    function add(text,speaker,kind,source){paginate(text,220).forEach(function(t){out.push({speaker:speaker,kind:kind,text:t,source:source||''});});}
    if(quote.kind==='story') {
        add(quote.title,'About '+guest.name,'reading trail · title',quote.source);
        add(quote.text,'About '+guest.name,'sourced story · our summary',quote.source);
        add(quote.context,'Zondo','our invitation · not their words',quote.source);
    } else if(quote.kind==='workshop') {
        add(quote.context,'About '+guest.name,'source context · our summary',quote.source);
        add(quote.text,'Zondo','workshop · our original exercise',quote.source);
    } else {
        add(quote.text,guest.name,'quotation',quote.source);
        add(quote.context,'Reading together','context · our reading',quote.source);
        add(guest.story,'About '+guest.name,'life & work · summary',guest.storySource||quote.source);
    }
    add(quote.question,'Zondo','a question for us',quote.source);
    return out;
}
function choose(guests, history, requested, random, mode) {
    var candidates=guests.map(function(g,i){return i;});
    if(requested){candidates=candidates.filter(function(i){return guests[i].id===requested;});if(!candidates.length)return null;}
    else if(candidates.length>1)candidates=candidates.filter(function(i){return guests[i].id!==history.guest;});
    if(!candidates.length)return null;
    var g=candidates[Math.min(candidates.length-1,Math.floor(Math.max(0,random)*candidates.length))];
    var recent=history.quotes||[],qs=entries(guests[g]);
    var family=['quotes','stories','workshop'].indexOf(mode)>=0?mode:(random<0.60?'quotes':random<0.80?'stories':'workshop');
    var pool=qs.map(function(q,i){return i;}).filter(function(i){return family==='quotes'?!qs[i].kind:family==='stories'?qs[i].kind==='story':qs[i].kind==='workshop';});
    if(!pool.length)pool=qs.map(function(q,i){return i;});
    var available=pool.filter(function(i){return recent.indexOf(qs[i].id)<0;});
    if(!available.length)available=pool.filter(function(i){return pool.length===1||qs[i].id!==recent[recent.length-1];});
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
