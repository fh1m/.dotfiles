import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.services
Column {
 id:root;width:parent.width;spacing:10
 property var actual:[]
 property var draft:[]
 property int selected:0
 property string operation:"list"
 property string token:""
 property double expires:0
 property double clock:Date.now()/1000
 property string status:"Drag screens, select a display, then Apply. Changes revert unless kept."
 readonly property var current:draft[selected]||({})
 function run(verb,args){if(worker.running)return;operation=verb;worker.command=[Quickshell.env("HOME")+"/.local/bin/sensei-display-layout",verb].concat(args||[]);worker.running=true;}
 function change(values){let rows=draft.map((r,i)=>i===selected?Object.assign({},r,values):r);draft=rows;}
 function refresh(){run("list",[]);}
 Component.onCompleted:refresh()
 Timer {interval:250;repeat:true;running:root.token!=="";onTriggered:{root.clock=Date.now()/1000;if(root.clock>root.expires+1){root.token="";root.refresh();}}}
 Process {id:worker;stdout:StdioCollector {onStreamFinished:{try{const j=JSON.parse(text);if(j.error){root.status=j.error;return;}if(root.operation==="list"){root.actual=j.outputs;root.draft=j.outputs.map(m=>({name:m.name,enabled:!m.disabled,x:m.x||0,y:m.y||0,scale:m.scale||1,transform:m.transform||0,mode:m.width+"x"+m.height+"@"+Number(m.refreshRate||60).toFixed(2),primary:m.name===MachineProfile.primaryOutput,mirror:typeof m.mirrorOf==="string"?m.mirrorOf:"none"}));if(j.pending?.token){root.token=j.pending.token;root.expires=j.pending.expires;}}else if(root.operation==="apply"){root.token=j.token;root.expires=j.expires;root.status="Keep this arrangement? Automatic rollback is armed.";}else{root.token="";root.status=j.kept?"Arrangement saved":"Previous arrangement restored";}}catch(e){root.status="Display backend unavailable";}}}}
 Rectangle {id:map;width:parent.width;height:190;radius:8;color:Theme.surfaceOne;border.color:Theme.rule
  readonly property real minX:Math.min(0,...root.actual.map(m=>m.x||0))
  readonly property real minY:Math.min(0,...root.actual.map(m=>m.y||0))
  readonly property real maxX:Math.max(1920,...root.actual.map(m=>(m.x||0)+m.width/(m.scale||1)))
  readonly property real maxY:Math.max(1080,...root.actual.map(m=>(m.y||0)+m.height/(m.scale||1)))
  readonly property real factor:Math.min((width-40)/(maxX-minX),(height-30)/(maxY-minY))
  Repeater {model:root.draft
   Rectangle {id:tile;required property var modelData;required property int index
    readonly property var original:root.actual.find(m=>m.name===modelData.name)||({width:1920,height:1080})
    x:20+(modelData.x-map.minX)*map.factor;y:15+(modelData.y-map.minY)*map.factor
    width:Math.max(38,original.width/modelData.scale*map.factor);height:Math.max(24,original.height/modelData.scale*map.factor);radius:4;color:root.selected===index?Theme.surfaceTwo:Theme.ink;opacity:modelData.enabled?1:.4;border.color:root.selected===index?Theme.signalRed:Theme.rule;border.width:1
    Text {anchors.centerIn:parent;text:(index+1)+" · "+tile.modelData.name;font.family:Appearance.font.ui;font.pixelSize:10;color:Theme.paper}
    MouseArea {anchors.fill:parent;drag.target:tile;enabled:root.token==="";onPressed:root.selected=tile.index;onReleased:{root.selected=tile.index;let x=Math.round(((tile.x-20)/map.factor+map.minX)/16)*16;let y=Math.round(((tile.y-15)/map.factor+map.minY)/16)*16;for(let i=0;i<root.draft.length;i++){if(i===tile.index)continue;const r=root.draft[i],m=root.actual[i];if(!m)continue;const edge=r.x+m.width/r.scale;if(Math.abs(x-edge)<40)x=Math.round(edge);const bottom=r.y+m.height/r.scale;if(Math.abs(y-bottom)<40)y=Math.round(bottom);}root.change({x:x,y:y});}}
   }
  }
 }
 ControlSlider {width:parent.width;title:(ExternalDisplays.display(root.current.name)?.control==="software"?"Software dimming · ":"Brightness · ")+(root.current.name||"display");glyph:"\uf185";level:root.current.name===MachineProfile.primaryOutput&&!MachineProfile.desktop?Brightness.value*100:MachineProfile.role(root.current.name)==="screenpad"?(RobotBench.data.brightness||0):(ExternalDisplays.display(root.current.name)?.level||0);onEdited:percent=>DisplayControls.setLevel(root.current.name===MachineProfile.primaryOutput?"main":MachineProfile.role(root.current.name)==="screenpad"?"screenpad":root.current.name,percent)}
 DeskComboBox {width:parent.width;model:root.draft;textRole:"name";currentIndex:root.selected;onActivated:index=>root.selected=index;enabled:root.token===""}
 Row {width:parent.width;spacing:8;enabled:root.token===""
  DeskComboBox {width:parent.width*.52;model:(root.actual[root.selected]?.availableModes||[]).map(s=>({value:s.replace("Hz",""),label:s.replace("x"," × ").replace("@"," · ")}));textRole:"label";currentIndex:Math.max(0,model.findIndex(m=>m.value===root.current.mode));onActivated:root.change({mode:model[currentIndex].value})}
  DeskComboBox {width:parent.width*.22;model:[1,1.25,1.5,1.75,2,2.5,3].map(v=>({value:v,label:Math.round(v*100)+"%"}));textRole:"label";currentIndex:Math.max(0,model.findIndex(m=>m.value===root.current.scale));onActivated:root.change({scale:model[currentIndex].value})}
  DeskComboBox {width:parent.width*.22-16;model:["Normal","90°","180°","270°"];currentIndex:Math.min(3,root.current.transform||0);onActivated:root.change({transform:currentIndex})}
 }
 Row {spacing:8;enabled:root.token===""
  ControlTile {label:root.current.enabled?"Enabled":"Disabled";selected:!!root.current.enabled;onActivated:root.change({enabled:!root.current.enabled})}
  ControlTile {label:root.current.primary?"Main display":"Use as main";selected:!!root.current.primary;enabled:MachineProfile.role(root.current.name)!=="screenpad";onActivated:root.draft=root.draft.map(r=>Object.assign({},r,{primary:r.name===root.current.name}))}
  DeskComboBox {width:200;model:["Join displays"].concat(root.draft.filter(r=>r.name!==root.current.name&&r.enabled).map(r=>r.name));onActivated:root.change({mirror:currentIndex===0?"none":model[currentIndex]})}
 }
 Text {width:parent.width;text:root.status;textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paperMuted}
 Row {spacing:8
  ControlTile {label:"Refresh";enabled:!worker.running&&root.token==="";onActivated:root.refresh()}
  ControlTile {label:"Apply layout";selected:true;enabled:!worker.running&&root.token===""&&root.draft.length>0;onActivated:root.run("apply",[JSON.stringify(root.draft)])}
  ControlTile {visible:root.token!=="";label:"Keep · "+Math.max(0,Math.ceil(root.expires-root.clock))+"s";selected:true;onActivated:root.run("confirm",[root.token])}
  ControlTile {visible:root.token!=="";label:"Revert";onActivated:root.run("rollback",[root.token])}
 }
}
