import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.services

Item {
 id:root
 property string section:Oasis.workspace
 property var selected:({})
 property var rows:[]
 property var history:[]
 property string activeAttempt:""
 property string captureSubmission:""
 property var relations:[]
 property string body:""
 property string query:""
 property string cursor:""
 property int serial:0
 property int latest:0
 property int detailSerial:0
 property int historySerial:0
 property int relationSerial:0
 property var changedPaths:[]
 property bool reconcileAll:false
 property bool referenceHidden:false
 readonly property bool coreRunning:worker.running
 readonly property bool watchRunning:watch.running
 readonly property int previewLength:body.length
 readonly property var sections:["Today","Learn","Research","Practice","Lab","Library"]
 readonly property var kinds:({Learn:["path","course","resource","unit","capability","prerequisite"],Research:["paper","resource","question"],Practice:["task","problem","session","practice-session"],Lab:["project","experiment","lab","artifact"]})
 function send(action,extra){
  if(!worker.running||!Oasis.activeVault)return 0;
  let request=Object.assign({version:1,request_id:++serial,vault:Oasis.activeVault,action:action},extra||{});
  worker.write(JSON.stringify(request)+"\n");return request.request_id;
 }
 function load(append){latest=send(section==="Today"&&!query?"next":"query",{kind:kinds[section]||null,query:query,quiet:Oasis.quiet,cursor:append?Number(cursor):0});}
 function select(row){let changed=row.id!==selected.id;if(changed)activeAttempt="";selected=row;Oasis.currentContext=Object.assign({},row,{vault:Oasis.activeVault});Oasis.savePreferences();body="";history=[];relations=[];if(changed)referenceHidden=section==="Practice";if(row.id){detailSerial=send("record",{record_id:row.id});historySerial=send("timeline",{record_id:row.id});relationSerial=send("relations",{record_id:row.id});}else Oasis.preview(row.path);}
 function saveEvent(event,data){if(activeAttempt&&event!=="attempt-start")data.attempt_id=activeAttempt;Oasis.run(["event",selected.path,event,"--target-id",selected.id,"--evidence",evidence.text,"--data",JSON.stringify(data)]);}
 onSectionChanged:{Oasis.workspace=section;Oasis.savePreferences();selected=({});history=[];relations=[];detailSerial=0;historySerial=0;relationSerial=0;body="";query="";search.text="";load(false);}
 Component.onCompleted:watch.running=Oasis.windowOpen&&Oasis.activeVault!==""
 Connections {target:Oasis;
  function onWindowOpenChanged(){watch.running=Oasis.windowOpen&&Oasis.activeVault!=="";}
  function onCaptureRequested(){capture.forceActiveFocus();}
  function onActiveVaultChanged(){watch.running=false;refresh.stop();root.changedPaths=[];root.reconcileAll=false;Qt.callLater(()=>watch.running=Oasis.windowOpen&&Oasis.activeVault!=="");root.rows=[];root.selected=({});root.body="";root.history=[];root.detailSerial=0;root.historySerial=0;root.relationSerial=0;if(worker.running)root.send("reconcile");}
  function onFinished(ok){if(ok){if(Oasis.operationResult.event==="attempt-start"){root.activeAttempt=Oasis.operationResult.id;root.referenceHidden=true;}else if(Oasis.operationResult.event==="attempt")root.activeAttempt="";root.send("reconcile");if(root.selected.id)root.select(root.selected);}}
 }
 Process {
  id:worker;command:["@HOME@/.local/bin/noesis","serve","--stdio"];stdinEnabled:true;running:Oasis.windowOpen
  onStarted:{root.send("reconcile");if(Oasis.currentContext.vault===Oasis.activeVault&&Oasis.currentContext.id)root.select(Oasis.currentContext);}
  stdout:SplitParser {onRead:line=>{
   try{
    let response=JSON.parse(line);if(response.vault&&response.vault!==Oasis.activeVault)return;
    if(response.error){Oasis.error=response.error;return;}
    let result=response.result;
    if(result.errors){if(result.errors.length)Oasis.error=JSON.stringify(result.errors);root.load(false);return;}
    if(response.request_id===root.latest){root.rows=result.records||[];root.cursor=result.cursor===null||result.cursor===undefined?"":String(result.cursor);}
    if(response.request_id===root.detailSerial){root.body=result.body||"";root.selected=Object.assign({},root.selected,result.props||{});Oasis.currentContext=Object.assign({},root.selected,{vault:Oasis.activeVault,session_state:result.state?.status||""});Oasis.savePreferences();position.text=result.state?.position||"";if(result.state?.conflict)Oasis.error=result.state.conflict;}
    if(response.request_id===root.historySerial)root.history=result.activities||[];
    if(response.request_id===root.relationSerial)root.relations=result.relationships||[];
   }catch(error){Oasis.error="Query response failed: "+String(error);}
  }}
  stderr:StdioCollector {onStreamFinished:if(text.trim())Oasis.error=text.trim()}
 }
 Process {id:watch;command:["@HOME@/.local/bin/sensei-learning-watch",Oasis.activeVault];stdout:SplitParser {onRead:line=>{
  try{let event=JSON.parse(line);root.reconcileAll=root.reconcileAll||event.reconcile;root.changedPaths=Array.from(new Set(root.changedPaths.concat(event.paths||[])));}
  catch(error){Oasis.error=line;root.reconcileAll=true;}
  refresh.restart();
 }}}
 Timer {id:refresh;interval:250;onTriggered:{root.send("reconcile",{paths:root.reconcileAll||root.changedPaths.length>1000?null:root.changedPaths});root.changedPaths=[];root.reconcileAll=false;}}
 Timer {id:searchDelay;interval:150;onTriggered:root.load(false)}
 Shortcut {sequence:"Ctrl+K";onActivated:search.forceActiveFocus()}
 Shortcut {sequence:"Ctrl+Shift+N";onActivated:capture.forceActiveFocus()}
 Shortcut {sequence:"Ctrl+1";onActivated:root.section="Today"}
 Shortcut {sequence:"Ctrl+2";onActivated:root.section="Learn"}
 Shortcut {sequence:"Ctrl+3";onActivated:root.section="Research"}
 Shortcut {sequence:"Ctrl+4";onActivated:root.section="Practice"}
 Shortcut {sequence:"Ctrl+5";onActivated:root.section="Lab"}
 Shortcut {sequence:"Ctrl+6";onActivated:root.section="Library"}
 RowLayout {
  anchors.fill:parent;anchors.margins:12;spacing:12
  ColumnLayout {Layout.preferredWidth:120;Layout.fillHeight:true
   Repeater {model:root.sections;delegate:NoesisButton {required property string modelData;text:modelData;Layout.fillWidth:true;highlighted:root.section===modelData;onClicked:root.section=modelData;Accessible.name:modelData+" workspace"}}
   Item {Layout.fillHeight:true}
   Label {text:"Vault scope";color:Theme.widgetMuted}
   DeskComboBox {Layout.fillWidth:true;model:(Oasis.state.vaults||[]).map(v=>v.name);currentIndex:(Oasis.state.vaults||[]).findIndex(v=>v.path===Oasis.activeVault);onActivated:{let v=Oasis.state.vaults[currentIndex];if(v)Oasis.choose(v.path);}}
  }
  ColumnLayout {Layout.minimumWidth:200;Layout.preferredWidth:Math.max(200,(root.width-168)*Oasis.listRatio);Layout.maximumWidth:Math.max(200,(root.width-168)*Oasis.listRatio);Layout.fillHeight:true
   DeskTextField {id:search;Layout.fillWidth:true;placeholderText:"Search "+root.section;onTextChanged:{root.query=text;searchDelay.restart();}Accessible.name:"Search learning records"}
   ListView {id:list;Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:root.rows;keyNavigationEnabled:true
    Keys.onReturnPressed:if(currentIndex>=0)root.select(root.rows[currentIndex])
    delegate:ItemDelegate {id:row;required property var modelData;required property int index;width:list.width;text:(modelData.title||modelData.path)+"\n"+(modelData.reason||modelData.type||"");highlighted:root.selected.path===modelData.path;onClicked:{list.currentIndex=index;root.select(modelData);}Accessible.name:text
     contentItem:Text {text:row.text;color:row.highlighted?Theme.widgetAccent:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:13;wrapMode:Text.Wrap;elide:Text.ElideRight}
     background:Rectangle {color:row.highlighted||row.hovered?Theme.widgetRaised:"transparent";border.width:row.activeFocus?1:0;border.color:Theme.widgetAccent}
    }
   }
   NoesisButton {visible:root.section==="Today";text:Oasis.quiet?"Show suggestions":"Quiet suggestions";onClicked:{Oasis.quiet=!Oasis.quiet;Oasis.savePreferences();root.load(false);}}
   NoesisButton {visible:root.cursor!=="";text:"Next 50";onClicked:root.load(true)}
   DeskTextArea {id:capture;Layout.fillWidth:true;Layout.preferredHeight:90;placeholderText:"Capture a thought…";Accessible.name:"Quick capture"}
   NoesisButton {text:"Capture";enabled:capture.text.trim()!==""&&!Oasis.working;onClicked:{root.captureSubmission=capture.text;Oasis.run(["capture",capture.text]);}}
   Connections {target:Oasis;function onFinished(ok){if(ok&&root.captureSubmission&&capture.text===root.captureSubmission)capture.text="";root.captureSubmission="";}}
  }
  Rectangle {Layout.preferredWidth:4;Layout.fillHeight:true;color:drag.containsMouse?Theme.widgetAccent:Theme.widgetBorder
   MouseArea {id:drag;anchors.fill:parent;cursorShape:Qt.SplitHCursor;property real startX:0;property real startRatio:0;onPressed:mouse=>{startX=mapToItem(root,mouse.x,mouse.y).x;startRatio=Oasis.listRatio;}onPositionChanged:mouse=>{if(pressed)Oasis.listRatio=Math.min(.6,Math.max(.2,startRatio+(mapToItem(root,mouse.x,mouse.y).x-startX)/Math.max(1,root.width-168)));}onReleased:Oasis.savePreferences()}
  }
  ColumnLayout {Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumWidth:0;visible:root.width>=720
   Label {text:root.selected.title||root.selected.path||"Select a working context";color:Theme.widgetAccent;wrapMode:Text.Wrap;Layout.fillWidth:true}
   Flow {Layout.fillWidth:true;spacing:6
    NoesisButton {text:"Open note";enabled:!!root.selected.path&&!root.referenceHidden;onClicked:Oasis.note(root.selected.path)}
    NoesisButton {text:"Reader";enabled:!root.referenceHidden;visible:["paper","resource","course"].includes(root.selected.type);onClicked:Oasis.run(["read-resource",root.selected.path,"--reader",root.selected.zotero_uri?"zotero":"sioyek"])}
    NoesisButton {text:root.referenceHidden?"Reveal reference":"Hide reference";enabled:!!root.selected.path;onClicked:{if(root.referenceHidden)root.saveEvent("assistance",{assistance:["reference"],scope:"Noesis preview"});root.referenceHidden=!root.referenceHidden;}}
   }
   ScrollView {Layout.fillWidth:true;Layout.fillHeight:true;clip:true
    TextArea {text:root.referenceHidden?"Reference hidden. Reconstruct before revealing.":root.body;readOnly:true;wrapMode:TextEdit.Wrap;color:Theme.widgetText;background:null;Accessible.name:"Record preview"}
   }
   Label {text:"Activity history · reported evidence";color:Theme.widgetMuted;visible:root.height>=600&&root.width>=1000}
   ListView {Layout.fillWidth:true;Layout.preferredHeight:Math.min(160,root.height*0.25,root.history.length*46);clip:true;model:root.history;visible:root.height>=600&&root.width>=1000
    delegate:Label {required property var modelData;width:ListView.view.width;text:modelData.event+" · "+(modelData.outcome||"")+" · "+(modelData.assistance||["unknown"]).join(", ")+"\n"+modelData.timestamp;color:Theme.widgetMuted;wrapMode:Text.Wrap}
   }
   ListView {Layout.fillWidth:true;Layout.preferredHeight:Math.min(100,root.relations.length*34);clip:true;model:root.relations;visible:root.relations.length>0&&root.height>=600&&!root.referenceHidden
    delegate:NoesisButton {required property var modelData;width:ListView.view.width;text:modelData.relation+(modelData.role?" · "+modelData.role:"")+" → "+(modelData.other_title||modelData.other_id);enabled:!!modelData.other_path;onClicked:root.select({id:modelData.other_id,path:modelData.other_path,title:modelData.other_title,type:modelData.other_type})}
   }
   DeskTextField {id:position;Layout.fillWidth:true;placeholderText:"Resume locator · page / unit / timestamp";visible:!!root.selected.id&&root.height>=600&&root.width>=1000}
   DeskTextArea {id:evidence;Layout.fillWidth:true;Layout.preferredHeight:70;placeholderText:"Actual reasoning / evidence / discrepancy";visible:!!root.selected.id&&root.height>=600&&root.width>=1000}
   RowLayout {visible:!!root.selected.id&&root.height>=600&&root.width>=1000
    DeskComboBox {id:mode;model:["pattern","interface","derive","build","transfer"];currentIndex:2;Layout.fillWidth:true}
    DeskComboBox {id:outcome;model:["unknown","incomplete","failed","partial","succeeded"];Layout.fillWidth:true}
    DeskComboBox {id:assistance;model:["unknown","none","hint","reference","collaborator","agent"];Layout.fillWidth:true}
   }
   RowLayout {visible:!!root.selected.id&&root.height>=600&&root.width>=1000
    NoesisButton {text:"Start attempt";enabled:!Oasis.working&&!root.activeAttempt;onClicked:root.saveEvent("attempt-start",{mode:mode.currentText,scope:root.selected.title||root.selected.path})}
    NoesisButton {text:"Save position";enabled:!Oasis.working;onClicked:root.saveEvent("study",{state:{position:position.text}})}
    NoesisButton {text:"Finalize attempt";enabled:!Oasis.working&&!!root.activeAttempt&&evidence.text.trim()!=="";onClicked:root.saveEvent("attempt",{outcome:outcome.currentText,assistance:[assistance.currentText],mode:mode.currentText,assessment:"learner-reported",scope:root.selected.title||root.selected.path})}
   }
   Label {text:Oasis.error||Oasis.message;color:Theme.widgetAccent;wrapMode:Text.Wrap;Layout.fillWidth:true}
  }
 }
}
