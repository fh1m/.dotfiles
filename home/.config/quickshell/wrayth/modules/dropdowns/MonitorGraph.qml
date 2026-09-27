import QtQuick
import qs.config
Canvas {
 id:root
 property var values:[]
 property color ink:Theme.widgetAccent
 onValuesChanged:requestPaint()
 onInkChanged:requestPaint()
 onPaint: {let c=getContext('2d');c.reset();c.strokeStyle=Theme.alpha(Theme.widgetBorder,.6);c.lineWidth=1;for(let i=1;i<4;i++){c.beginPath();c.moveTo(0,height*i/4);c.lineTo(width,height*i/4);c.stroke();}if(values.length<2)return;c.beginPath();let n=180;for(let i=0;i<values.length;i++){let x=width*(n-values.length+i)/(n-1),y=height-2-(height-4)*Math.min(100,values[i])/100;if(i===0)c.moveTo(x,y);else c.lineTo(x,y);}c.strokeStyle=ink;c.lineWidth=2;c.stroke();c.lineTo(width,height);c.lineTo(width*(n-values.length)/(n-1),height);c.closePath();c.fillStyle=Theme.alpha(ink,.13);c.fill(); }
}
