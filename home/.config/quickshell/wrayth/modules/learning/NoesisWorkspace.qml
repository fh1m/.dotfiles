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
 property var home:({})
 property bool loading:false
 property bool contextLoading:false
 property bool inspectorOpen:false
 property string contextTab:"Read"
 property var navigation:[]
 property int navigationIndex:-1
 property var selected:({})
 property string selectedVault:""
 property var rows:[]
 property var history:[]
 property string activeAttempt:""
 property string revealedAttempt:""
 property string revealingTarget:""
 property string captureSubmission:""
 property string captureVault:""
 property var relations:[]
 property var artifactInfo:({})
 property var workflow:({})
 property string body:""
 property string query:""
 property string cursor:""
 property int serial:0
 property int latest:0
 property int appendSerial:0
 property int detailSerial:0
 property int historySerial:0
 property int relationSerial:0
 property var changedPaths:[]
 property bool reconcileAll:false
 property bool watchTransition:true
 property bool referenceHidden:false
 readonly property int captureLength:capture.text.length
 readonly property bool captureOpen:captureDialog.opened
 readonly property bool captureFocused:capture.activeFocus
 readonly property bool searchFocused:search.activeFocus
 readonly property bool inspectorVisible:inspectorOpen&&!!selected.id&&width>=1280
 readonly property real listSpace:Math.max(640,width-168-(inspectorVisible?240:0))
 readonly property bool coreRunning:worker.running
 readonly property bool watchRunning:watch.running
 readonly property int previewLength:body.length
 readonly property var sections:["Today","Learn","Research","Practice","Lab","Library"]
 readonly property var kinds:({Learn:["path","stage","course","resource","unit","capability","concept","prerequisite"],Research:["paper","resource","question"],Practice:["task","problem","session","practice-session"],Lab:["project","experiment","lab","artifact"]})
 function send(action,extra){
  if(!worker.running||!Oasis.activeVault)return 0;
  let request=Object.assign({version:1,request_id:++serial,vault:Oasis.activeVault,action:action},extra||{});
  worker.write(JSON.stringify(request)+"\n");return request.request_id;
 }
 function load(append){loading=true;latest=send(section==="Today"&&!query?"today":"query",{kind:kinds[section]||null,query:query,context_id:Oasis.currentContext.vault===Oasis.activeVault?Oasis.currentContext.id:null,quiet:Oasis.quiet,path_id:Oasis.pathScope||null,cursor:append?Number(cursor):0});appendSerial=append?latest:0;}
 function select(row,fromHistory){stashDraft();if(!fromHistory&&row.id!==selected.id){navigation=navigation.slice(0,navigationIndex+1).concat([Object.assign({},row)]);navigationIndex=navigation.length-1;}contextLoading=true;contextTab=["task","problem"].includes(row.type)?"Work":"Read";let changed=row.id!==selected.id;if(changed){activeAttempt="";revealedAttempt="";revealingTarget="";}selectedVault=Oasis.activeVault;selected=row;Oasis.currentContext=Object.assign({},row,{vault:Oasis.activeVault});Oasis.savePreferences();body="";artifactInfo=({});workflow=({});history=[];evidence.text=Oasis.drafts[draftKey(row)]||"";relations=[];if(changed)referenceHidden=section==="Practice";if(row.id){detailSerial=send("record",{record_id:row.id});historySerial=send("timeline",{record_id:row.id});relationSerial=send("relations",{record_id:row.id});}else Oasis.preview(row.path);}
 function refreshContext(){if(!selected.id)return;let tab=contextTab;select(selected,true);contextTab=tab;}
 function draftKey(row){return (row.id===selected.id?selectedVault:Oasis.activeVault)+":"+row.id;}
 function stashDraft(){if(selected.id){let next=Object.assign({},Oasis.drafts);next[draftKey(selected)]=evidence.text;Oasis.drafts=next;Oasis.savePreferences();}}
 function back(){if(navigationIndex>0){navigationIndex--;select(navigation[navigationIndex],true);}}
 function forward(){if(navigationIndex+1<navigation.length){navigationIndex++;select(navigation[navigationIndex],true);}}
 function quickCapture(){captureVault=Oasis.activeVault;capture.text=Oasis.drafts[captureVault+":capture"]||"";captureDialog.open();capture.forceActiveFocus();}
 function submitCapture(){if(root.captureVault!==Oasis.activeVault){Oasis.error="Vault changed. Return to the capture’s vault before saving.";return;}root.captureSubmission=capture.text;Oasis.run(["capture",capture.text]);}
 function saveEvent(event,data){if(activeAttempt&&event!=="attempt-start")data.attempt_id=activeAttempt;Oasis.run(["event",selected.path,event,"--target-id",selected.id,"--evidence",evidence.text,"--data",JSON.stringify(data)]);}
 onSectionChanged:{stashDraft();Oasis.workspace=section;Oasis.savePreferences();selected=({});history=[];relations=[];detailSerial=0;historySerial=0;relationSerial=0;body="";query="";search.text="";load(false);}
 Component.onCompleted:watch.running=Oasis.windowOpen&&Oasis.activeVault!==""
 Connections {target:Oasis;
  function onWindowOpenChanged(){root.watchTransition=true;watch.running=Oasis.windowOpen&&Oasis.activeVault!=="";}
  function onCaptureRequested(){root.quickCapture();}
  function onActiveVaultChanged(){root.stashDraft();captureDialog.close();createDialog.close();reviewDialog.close();comparisonDialog.close();root.watchTransition=true;watch.running=false;refresh.stop();root.changedPaths=[];root.reconcileAll=false;Qt.callLater(()=>watch.running=Oasis.windowOpen&&Oasis.activeVault!=="");root.rows=[];root.selected=({});root.body="";root.history=[];root.detailSerial=0;root.historySerial=0;root.relationSerial=0;if(worker.running)root.send("reconcile");}
  function onFinished(ok){if(root.revealingTarget){if(ok&&Oasis.operationResult.event==="assistance"&&Oasis.operationResult.target?.record_id===root.revealingTarget&&root.selected.id===root.revealingTarget){root.revealedAttempt=root.activeAttempt;root.referenceHidden=false;}root.revealingTarget="";}if(ok){if(Oasis.operationResult.event==="attempt-start"&&Oasis.operationResult.target?.record_id===root.selected.id){root.activeAttempt=Oasis.operationResult.id;root.referenceHidden=true;}else if(Oasis.operationResult.event==="attempt")root.activeAttempt="";root.send("reconcile");root.refreshContext();}}
 }
 Process {
  id:worker;command:["@HOME@/.local/bin/noesis","serve","--stdio"];stdinEnabled:true;running:Oasis.windowOpen
  onStarted:{root.send("reconcile");if(root.section!=="Today"&&Oasis.currentContext.vault===Oasis.activeVault&&Oasis.currentContext.id)root.select(Oasis.currentContext);}
  stdout:SplitParser {onRead:line=>{
   try{
    let response=JSON.parse(line);if(response.vault&&response.vault!==Oasis.activeVault)return;
    if(response.error){root.loading=false;root.contextLoading=false;Oasis.error=response.error;return;}
    let result=response.result;
    if(result.errors){if(result.errors.length)Oasis.error=JSON.stringify(result.errors);root.load(false);root.refreshContext();return;}
    if(response.request_id===root.latest){root.loading=false;root.home=result;root.rows=response.request_id===root.appendSerial?Array.from(new Map(root.rows.concat(result.records||[]).map(row=>[row.id||row.path,row])).values()):(result.records||[]);root.cursor=result.cursor===null||result.cursor===undefined?"":String(result.cursor);}
    if(response.request_id===root.detailSerial){root.contextLoading=false;root.body=result.body||"";root.artifactInfo=result.artifact||({});root.workflow=result.overview||({});root.activeAttempt=result.attempt?.id||"";if(root.activeAttempt){root.referenceHidden=root.revealedAttempt!==root.activeAttempt;mode.currentIndex=Math.max(0,mode.model.indexOf(result.attempt.mode||"derive"));}if(result.attempt_conflict)Oasis.error="Multiple unfinished attempts need explicit resolution.";root.selected=Object.assign({},root.selected,result.props||{},{path:result.path});Oasis.currentContext=Object.assign({},root.selected,{vault:Oasis.activeVault,session_state:result.state?.status||""});Oasis.savePreferences();position.text=String(result.state?.locator?.value??result.state?.position??"");locatorKind.currentIndex=result.state?.locator?Math.max(0,locatorKind.model.indexOf(result.state.locator.kind)):0;readingPass.currentIndex=Math.max(0,readingPass.model.indexOf(result.state?.reading_pass||"survey"));if(result.state?.conflict)Oasis.error=result.state.conflict;}
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
 }}
  onStarted:root.watchTransition=false
  stderr:StdioCollector {onStreamFinished:if(text.trim())Oasis.error="Filesystem watch failed; refresh to reconcile."}
  onExited:code=>{if(code!==0&&Oasis.windowOpen&&!root.watchTransition)Oasis.error="Filesystem watch stopped; refresh to reconcile."}}
 Timer {id:refresh;interval:250;onTriggered:{root.send("reconcile",{paths:root.reconcileAll||root.changedPaths.length>1000?null:root.changedPaths});root.changedPaths=[];root.reconcileAll=false;}}
 Timer {id:searchDelay;interval:150;onTriggered:root.load(false)}
 Shortcut {sequence:"Ctrl+K";onActivated:search.forceActiveFocus()}
 Shortcut {sequence:"Ctrl+Shift+N";onActivated:root.quickCapture()}
 Shortcut {sequence:"Ctrl+1";onActivated:root.section="Today"}
 Shortcut {sequence:"Ctrl+2";onActivated:root.section="Learn"}
 Shortcut {sequence:"Ctrl+3";onActivated:root.section="Research"}
 Shortcut {sequence:"Ctrl+4";onActivated:root.section="Practice"}
 Shortcut {sequence:"Ctrl+5";onActivated:root.section="Lab"}
 Shortcut {sequence:"Ctrl+6";onActivated:root.section="Library"}
 Shortcut {sequence:"Alt+Left";onActivated:root.back()}
 Shortcut {sequence:"Alt+Right";onActivated:root.forward()}
 Shortcut {sequence:"Ctrl+I";onActivated:root.inspectorOpen=!root.inspectorOpen}
 Timer {id:captureDraftSave;interval:500;onTriggered:{let next=Object.assign({},Oasis.drafts);next[root.captureVault+":capture"]=capture.text;Oasis.drafts=next;Oasis.savePreferences();}}
 Timer {id:draftSave;interval:500;onTriggered:root.stashDraft()}
 RowLayout {
  anchors.fill:parent;spacing:0
  Rectangle {Layout.preferredWidth:168;Layout.fillHeight:true;color:NoesisStyle.surface
   ColumnLayout {anchors.fill:parent;anchors.margins:NoesisStyle.lg;spacing:NoesisStyle.xs
    Text {text:"YOUR WORKSPACE";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;Layout.topMargin:NoesisStyle.sm;Layout.bottomMargin:NoesisStyle.md}
    Repeater {model:root.sections;delegate:NoesisButton {required property string modelData;text:modelData;Layout.fillWidth:true;textAlignment:Text.AlignLeft;highlighted:root.section===modelData;onClicked:root.section=modelData;Accessible.name:modelData+" workspace";hint:"Ctrl+"+(root.sections.indexOf(modelData)+1)}}
    Item {Layout.fillHeight:true}
    NoesisButton {text:"Quick capture";Layout.fillWidth:true;textAlignment:Text.AlignLeft;onClicked:root.quickCapture();hint:"Ctrl+Shift+N"}
    NoesisButton {text:"Find anything";Layout.fillWidth:true;textAlignment:Text.AlignLeft;onClicked:search.forceActiveFocus();hint:"Ctrl+K"}
    Text {text:"VAULT";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;Layout.topMargin:NoesisStyle.lg}
    NoesisSelect {Layout.fillWidth:true;model:(Oasis.state.vaults||[]).map(v=>v.name);currentIndex:(Oasis.state.vaults||[]).findIndex(v=>v.path===Oasis.activeVault);onActivated:{let v=Oasis.state.vaults[currentIndex];if(v)Oasis.choose(v.path);}}
   }
  }
  ColumnLayout {Layout.fillWidth:true;Layout.fillHeight:true;spacing:0
   RowLayout {Layout.fillWidth:true;Layout.margins:NoesisStyle.xl;spacing:NoesisStyle.sm
    NoesisButton {text:"←";enabled:root.navigationIndex>0;onClicked:root.back();Accessible.name:"Back";hint:"Alt+Left"}
    NoesisButton {text:"→";enabled:root.navigationIndex+1<root.navigation.length;onClicked:root.forward();Accessible.name:"Forward";hint:"Alt+Right"}
    Text {text:root.section;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.heading;Layout.fillWidth:true}
    NoesisField {id:search;Layout.preferredWidth:Math.min(280,root.width*.22);placeholderText:"Search · Ctrl+K";onTextChanged:{root.query=text;searchDelay.restart();}Accessible.name:"Search learning records"}
    NoesisButton {text:root.section==="Lab"?"+ Experiment":"+ Resource";visible:["Learn","Research","Lab","Library"].includes(root.section);onClicked:createDialog.begin(root.section==="Lab"?"experiment":"resource","")}
    NoesisButton {text:"+ Path";visible:root.section==="Learn";onClicked:createDialog.begin("path","")}
    NoesisButton {text:"From Zotero";visible:root.section==="Research";onClicked:zoteroDialog.open()}
    NoesisButton {text:"+ Capture";primary:true;onClicked:root.quickCapture()}
    NoesisButton {text:"↻";onClicked:root.send("reconcile");Accessible.name:"Refresh"}
   }
   RowLayout {Layout.fillWidth:true;Layout.fillHeight:true;spacing:0
    ColumnLayout {Layout.fillWidth:!root.selected.id;Layout.preferredWidth:root.selected.id?Math.max(240,root.listSpace*Oasis.listRatio):0;Layout.maximumWidth:root.selected.id?Math.max(240,root.listSpace*Oasis.listRatio):10000;Layout.fillHeight:true;Layout.leftMargin:NoesisStyle.xl;Layout.rightMargin:NoesisStyle.xl;spacing:NoesisStyle.lg
     Text {text:({Today:"One useful next step.",Learn:"Paths, courses and the ideas that connect them.",Research:"Read with a question. Return with an explanation.",Practice:"Preserve the struggle. Make the next attempt independent.",Lab:"From prediction to measurement.",Library:"Everything saved, ready to connect."})[root.section];color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;Layout.fillWidth:true}
     ColumnLayout {visible:root.section==="Today"&&!root.query&&!!root.home.continue;Layout.fillWidth:true;spacing:NoesisStyle.sm
      Text {text:"CONTINUE";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
      NoesisRow {Layout.fillWidth:true;title:root.home.continue?.title||"";subtitle:root.home.continue?.unfinished_attempt?"Unfinished attempt · reasoning and exposure preserved":root.home.continue?.position||"Return to your working context";trailing:"Resume →";onClicked:root.select(root.home.continue)}
     }
     RowLayout {Layout.fillWidth:true;visible:root.section==="Today"&&!root.query
      Text {text:"SUGGESTED NEXT";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;Layout.fillWidth:true}
      NoesisButton {text:Oasis.quiet?"Show":"Quiet";onClicked:{Oasis.quiet=!Oasis.quiet;Oasis.savePreferences();root.load(false);}}
      NoesisButton {text:"All paths";visible:Oasis.pathScope!=="";onClicked:{Oasis.setPathScope("");root.load(false);}}
     }
     Text {visible:root.loading;text:"Loading your workspace…";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
     ListView {id:list;Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:root.rows;keyNavigationEnabled:true;reuseItems:true;spacing:NoesisStyle.xs
      Keys.onReturnPressed:if(currentIndex>=0)root.select(root.rows[currentIndex])
      delegate:NoesisRow {required property var modelData;required property int index;width:list.width;title:modelData.title||modelData.path;subtitle:modelData.reason||modelData.type||"";highlighted:root.selected.id===modelData.id;onClicked:{list.currentIndex=index;root.select(modelData);}}
      ScrollBar.vertical:ScrollBar {}
      NoesisEmpty {anchors.centerIn:parent;width:Math.min(560,parent.width);visible:!root.loading&&root.rows.length===0;title:root.query?"No matching records":root.section==="Today"?root.home.continue?"Room for curiosity":"Your learning has a home":"Start with a question";description:root.query?"Try a title, concept, identifier or a word from your notes.":root.section==="Today"?"Capture something worth exploring, choose a path, or resume when you are ready. No backlog to catch up with.":"Save a source or a thought now. You can organize and connect it as you work.";action:root.query?"Clear search":"Quick capture";onActivated:{if(root.query)search.text="";else root.quickCapture();}}
     }
     NoesisButton {visible:root.cursor!=="";text:"Load 50 more";onClicked:root.load(true);Layout.bottomMargin:NoesisStyle.xl}
    }
    Rectangle {visible:!!root.selected.id;Layout.preferredWidth:1;Layout.fillHeight:true;color:NoesisStyle.rule
     MouseArea {anchors.fill:parent;anchors.margins:-4;cursorShape:Qt.SplitHCursor;property real startX:0;property real startRatio:0;onPressed:mouse=>{startX=mapToItem(root,mouse.x,mouse.y).x;startRatio=Oasis.listRatio;}onPositionChanged:mouse=>{if(pressed)Oasis.listRatio=Math.min(.5,Math.max(.22,startRatio+(mapToItem(root,mouse.x,mouse.y).x-startX)/Math.max(1,root.width-168)));}onReleased:Oasis.savePreferences()}
    }
    ColumnLayout {visible:!!root.selected.id;Layout.fillWidth:true;Layout.fillHeight:true;Layout.margins:NoesisStyle.xl;spacing:NoesisStyle.md
     RowLayout {Layout.fillWidth:true
      ColumnLayout {Layout.fillWidth:true;spacing:NoesisStyle.xs
       Text {text:(root.selected.type||"context").toUpperCase();color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
       Text {text:root.selected.title||root.selected.imported_title||root.selected.path||"";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.heading;wrapMode:Text.Wrap;Layout.fillWidth:true}
      }
      NoesisButton {text:"Details";highlighted:root.inspectorOpen;onClicked:root.inspectorOpen=!root.inspectorOpen;hint:"Ctrl+I"}
      NoesisButton {text:"×";onClicked:{root.stashDraft();root.selected=({});}
       Accessible.name:"Close context"}
     }
     RowLayout {Layout.fillWidth:true;spacing:NoesisStyle.xs
      Repeater {model:["Read","Work","History","Connections"];delegate:NoesisButton {required property string modelData;text:modelData;highlighted:root.contextTab===modelData;onClicked:root.contextTab=modelData}}
      Item {Layout.fillWidth:true}
      NoesisButton {text:"Open note ↗";enabled:!root.referenceHidden;onClicked:Oasis.note(root.selected.path)}
     }
     Label {visible:root.contextLoading;text:"Opening context…";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont}
     Label {visible:root.selected.type==="artifact";text:(root.artifactInfo.availability||"Artifact reference")+" · "+(root.artifactInfo.location||"");color:NoesisStyle.secondary;wrapMode:Text.Wrap;Layout.fillWidth:true;font.family:NoesisStyle.uiFont}
     Label {visible:root.workflow.kind==="experiment"||root.workflow.kind==="project";text:root.workflow.latest_comparison?"Last reported result · "+(root.workflow.latest_comparison.observed||root.workflow.latest_comparison.conclusion||"Open history for evidence"):"Preserve a prediction, connect a run and compare what happened.";color:NoesisStyle.secondary;wrapMode:Text.Wrap;Layout.fillWidth:true;font.family:NoesisStyle.uiFont}
     Label {visible:!!root.workflow.counts&&root.contextTab==="Read";text:{let c=root.workflow.counts;if(!c)return "";return "Lectures "+c.lectures.consumed+" / "+c.lectures.total+" · readings "+c.readings.consumed+" / "+c.readings.total+"\nAssignments "+c.assignments.reported_success+" / "+c.assignments.total+" reported success · projects "+c.projects.reported_success+" / "+c.projects.total;}color:NoesisStyle.secondary;wrapMode:Text.Wrap;Layout.fillWidth:true;font.family:NoesisStyle.uiFont}
     ScrollView {visible:root.contextTab==="Read";Layout.fillWidth:true;Layout.fillHeight:true;clip:true
      TextArea {text:root.referenceHidden?"Reference hidden. Reconstruct before revealing.":root.body;readOnly:true;textFormat:TextEdit.MarkdownText;wrapMode:TextEdit.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;background:null;selectByMouse:true;Accessible.name:"Reading preview";onLinkActivated:link=>{if(/^https?:\/\//.test(link))Quickshell.execDetached(["xdg-open",link]);}}
     }
     ListView {visible:root.contextTab==="Read"&&["course","path"].includes(root.workflow.kind)&&root.relations.length>0;Layout.fillWidth:true;Layout.preferredHeight:Math.min(240,root.relations.length*NoesisStyle.row);clip:true;model:root.relations.filter(r=>["contains","orders","assigns"].includes(r.relation))
      delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:modelData.other_title||modelData.other_id;subtitle:(modelData.other_type||"step")+(modelData.other_status?" · "+modelData.other_status:"");enabled:!!modelData.other_path;onClicked:root.select({id:modelData.other_id,path:modelData.other_path,title:modelData.other_title,type:modelData.other_type})}
      ScrollBar.vertical:ScrollBar {}
     }
     ColumnLayout {visible:root.contextTab==="Work";Layout.fillWidth:true;Layout.fillHeight:true;spacing:NoesisStyle.md
      Label {text:root.activeAttempt?"Continue this attempt. Reference exposure stays in its history.":"Predict first. Preserve the reasoning before checking it.";color:NoesisStyle.secondary;wrapMode:Text.Wrap;Layout.fillWidth:true;font.family:NoesisStyle.uiFont}
      NoesisEditor {id:evidence;Layout.fillWidth:true;Layout.fillHeight:true;placeholderText:"Prediction, reasoning, derivation or observed discrepancy…";onTextChanged:if(root.selected.id)draftSave.restart()}
      RowLayout {Layout.fillWidth:true
       NoesisSelect {id:mode;model:["pattern","interface","derive","build","transfer"];currentIndex:2;Layout.fillWidth:true}
       NoesisSelect {id:outcome;model:["unknown","incomplete","failed","partial","succeeded"];Layout.fillWidth:true;visible:!!root.activeAttempt}
       NoesisSelect {id:assistance;model:["unknown","none","hint","reference","collaborator","agent"];Layout.fillWidth:true;visible:!!root.activeAttempt}
      }
      RowLayout {Layout.fillWidth:true
       NoesisButton {text:"Start attempt";primary:true;visible:!root.activeAttempt;enabled:!Oasis.working;onClicked:root.saveEvent("attempt-start",{mode:mode.currentText,scope:root.selected.title||root.selected.path})}
       NoesisButton {text:"Save outcome";primary:true;visible:!!root.activeAttempt;enabled:!Oasis.working&&evidence.text.trim()!=="";onClicked:root.saveEvent("attempt",{outcome:outcome.currentText,assistance:[assistance.currentText],mode:mode.currentText,assessment:"learner-reported",scope:root.selected.title||root.selected.path})}
       NoesisButton {text:root.referenceHidden?"Reveal reference":"Hide reference";enabled:!Oasis.working;onClicked:{if(root.referenceHidden){root.revealingTarget=root.selected.id;root.saveEvent("assistance",{assistance:["reference"],scope:"Noesis preview"});}else{root.referenceHidden=true;root.revealedAttempt="";}}}
       NoesisButton {text:"Plan a check";onClicked:reviewDialog.open()}
       Item {Layout.fillWidth:true}
      }
     }
     ListView {visible:root.contextTab==="History";Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:root.history;spacing:NoesisStyle.sm
      delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:modelData.event+" · "+(modelData.criterion||modelData.outcome||modelData.integrity||"")+(modelData.decision?" · "+modelData.decision:"");subtitle:(modelData.assistance||["unknown"]).join(", ")+" · "+modelData.timestamp;enabled:!root.referenceHidden;onClicked:Oasis.note(modelData.path)}
      NoesisEmpty {anchors.centerIn:parent;width:parent.width;visible:root.history.length===0;title:"History begins with real work";description:"Positions, predictions, attempts and comparisons will appear here. Nothing is inferred from a saved note."}
      ScrollBar.vertical:ScrollBar {}
     }
     ListView {visible:root.contextTab==="Connections";Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:root.relations;spacing:NoesisStyle.xs
      delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:modelData.other_title||modelData.other_id;subtitle:modelData.relation+(modelData.role?" · "+modelData.role:"");enabled:!!modelData.other_path&&!root.referenceHidden;onClicked:root.select({id:modelData.other_id,path:modelData.other_path,title:modelData.other_title,type:modelData.other_type})}
      NoesisEmpty {anchors.centerIn:parent;width:parent.width;visible:root.relations.length===0;title:"Connect the next question";description:"Related resources, prerequisites, implementations and evidence stay linked even when notes move."}
     }
     Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm;visible:root.contextTab==="Read"
      NoesisButton {text:root.selected.source_kind==="video"||root.selected.source_kind==="playlist"?"Continue video ↗":root.selected.local_file||root.selected.zotero_attachment_key?"Open PDF ↗":"Open source ↗";enabled:!root.referenceHidden;visible:["paper","resource","course","unit"].includes(root.selected.type);onClicked:Oasis.run(["read-resource",root.selected.path,"--reader",root.selected.zotero_uri?"zotero":"sioyek"])}
      NoesisButton {text:"Add lesson / chapter";visible:["path","course","resource"].includes(root.selected.type);onClicked:createDialog.begin("unit",root.selected.id)}
      NoesisButton {text:"Add problem";visible:["path","course","resource","unit"].includes(root.selected.type);onClicked:createDialog.begin("task",root.selected.id)}
      NoesisButton {text:"Add run";visible:["project","experiment","lab"].includes(root.selected.type);onClicked:createDialog.begin("experiment",root.selected.id)}
      NoesisButton {text:"Connect data / figure / code";visible:["paper","project","experiment","lab"].includes(root.selected.type)||root.selected.source_kind==="paper";onClicked:createDialog.begin("artifact",root.selected.id)}
      NoesisButton {text:"Record comparison";visible:["experiment","lab"].includes(root.selected.type);onClicked:comparisonDialog.open()}
      NoesisButton {text:"Ask a question";visible:!root.referenceHidden;onClicked:createDialog.begin("question",root.selected.id)}
      NoesisButton {text:"Bibliography";enabled:!root.referenceHidden;visible:!!root.selected.bibliography_projection;onClicked:Oasis.note(root.selected.bibliography_projection)}
      NoesisButton {text:"Use path for Today";visible:root.selected.type==="path";onClicked:Oasis.setPathScope(root.selected.id)}
      NoesisButton {text:"Check checksum";visible:root.selected.type==="artifact";enabled:!Oasis.working;onClicked:Oasis.run(["artifact-check",root.selected.id])}
     }
     RowLayout {Layout.fillWidth:true;visible:root.contextTab==="Read"&&["paper","resource","course","unit"].includes(root.selected.type)
      NoesisSelect {id:locatorKind;model:["location","page","section","exercise","timestamp"];Layout.preferredWidth:110;Accessible.name:"Resume location kind"}
      NoesisSelect {id:readingPass;model:["survey","detail","reconstruct","verify"];visible:root.selected.source_kind==="paper"||root.selected.type==="paper";Layout.preferredWidth:120;Accessible.name:"Reading pass"}
      NoesisField {id:position;Layout.fillWidth:true;placeholderText:"Resume at page, section or timestamp"}
      NoesisButton {text:"Save place";enabled:!Oasis.working;onClicked:root.saveEvent("study",{state:Object.assign(locatorKind.currentText==="location"?{position:position.text}:{locator:{kind:locatorKind.currentText,value:position.text}},readingPass.visible?{reading_pass:readingPass.currentText}:{})})}
     }
     Text {visible:root.contextTab==="Read";text:"Equations, diagrams and editing open in Obsidian.";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;wrapMode:Text.Wrap;Layout.fillWidth:true}
    }
    Rectangle {visible:root.inspectorVisible;Layout.preferredWidth:240;Layout.fillHeight:true;color:NoesisStyle.surface
     ColumnLayout {anchors.fill:parent;anchors.margins:NoesisStyle.lg;spacing:NoesisStyle.lg
      Text {text:"CONTEXT";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
      Text {text:root.selected.path||"";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
      Text {text:root.selected.confidence!==undefined?"Legacy confidence: "+root.selected.confidence+" / 5 · self-report":"Evidence stays scoped. Assistance stays visible.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
      ListView {visible:root.workflow.kind==="paper";Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:root.referenceHidden?[]:root.workflow.annotations||[];spacing:NoesisStyle.md
       delegate:Column {required property var modelData;width:ListView.view.width;spacing:NoesisStyle.sm
        Text {text:"ZOTERO · "+(modelData.page_label?"PAGE "+modelData.page_label:modelData.native_id);color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
        Text {text:modelData.text||modelData.comment;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;width:parent.width}
       }
      }
      Item {Layout.fillHeight:true;visible:root.workflow.kind!=="paper"}
      NoesisButton {text:"Close inspector";onClicked:root.inspectorOpen=false}
     }
    }
   }
   RowLayout {Layout.fillWidth:true;Layout.margins:NoesisStyle.md;visible:Oasis.error!==""||Oasis.message!==""||Oasis.working
    Text {text:Oasis.working?"Saving…":Oasis.error||Oasis.message;color:Oasis.error?NoesisStyle.accent:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
    NoesisButton {text:"Stop";visible:Oasis.working;onClicked:Oasis.cancel()}
   }
  }
 }
 NoesisDialog {id:comparisonDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(560,root.width-48);modal:true;title:"Compare prediction with observation"
  property bool submitting:false
  background:Rectangle {color:NoesisStyle.surface;radius:NoesisStyle.radius;border.width:1;border.color:NoesisStyle.rule}
  contentItem:ColumnLayout {spacing:NoesisStyle.md
   NoesisField {id:predicted;Layout.fillWidth:true;placeholderText:"Original prediction or hypothesis"}
   NoesisField {id:observed;Layout.fillWidth:true;placeholderText:"Observed result, with units and uncertainty"}
   NoesisField {id:conditions;Layout.fillWidth:true;placeholderText:"Configuration and code commit · optional"}
   NoesisEditor {id:conclusion;Layout.fillWidth:true;Layout.preferredHeight:120;placeholderText:"Discrepancy, evidence and what to test next…"}
   Text {text:"A successful run does not establish the hypothesis. This preserves the comparison as reported evidence.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
   NoesisButton {text:"Save comparison";primary:true;enabled:predicted.text.trim()!==""&&observed.text.trim()!==""&&conclusion.text.trim()!==""&&!Oasis.working;onClicked:{comparisonDialog.submitting=true;Oasis.run(["event",root.selected.path,"comparison","--target-id",root.selected.id,"--evidence",conclusion.text,"--data",JSON.stringify({prediction:predicted.text,observed:observed.text,configuration:conditions.text,conclusion:conclusion.text,assessment:"learner-reported"})]);}}
  }
  Connections {target:Oasis;function onFinished(ok){if(comparisonDialog.submitting){comparisonDialog.submitting=false;if(ok){comparisonDialog.close();predicted.text="";observed.text="";conditions.text="";conclusion.text="";}}}}
 }
 NoesisDialog {id:reviewDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(440,root.width-48);modal:true;title:"Plan a later check"
  background:Rectangle {color:NoesisStyle.surface;radius:NoesisStyle.radius;border.width:1;border.color:NoesisStyle.rule}
  contentItem:ColumnLayout {spacing:NoesisStyle.lg
   NoesisSelect {id:checkStage;model:["retry","later","maintenance"];Layout.fillWidth:true}
   NoesisSelect {id:checkAction;model:["schedule","snooze","retire"];Layout.fillWidth:true}
   NoesisEditor {id:checkPurpose;Layout.fillWidth:true;Layout.preferredHeight:100;placeholderText:"What will you reconstruct or verify?"}
   Text {text:"Defaults: 1, 7 or 30 days. A convenience policy, not a competence estimate.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
   NoesisButton {text:"Save plan";primary:true;enabled:checkPurpose.text.trim()!==""&&!Oasis.working;onClicked:{Oasis.run(["event",root.selected.path,"review-plan","--target-id",root.selected.id,"--evidence",checkPurpose.text,"--data",JSON.stringify({stage:checkStage.currentText,action:checkAction.currentText})]);reviewDialog.close();}}
  }
 }
 NoesisZoteroDialog {id:zoteroDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(620,root.width-48);height:Math.min(480,root.height-80);onImported:record=>{let paths=(record.created||[]).concat(record.existing||[]);if(paths.length)root.select({id:record.resource_id,path:paths[0],type:"paper"});}}
 NoesisCreateDialog {id:createDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(560,root.width-48);onCreated:record=>root.select(record)}
 NoesisDialog {id:captureDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(560,root.width-48);modal:true;title:"Quick capture";closePolicy:Popup.CloseOnEscape
  background:Rectangle {color:NoesisStyle.surface;radius:NoesisStyle.radius;border.color:NoesisStyle.rule;border.width:1}
  contentItem:ColumnLayout {spacing:NoesisStyle.lg
   NoesisEditor {id:capture;Keys.onPressed:event=>{if((event.key===Qt.Key_Return||event.key===Qt.Key_Enter)&&(event.modifiers&Qt.ControlModifier)){event.accepted=true;if(capture.text.trim()&&!Oasis.working)root.submitCapture();}}Layout.fillWidth:true;Layout.preferredHeight:160;placeholderText:"A thought, source, snippet or observation…";onTextChanged:if(root.captureVault)captureDraftSave.restart();Accessible.name:"Quick capture"}
   Text {text:"No classification needed. Connect it when you are ready.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
   RowLayout {Layout.fillWidth:true
    NoesisButton {text:"Keep draft";onClicked:captureDialog.close()}
    Item {Layout.fillWidth:true}
    NoesisButton {text:"Save capture";primary:true;enabled:capture.text.trim()!==""&&!Oasis.working;onClicked:root.submitCapture()}
   }
  }
 }
 Connections {target:Oasis;function onFinished(ok){if(ok&&root.captureSubmission&&capture.text===root.captureSubmission){capture.text="";captureDialog.close();}root.captureSubmission="";}}
}
