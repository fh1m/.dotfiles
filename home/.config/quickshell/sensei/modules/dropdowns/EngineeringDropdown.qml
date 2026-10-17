import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.services
DropdownFrame {
 id:root;property string outputName:"";property bool instrument:false;title:"Engineering / projects & jobs";implicitWidth:740
 IpcHandler {target:"engineering-"+root.outputName+(root.instrument?"-instrument":"");function state():string{return JSON.stringify({host:root.targetHost,projects:root.snapshot.projects.length,jobs:root.snapshot.jobs.length,busy:worker.running,prepared:!!root.prepared.confirmation,report:root.report});}function openOn(output:string):void{if(ShellState.screens.some(s=>s.name===output)){ShellState.openDropdownOn("engineering",output);}}}
 property string targetHost:root.instrument&&ShellState.instrumentHost?ShellState.instrumentHost:MachineProfile.desktop?"homie":"arete"
 property var snapshot:({projects:[],jobs:[],hardware:[]})
 property int projectIndex:0
 readonly property var project:snapshot.projects?.[projectIndex]||({})
 property var prepared:({})
 property bool healthy:true
 property double updatedAt:0
 property string report:"Choose a project and a reviewed task. Host choice is always explicit."
 property int page:root.instrument?ShellState.instrumentPage:0
 property string operation:""
 property var deferred:[]
 readonly property var origin:ShellState.screens.find(s=>s.name===root.outputName)||ShellState.screens[0]
 function request(args,verb){if(worker.running)return;operation=verb;worker.command=[Quickshell.env("HOME")+"/.local/bin/sensei-actions","--host",targetHost].concat(args);worker.running=true;}
 function refresh(){request(["overview"],"overview");}
 function action(name,params){prepared={};request(["prepare",name,"--params",JSON.stringify(params)],"prepare");}
 Connections {target:Den;function onOnlineChanged(){if(root.active)root.refresh();}}
 Component.onCompleted:{if(ShellState.engineeringSelectedAction){report="Selected action: "+ShellState.engineeringSelectedAction+". Choose the project and confirm its exact parameters below.";ShellState.engineeringSelectedAction="";}refresh();}
 readonly property bool active:root.instrument?ShellState.instrumentPinned&&ShellState.instrumentKind==="engineering":ShellState.dropdown==="engineering"&&ShellState.dropdownOriginScreen===root.outputName
 onActiveChanged:if(active)refresh()
 Timer {interval:3000;repeat:true;running:root.active&&root.healthy&&(root.snapshot.jobs||[]).some(j=>["queued","running"].includes(j.state));onTriggered:root.refresh()}
 Process {id:worker;onExited:if(root.deferred.length){const next=root.deferred;root.deferred=[];root.request(next,"run");}stdout:StdioCollector {onStreamFinished:{try{const row=JSON.parse(text);if(row.error){root.healthy=false;root.report=row.error;root.prepared={};return;}if(root.operation==="overview"){root.healthy=true;root.updatedAt=Date.now();root.snapshot=row;if(root.instrument&&ShellState.instrumentProject)root.projectIndex=Math.max(0,row.projects.findIndex(p=>p.id===ShellState.instrumentProject));root.projectIndex=Math.min(root.projectIndex,Math.max(0,row.projects.length-1));if(ShellState.engineeringSelectedJob){root.deferred=["run","job.logs","--params",JSON.stringify({id:ShellState.engineeringSelectedJob})];ShellState.engineeringSelectedJob="";}}else if(root.operation==="prepare"){if(row.confirmation){root.prepared=row;root.report="Review: "+JSON.stringify(row.plan);}else root.deferred=["run",row.plan.action,"--params",JSON.stringify(row.plan.params)];}else{root.report=JSON.stringify(row);root.prepared={};}}catch(e){root.report="Invalid or unavailable backend response";}}}}
 ScrollView {id:engineeringScroll;width:parent.width;height:Math.max(200,Math.min(680,(root.origin?.height??1080)-170));contentWidth:availableWidth;contentHeight:engineeringBody.implicitHeight;clip:true
 Column {id:engineeringBody;width:engineeringScroll.availableWidth;spacing:10
  Row {spacing:8
   ControlTile {label:ShellState.instrumentPinned?"Return from instrument":"Pin on ScreenPad";onActivated:{if(ShellState.instrumentPinned)ShellState.releaseInstrument();else{ShellState.instrumentPage=root.page;ShellState.instrumentProject=root.project.id||"";ShellState.instrumentHost=root.targetHost;ShellState.pinInstrument("engineering");}}}
   ControlTile {label:"Projects / queue";selected:root.page===0;onActivated:root.page=0}
   ControlTile {label:"Zondo";selected:root.page===2;onActivated:root.page=2}
   ControlTile {label:"Hardware";selected:root.page===1;onActivated:root.page=1}
  }
  ZondoPlayground {width:parent.width;visible:root.page===2}
  Column {width:parent.width;visible:root.page===1;spacing:8
   DeskComboBox {id:hardwareNode;width:parent.width;model:root.snapshot.availableHardware||[];textRole:"node"}
   Row {width:parent.width;spacing:8
    DeskTextField {id:hardwareId;width:(parent.width-8)/2;placeholderText:"Stable ID, e.g. imu-adapter";maximumLength:80}
    DeskTextField {id:hardwareLabel;width:(parent.width-8)/2;placeholderText:"Friendly device name";maximumLength:120}
   }
   ControlTile {label:"Register passport…";enabled:hardwareId.text.trim()!==""&&hardwareLabel.text.trim()!==""&&hardwareNode.currentIndex>=0&&!worker.running;onActivated:root.action("hardware.register",{id:hardwareId.text.trim(),label:hardwareLabel.text.trim(),node:root.snapshot.availableHardware[hardwareNode.currentIndex].node})}

   Repeater {model:root.snapshot.hardware||[]
    Text {required property var modelData;width:parent.width;text:(modelData.label||modelData.id)+" · "+(modelData.ambiguous?"Ambiguous identity":modelData.connected?"Connected":"Disconnected")+" · "+(modelData.project||"No project")+"\n"+(modelData.nodes||[]).map(n=>n.node).join(", ");wrapMode:Text.Wrap;textFormat:Text.PlainText;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paper}
   }
   Text {width:parent.width;visible:!root.snapshot.hardware?.length;text:"Register a connected device with sensei-hardware register ID --node /dev/… --label NAME. No board is opened or flashed.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paperMuted}
  }
  Row {width:parent.width;spacing:8
   DeskComboBox {width:180;model:["arete","homie"];currentIndex:root.targetHost==="homie"?1:0;onActivated:{root.targetHost=currentIndex===1?"homie":"arete";root.prepared={};root.snapshot={projects:[],jobs:[],hardware:[]};root.refresh();}}
   ControlTile {label:"Refresh";glyph:"\uf021";enabled:!worker.running;onActivated:root.refresh()}
  }
  DeskComboBox {width:parent.width;model:root.snapshot.projects||[];textRole:"title";onActivated:index=>{root.projectIndex=index;root.prepared={};}}
  Row {spacing:8
   ControlTile {label:"Preflight";enabled:!!root.project.id&&!worker.running;onActivated:root.action("project.preflight",{project:root.project.id})}
   ControlTile {label:"Open project";enabled:!!root.project.id&&!worker.running;onActivated:root.action("project.open",{project:root.project.id})}
  }
  Text {width:parent.width;visible:!root.project.id;text:"No registered projects on this host. Register an existing checkout with sensei-actions register PROJECT DIRECTORY; add named task definitions and review them with sensei-actions trust.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paperMuted}
  Flow {width:parent.width;spacing:8
   Repeater {model:Object.keys(root.project.tasks||{})
    ControlTile {required property string modelData;label:modelData;enabled:!worker.running;onActivated:root.action("job.launch",{project:root.project.id,task:modelData})}
   }
  }
  Flow {width:parent.width;spacing:8
   Repeater {model:Object.keys(root.project.environments||{})
    Row {required property string modelData;spacing:6
     ControlTile {label:modelData+" preflight";enabled:!worker.running;onActivated:root.action("environment.preflight",{project:root.project.id,environment:modelData})}
     ControlTile {label:"ROS graph";enabled:!worker.running;onActivated:root.action("ros.health",{project:root.project.id,environment:modelData})}
    }
   }
  }
  Text {width:parent.width;text:root.report;textFormat:Text.PlainText;wrapMode:Text.Wrap;maximumLineCount:5;elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paper}
  Row {visible:!!root.prepared.confirmation;spacing:8
   ControlTile {label:"Confirm on "+root.targetHost;selected:true;enabled:!worker.running;onActivated:root.request(["run",root.prepared.plan.action,"--params",JSON.stringify(root.prepared.plan.params),"--confirmation",root.prepared.confirmation],"run")}
   ControlTile {label:"Cancel";onActivated:root.prepared={}}
  }
  Text {text:"JOB RECEIPTS / "+root.targetHost+(root.healthy?"":" · STALE / UNAVAILABLE");font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.signalRed}
  ScrollView {id:jobScroll;visible:root.page===0;width:parent.width;height:Math.max(100,Math.min(320,(root.origin?.height??1080)-420));contentWidth:availableWidth;contentHeight:jobRows.implicitHeight;clip:true
   Column {id:jobRows;width:jobScroll.availableWidth;spacing:8
    Repeater {model:(root.snapshot.jobs||[]).slice().reverse()
     Rectangle {required property var modelData;width:jobRows.width;height:100;radius:6;color:Theme.surfaceOne;border.color:Theme.rule
      Column {anchors.fill:parent;anchors.margins:8;spacing:4
       Text {width:parent.width;text:modelData.id+" · "+modelData.state;textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:12;color:modelData.state==="failed"?Theme.signalRed:Theme.paper}
       Text {width:parent.width;text:(modelData.command||[]).join(" ");textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.paperMuted}
       Text {text:"Inputs "+(modelData.inputs||[]).length+" · Artifacts "+(modelData.artifacts||[]).length+" · Unit "+(modelData.unitState||"unknown");font.family:Appearance.font.ui;font.pixelSize:10;color:Theme.paperMuted}
       Row {spacing:6
        ControlTile {implicitHeight:24;label:"Log";onActivated:root.action("job.logs",{id:modelData.id})}
        ControlTile {implicitHeight:24;label:"Artifacts";onActivated:root.action("job.artifacts",{id:modelData.id})}
        ControlTile {implicitHeight:24;visible:["queued","running"].includes(modelData.state);label:"Cancel…";onActivated:root.action("job.cancel",{id:modelData.id})}
       }
      }
     }
    }
   }
  }
 }
 }
}
