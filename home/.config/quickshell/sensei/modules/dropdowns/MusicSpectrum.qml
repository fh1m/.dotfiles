import QtQuick
import qs.config
import qs.services

// One shared CAVA analyzer. A bounded 30 Hz painter interpolates real bands;
// no second audio capture, generated beat, or animation while hidden/idle.
Item {
 id:root
 property bool enabledSpectrum:SpotifyDesk.spectrumEnabled
 property color accent:Theme.widgetAccent
 readonly property bool activeView:visible&&enabledSpectrum&&SpotifyDesk.playing
 property var levels:[]
 property var smoothLevels:[]
 property var peaks:[]
 property int decay:0
 onActiveViewChanged:{levels=activeView?Cava.levels:[];if(!activeView){smoothLevels=[];peaks=[];plot.requestPaint();}}
 Connections {target:Cava;function onLevelsChanged(){if(root.activeView){root.levels=Cava.levels;root.decay=24;}}}
 Timer {interval:33;repeat:true;running:root.activeView&&(Cava.live||root.decay>0);onTriggered:{
  let values=[],tops=[];
  for(let i=0;i<48;i++){const target=Math.max(0,Math.min(1,Number(root.levels[i])||0)),previous=root.smoothLevels[i]||0,value=previous+(target-previous)*(target>previous?.55:.15);values.push(value);tops.push(Math.max(value,(root.peaks[i]||0)-.013));}
  root.smoothLevels=values;root.peaks=tops;root.decay=Math.max(0,root.decay-1);plot.requestPaint();
 }}
 Canvas {id:plot;anchors.fill:parent;onPaint:{
  const c=getContext('2d'),w=width,h=height;c.clearRect(0,0,w,h);if(w<1||h<1)return;
  c.strokeStyle=Theme.alpha(root.accent,.12);c.lineWidth=1;
  for(let j=1;j<4;j++){c.beginPath();c.moveTo(0,h*j/4);c.lineTo(w,h*j/4);c.stroke();}
  const xs=i=>i*w/47,ys=i=>h-2-(root.smoothLevels[i]||0)*(h-5);
  c.beginPath();c.moveTo(0,h);c.lineTo(0,ys(0));
  for(let i=0;i<47;i++)c.quadraticCurveTo(xs(i),ys(i),(xs(i)+xs(i+1))/2,(ys(i)+ys(i+1))/2);
  c.lineTo(w,ys(47));c.lineTo(w,h);c.closePath();
  const gradient=c.createLinearGradient(0,0,0,h);gradient.addColorStop(0,Theme.alpha(root.accent,.55));gradient.addColorStop(1,Theme.alpha(root.accent,.025));c.fillStyle=gradient;c.fill();
  c.beginPath();c.moveTo(0,ys(0));for(let i=0;i<47;i++)c.quadraticCurveTo(xs(i),ys(i),(xs(i)+xs(i+1))/2,(ys(i)+ys(i+1))/2);c.lineTo(w,ys(47));c.strokeStyle=root.accent;c.lineWidth=1.6;c.stroke();
  c.fillStyle=Theme.alpha(Theme.paper,.55);for(let i=0;i<48;i+=2){const p=root.peaks[i]||0;if(p>.04)c.fillRect(xs(i),h-2-p*(h-5),2,1);}
 }}
}
