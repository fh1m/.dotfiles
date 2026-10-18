function intersects(a,b) { return a.x<b.x+b.w && a.x+a.w>b.x && a.y<b.y+b.h && a.y+a.h>b.y; }
// Dialogue reserves the character footprint and prefers a nearby safe position.
function place(width,height,w,h,pet,pw,ph,windows) {
    var body={x:pet.x-10,y:pet.y-10,w:pw+20,h:ph+20};
    var xs=[pet.x+(pw-w)/2,pet.x+pw+14,pet.x-w-14];
    var ys=[pet.y-h-14,pet.y+(ph-h)/2,pet.y+ph+14];
    for(var yi=0;yi<ys.length;yi++)for(var xi=0;xi<xs.length;xi++) {
        var c={x:Math.max(12,Math.min(width-w-12,xs[xi])),y:Math.max(52,Math.min(height-h-52,ys[yi])),w:w,h:h};
        if(!intersects(c,body)&&!windows.some(function(win){return intersects(c,win);}))return {available:true,x:c.x,y:c.y};
    }
    return {available:false,x:12,y:52};
}
