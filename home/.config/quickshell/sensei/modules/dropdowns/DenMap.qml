import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
Column {
 id:root;width:parent.width;spacing:10;property var snapshot:({outputs:[],geometry:{homie:{x:960,y:-1080,width:1920,height:1080}}});property int px:960;property int py:-1080;property string status:"Physical map · Homie is a separate computer. Drag its display; Apply safely releases input first."
 function run(args){if(worker.running)return;worker.command=[Quickshell.env("HOME")+"/.local/bin/sensei-den-layout"].concat(args);worker.running=true;}
 Component.onCompleted:run(["list"])
 Rectangle {id:map;width:parent.width;height:220;color:Theme.surfaceOne;border.color:Theme.rule;radius:6
  readonly property real factor:Math.min((width-32)/Math.max(5760,root.px+root.snapshot.geometry.homie.width+1920),(height-24)/3240)
  Repeater {model:root.snapshot.outputs
   Rectangle {required property var modelData;x:16+(modelData.x+1920)*map.factor;y:12+(modelData.y+1080)*map.factor;width:modelData.width/modelData.scale*map.factor;height:modelData.height/modelData.scale*map.factor;color:Theme.ink;border.color:Theme.rule;radius:3
    Text {anchors.centerIn:parent;text:modelData.name;font.family:Appearance.font.ui;font.pixelSize:9;color:Theme.widgetMuted}
   }
  }
  Rectangle {id:peer;x:16+(root.px+1920)*map.factor;y:12+(root.py+1080)*map.factor;width:root.snapshot.geometry.homie.width*map.factor;height:root.snapshot.geometry.homie.height*map.factor;color:Theme.surfaceTwo;border.color:Theme.signalRed;radius:3
   Text {anchors.centerIn:parent;text:"HOMIE";font.family:Appearance.font.ui;font.pixelSize:10;color:Theme.widgetText}
   MouseArea {anchors.fill:parent;drag.target:peer;onReleased:{root.px=Math.round(((peer.x-16)/map.factor-1920)/16)*16;root.py=Math.round(((peer.y-12)/map.factor-1080)/16)*16;if(Math.abs(root.py+root.snapshot.geometry.homie.height)<80)root.py=-root.snapshot.geometry.homie.height;}}
  }
 }
 Text {width:parent.width;text:root.status+"\nHomie: "+root.px+", "+root.py+" · Upper ↔ Homie remains an explicit side link.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
 Row {spacing:8
  ControlTile {label:"Apply Den map";enabled:!worker.running;onActivated:root.run(["save","--x",String(root.px),"--y",String(root.py)])}
  ControlTile {label:"Top / middle-right";enabled:!worker.running;onActivated:{root.px=960;root.py=-1080;}}
 }
 Process {id:worker;stdout:StdioCollector {onStreamFinished:{try{const r=JSON.parse(text);if(r.error)root.status=r.error;else{if(r.outputs)root.snapshot=r;root.px=r.geometry.homie.x;root.py=r.geometry.homie.y;if(r.note)root.status=r.note;}}catch(e){root.status="Physical map unavailable. Existing input settings retained.";}}}}
}
