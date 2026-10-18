import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.services
Column {
 id:root;spacing:12
 property var snapshot:({profile:{},displays:[]});property string error:"";property bool testing:false
 function run(args){if(worker.running)return;worker.command=[Quickshell.env("HOME")+"/.local/bin/sensei-draw"].concat(args);worker.running=true;}
 function edit(data){run(["set",JSON.stringify(data)]);}
 Component.onCompleted:run(["status"])
 WidgetSection {width:parent.width;title:"Pen & paper";subtitle:root.snapshot.connected?root.snapshot.model:"Connect a drawing tablet · notes still work";glyph:"\uf040"
  Flow {width:parent.width;spacing:8
   ControlTile {implicitWidth:(parent.width-16)/3;label:"Focus mode";detail:"Toggle · F11";glyph:"\uf065";onActivated:root.run(["focus"])}
   ControlTile {implicitWidth:(parent.width-16)/3;label:"Scratchpad";detail:"Native ink · resume";glyph:"\uf040";onActivated:root.run(["quick"])}
   ControlTile {implicitWidth:(parent.width-16)/3;label:"New sheet";glyph:"\uf067";onActivated:root.run(["quick","--new"])}
   ControlTile {implicitWidth:(parent.width-16)/3;label:"Learning sketch";glyph:"\uf040";onActivated:root.run(["learn"])}
   ControlTile {implicitWidth:(parent.width-16)/3;label:"Typed capture";glyph:"\uf11c";onActivated:root.run(["typed"])}
   ControlTile {implicitWidth:(parent.width-16)/3;label:"Attach to Noesis";detail:"Current saved sheet";glyph:"\uf0c1";onActivated:root.run(["attach"])}
   ControlTile {implicitWidth:(parent.width-16)/3;label:"Art studio";glyph:"\uf1fc";onActivated:Quickshell.execDetached(["krita"])}
  }
 }
 WidgetSection {width:parent.width;visible:root.snapshot.connected===true;title:"Tablet mapping";subtitle:root.snapshot.driver?(root.snapshot.mappedOutput+(root.snapshot.fallback?" · Upper absent, using Main":" · Artist Mode")):"Driver unavailable";glyph:"\uf26c"
  Column {width:parent.width;spacing:10
   Flow {width:parent.width;spacing:6
    Repeater {model:root.snapshot.displays||[]
     ControlTile {required property var modelData;implicitWidth:110;label:modelData.role;selected:root.snapshot.profile.output===modelData.role;onActivated:root.edit({output:modelData.role})}
    }
   }
   Row {width:parent.width;spacing:8
    ControlTile {implicitWidth:(parent.width-16)/3;label:root.snapshot.profile.aspect?"Aspect locked":"Full area";selected:root.snapshot.profile.aspect===true;onActivated:root.edit({aspect:!root.snapshot.profile.aspect})}
    ControlTile {implicitWidth:(parent.width-16)/3;label:"Rotate · "+(root.snapshot.profile.rotation||0)+"°";onActivated:root.edit({rotation:((root.snapshot.profile.rotation||0)+90)%360})}
    ControlTile {implicitWidth:(parent.width-16)/3;label:root.testing?"Close pen test":"Test pressure";selected:root.testing;onActivated:root.testing=!root.testing}
   }
   Rectangle {width:parent.width;height:66;color:Theme.surfaceOne;border.color:Theme.rule;radius:5
    Rectangle {anchors.centerIn:parent;width:Math.min(parent.width-40,240);height:52;color:Theme.ink;border.color:Theme.widgetMuted
     Rectangle {anchors.centerIn:parent;width:parent.width; height:parent.height*((root.snapshot.area?.Height||152.4)/152.4);color:"#22f23d70";border.color:Theme.widgetAccent}
    }
    Text {anchors.centerIn:parent;text:(root.snapshot.area?.Width||0).toFixed(1)+" × "+(root.snapshot.area?.Height||0).toFixed(1)+" mm";font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetText}
   }
   ControlSlider {width:parent.width;title:"Tip activation · %";maximum:20;level:root.snapshot.profile.threshold??1;onEdited:value=>root.edit({threshold:Math.round(value)})}
   Text {width:parent.width;text:"Buttons apply only in drawing apps. Pressure curves remain app-owned; no hidden smoothing.";wrapMode:Text.Wrap;color:Theme.widgetMuted;font.family:Appearance.font.ui;font.pixelSize:11}
   Repeater {model:4
    Row {required property int index;width:parent.width;spacing:8
     Text {width:64;anchors.verticalCenter:parent.verticalCenter;text:"Key "+(parent.index+1);color:Theme.widgetMuted;font.family:Appearance.font.ui;font.pixelSize:12}
     DeskComboBox {width:parent.width-72;model:["undo","redo","eraser","pan","none"];currentIndex:Math.max(0,model.indexOf(root.snapshot.profile.buttons?.[parent.index]||"none"));onActivated:{let buttons=(root.snapshot.profile.buttons||["undo","redo","eraser","pan"]).slice();buttons[parent.index]=model[currentIndex];root.edit({buttons:buttons});}}
    }
   }
  }
 }
 Rectangle {id:pad;width:parent.width;height:root.testing?170:0;visible:root.testing;color:Theme.ink;border.color:Theme.rule;radius:6
  property var points:[];property real pressure:0;property int samples:0
  Canvas {id:ink;anchors.fill:parent;onPaint:{const c=getContext("2d");c.clearRect(0,0,width,height);const p=pad.points;for(let i=1;i<p.length;i++){if(p[i].start)continue;c.beginPath();c.moveTo(p[i-1].x,p[i-1].y);c.lineTo(p[i].x,p[i].y);c.lineWidth=1+p[i].p*7;c.strokeStyle="#f23d70";c.lineCap="round";c.stroke();}}}
  PointHandler {acceptedDevices:PointerDevice.Stylus|PointerDevice.Airbrush;onActiveChanged:if(active)pad.points=pad.points.concat([{x:point.position.x,y:point.position.y,p:point.pressure,start:true}]);onPointChanged:if(active){pad.pressure=point.pressure;pad.samples++;pad.points=pad.points.concat([{x:point.position.x,y:point.position.y,p:point.pressure}]).slice(-2000);ink.requestPaint();}}
  Text {anchors {left:parent.left;top:parent.top;margins:10}text:"PEN TEST · "+Math.round(pad.pressure*100)+"% · "+pad.samples+" samples · memory only";font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
 }
 Row {spacing:8;ControlTile {implicitWidth:100;label:"Refresh";enabled:!worker.running;onActivated:root.run(["status"])}ControlTile {implicitWidth:160;label:"Restore defaults";enabled:!worker.running;onActivated:root.edit({output:"upper",aspect:true,rotation:0,threshold:1,buttons:["undo","redo","eraser","pan"]})}}
 Text {width:parent.width;text:root.error;visible:text.length>0;wrapMode:Text.Wrap;color:Theme.widgetAccent;font.family:Appearance.font.ui;font.pixelSize:12}
 Process {id:worker;stdout:StdioCollector {onStreamFinished:{try{const d=JSON.parse(text);if(d.error)root.error=d.error;else{root.error=d.path?"Saved · "+d.path:d.preview?"Linked · "+d.preview:"";if(d.profile)root.snapshot=d;}}catch(e){root.error="Drawing action did not return a valid receipt.";}}}}
}
