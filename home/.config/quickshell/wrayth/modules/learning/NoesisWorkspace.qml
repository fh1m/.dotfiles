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
 property var selectedState:({})
 property string body:""
 property string query:""
 property string cursor:""
 property int serial:0
 property int latest:0
 property int appendSerial:0
 property int reconcileSerial:0
 property int detailSerial:0
 property int historySerial:0
 property int relationSerial:0
 property int capabilitySerial:0
 property int capabilityDetailSerial:0
 property string submittedEvidence:""
 property var changedPaths:[]
 property bool reconcileAll:false
 property bool watchTransition:true
 property bool referenceHidden:false
 readonly property string reportedOutcome:outcome.currentText
 readonly property string declaredAssistance:assistance.currentText
 readonly property int captureLength:capture.text.length
 readonly property real readViewportHeight:readScroll.availableHeight
 readonly property real readContentHeight:readingColumn.implicitHeight
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
  if(action==="reconcile")reconcileSerial=request.request_id;
  worker.write(JSON.stringify(request)+"\n");return request.request_id;
 }
 function load(append){loading=true;latest=send(section==="Today"&&!query?"today":"query",{kind:kinds[section]||null,query:query,resource_kinds:({Learn:["course","book","playlist","video","lecture"],Research:["paper","journal","preprint","article"]})[section]||null,context_id:Oasis.currentContext.vault===Oasis.activeVault?Oasis.currentContext.id:null,quiet:Oasis.quiet,path_id:Oasis.pathScope||null,cursor:append?Number(cursor):0});appendSerial=append?latest:0;}
 function select(row,fromHistory){stashDraft();if(!fromHistory&&row.id!==selected.id){navigation=navigation.slice(0,navigationIndex+1).concat([Object.assign({},row)]);navigationIndex=navigation.length-1;}contextLoading=true;contextTab=["task","problem"].includes(row.type)?"Work":"Read";let changed=row.id!==selected.id;if(changed){activeAttempt="";revealedAttempt="";revealingTarget="";}selectedVault=Oasis.activeVault;selected=row;Oasis.currentContext=Object.assign({},row,{vault:Oasis.activeVault});Oasis.savePreferences();body="";artifactInfo=({});workflow=({});selectedState=({});history=[];evidence.text=Oasis.drafts[draftKey(row)]||"";relations=[];if(changed)referenceHidden=section==="Practice";if(contextTab==="Work")Qt.callLater(()=>evidence.forceActiveFocus());if(row.id){detailSerial=send("record",{record_id:row.id});historySerial=send("timeline",{record_id:row.id});relationSerial=send("relations",{record_id:row.id});}else Oasis.preview(row.path);}
 function refreshContext(){if(!selected.id)return;let tab=contextTab;select(selected,true);contextTab=tab;}
 function draftKey(row){return (row.id===selected.id?selectedVault:Oasis.activeVault)+":"+row.id;}
 function stashDraft(){if(selected.id){let next=Object.assign({},Oasis.drafts);next[draftKey(selected)]=evidence.text;Oasis.drafts=next;Oasis.savePreferences();}}
 function back(){if(navigationIndex>0){navigationIndex--;select(navigation[navigationIndex],true);}}
 function forward(){if(navigationIndex+1<navigation.length){navigationIndex++;select(navigation[navigationIndex],true);}}
 function quickCapture(){captureVault=Oasis.activeVault;capture.text=Oasis.drafts[captureVault+":capture"]||"";captureDialog.open();capture.forceActiveFocus();}
 function submitCapture(){if(root.captureVault!==Oasis.activeVault){Oasis.error="Vault changed. Return to the capture’s vault before saving.";return;}root.captureSubmission=capture.text;Oasis.run(["capture",capture.text]);}
 function studyUpdate(status){let state={};if(position.text.trim()||!status)state=locatorKind.currentText==="location"?{position:position.text}:{locator:{kind:locatorKind.currentText,value:position.text}};if(root.selected.source_kind==="paper"||root.selected.type==="paper")state.reading_pass=readingPass.currentText;if(status)state.status=status;return state;}
 function contextActions(){
  let items=[];let add=(action,label,reason)=>items.push({action:action,label:label,reason:reason||""});let kind=selected.type;
  if(!selected.id||Oasis.working)return items;
  if(["task","problem"].includes(kind)&&history.some(event=>["attempt","review"].includes(event.event))&&!referenceHidden&&!activeAttempt)add("evidence","Review latest evidence","Judge a scoped result against a capability criterion");
  if(!referenceHidden)add("question","Ask a question","Preserve the uncertainty and your current explanation");
  if(workflow.kind==="paper"&&!referenceHidden)add("implementation","Start implementation","Connect a Git repository to this paper");
  if(["path","course","resource"].includes(kind))add("unit","Add lesson or chapter","Each unit keeps its own position and history");
  if(["path","course","resource","unit"].includes(kind))add("task","Add problem","Assessment stays separate from consumption");
  if(["project","experiment","lab"].includes(kind))add("run","Add experiment run","Preserve a new prediction and code revision");
  if(["paper","project","experiment","lab"].includes(kind)||selected.source_kind==="paper")add("artifact","Connect data, figure or code","Reference the original output without copying it");
  if(["experiment","lab"].includes(kind))add("comparison","Compare prediction and observation","Record units, uncertainty and the next test");
  if(["paper","unit"].includes(kind)||kind==="resource"&&selected.source_kind!=="course")add("consumed",selected.unit_kind==="lecture"||selected.unit_kind==="video"?"Lecture viewed":"Finished reading","Consumption does not award capability");
  if(["paper","resource","course","unit"].includes(kind))add("pause",selectedState.status==="parked"?"Resume reading":"Pause reading","Keep the resume place and all learning history");
  if(kind==="path")add("capability","Define a capability","Describe an ability and its assessment criteria");
  if(["task","problem"].includes(kind)){if(!activeAttempt)add("attempt-start","Start an attempt","Preserve reasoning before checking a reference");else{if(evidence.text.trim())add("attempt-save","Save outcome","Record the reported result and assistance separately");add("reference",referenceHidden?"Reveal reference":"Hide reference","Reference exposure stays in the attempt history");}add("check","Plan an independent check","Reconstruct later against a specific criterion");}
  if(kind==="path")add("path","Use path for Today","Suggestions use this path’s frontier and gates");
  if(selected.bibliography_projection&&!referenceHidden)add("bibliography","Open bibliography","Zotero-owned projection stays separate from your analysis");
  if(kind==="artifact")add("checksum","Check checksum","Inspect the referenced artifact without changing it");
  return items;
 }
 function contextAction(action){
  if(action==="evidence"){let entry=history.slice().reverse().find(event=>["attempt","review"].includes(event.event));if(entry)evidenceDialog.begin(entry);}
  else if(action==="question")createDialog.begin("question",selected.id);
  else if(action==="implementation")createDialog.begin("project",selected.id);
  else if(action==="capability")createDialog.begin("capability",selected.id);
  else if(action==="attempt-start")saveEvent("attempt-start",{mode:mode.currentText,scope:selected.title||selected.path});
  else if(action==="attempt-save")saveEvent("attempt",{outcome:outcome.currentText,assistance:[assistance.currentText],mode:mode.currentText,assessment:"learner-reported",scope:selected.title||selected.path});
  else if(action==="reference"){if(referenceHidden){revealingTarget=selected.id;saveEvent("assistance",{assistance:["reference"],scope:"Noesis preview"});}else{referenceHidden=true;revealedAttempt="";}}
  else if(action==="check")reviewDialog.open();
  else if(action==="unit"||action==="task")createDialog.begin(action,selected.id);
  else if(action==="run")createDialog.begin("experiment",selected.id);
  else if(action==="artifact")createDialog.begin("artifact",selected.id);
  else if(action==="comparison")comparisonDialog.open();
  else if(action==="consumed")saveEvent("study",{state:studyUpdate("read")});
  else if(action==="pause")saveEvent("disposition",{state:selectedState.status==="parked"?"active":"parked"});
  else if(action==="path")Oasis.setPathScope(selected.id);
  else if(action==="bibliography")Oasis.note(selected.bibliography_projection);
  else if(action==="checksum")Oasis.run(["artifact-check",selected.id]);
 }
 function saveEvent(event,data){submittedEvidence=evidence.text;if(activeAttempt&&event!=="attempt-start")data.attempt_id=activeAttempt;Oasis.run(["event",selected.path,event,"--target-id",selected.id,"--evidence",evidence.text,"--data",JSON.stringify(data)]);}
 onSectionChanged:{actionDialog.close();stashDraft();Oasis.workspace=section;Oasis.savePreferences();selected=({});history=[];relations=[];detailSerial=0;historySerial=0;relationSerial=0;body="";query="";search.text="";load(false);}
 Component.onCompleted:watch.running=Oasis.windowOpen&&Oasis.activeVault!==""
 Connections {target:Oasis;
  function onWindowOpenChanged(){root.watchTransition=true;watch.running=Oasis.windowOpen&&Oasis.activeVault!=="";}
  function onCaptureRequested(){root.quickCapture();}
  function onActiveVaultChanged(){root.stashDraft();captureDialog.close();evidenceDialog.close();capabilitySerial=0;capabilityDetailSerial=0;actionDialog.close();createDialog.close();reviewDialog.close();comparisonDialog.close();root.watchTransition=true;watch.running=false;refresh.stop();root.changedPaths=[];root.reconcileAll=false;Qt.callLater(()=>watch.running=Oasis.windowOpen&&Oasis.activeVault!=="");root.rows=[];root.selected=({});root.body="";root.history=[];root.detailSerial=0;root.historySerial=0;root.relationSerial=0;if(worker.running)root.send("reconcile");}
  function onFinished(ok){if(root.revealingTarget){if(ok&&Oasis.operationResult.event==="assistance"&&Oasis.operationResult.target?.record_id===root.revealingTarget&&root.selected.id===root.revealingTarget){root.revealedAttempt=root.activeAttempt;root.referenceHidden=false;}root.revealingTarget="";}if(ok){if(Oasis.operationResult.event==="attempt-start"&&Oasis.operationResult.target?.record_id===root.selected.id){root.activeAttempt=Oasis.operationResult.id;root.referenceHidden=true;outcome.currentIndex=0;assistance.currentIndex=0;}else if(Oasis.operationResult.event==="attempt"&&Oasis.operationResult.target?.record_id===root.selected.id){root.activeAttempt="";root.revealedAttempt="";root.referenceHidden=false;if(evidence.text===root.submittedEvidence){evidence.text="";root.stashDraft();}}root.send("reconcile");root.refreshContext();}}
 }
 Process {
  id:worker;command:["@HOME@/.local/bin/noesis","serve","--stdio"];stdinEnabled:true;running:Oasis.windowOpen
  onStarted:{root.send("reconcile");if(root.section!=="Today"&&Oasis.currentContext.vault===Oasis.activeVault&&Oasis.currentContext.id)root.select(Oasis.currentContext);}
  stdout:SplitParser {onRead:line=>{
   try{
    let response=JSON.parse(line);if(response.vault&&response.vault!==Oasis.activeVault)return;
    if(response.error){if(![root.latest,root.detailSerial,root.historySerial,root.relationSerial,root.reconcileSerial,root.capabilitySerial,root.capabilityDetailSerial].includes(response.request_id))return;root.loading=false;root.contextLoading=false;Oasis.error=response.error;return;}
    let result=response.result;
    if(result.errors){if(result.errors.length)Oasis.error=JSON.stringify(result.errors);root.load(false);root.refreshContext();return;}
    if(response.request_id===root.latest){root.loading=false;root.home=result;root.rows=response.request_id===root.appendSerial?Array.from(new Map(root.rows.concat(result.records||[]).map(row=>[row.id||row.path,row])).values()):(result.records||[]);root.cursor=result.cursor===null||result.cursor===undefined?"":String(result.cursor);}
    if(response.request_id===root.detailSerial){root.contextLoading=false;root.body=result.body||"";root.artifactInfo=result.artifact||({});root.workflow=result.overview||({});root.selectedState=result.state||({});root.activeAttempt=result.attempt?.id||"";if(root.activeAttempt){root.referenceHidden=root.revealedAttempt!==root.activeAttempt;mode.currentIndex=Math.max(0,mode.model.indexOf(result.attempt.mode||"derive"));}if(result.attempt_conflict)Oasis.error="Multiple unfinished attempts need explicit resolution.";root.selected=Object.assign({},root.selected,result.props||{},{path:result.path});Oasis.currentContext=Object.assign({},root.selected,{vault:Oasis.activeVault,session_state:result.state?.status||""});Oasis.savePreferences();position.text=String(result.state?.locator?.value??result.state?.position??"");locatorKind.currentIndex=result.state?.locator?Math.max(0,locatorKind.model.indexOf(result.state.locator.kind)):0;readingPass.currentIndex=Math.max(0,readingPass.model.indexOf(result.state?.reading_pass||"survey"));if(result.state?.conflict)Oasis.error=result.state.conflict;}
    if(response.request_id===root.capabilitySerial){evidenceDialog.capabilities=result.records||[];evidenceDialog.loading=false;}
    if(response.request_id===root.capabilityDetailSerial){evidenceDialog.detail(result);evidenceDialog.loading=false;}
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
 Shortcut {sequence:"Ctrl+.";enabled:!!root.selected.id&&!Oasis.working&&root.contextActions().length>0;onActivated:actionDialog.begin(root.contextActions())}
 Shortcut {sequence:"Ctrl+N";onActivated:root.section==="Today"?root.quickCapture():createDialog.begin(root.section==="Lab"?"experiment":root.section==="Practice"?"task":"resource","")}
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
    NoesisButton {text:"Quick capture";visible:root.section!=="Today";Layout.fillWidth:true;textAlignment:Text.AlignLeft;onClicked:root.quickCapture();hint:"Ctrl+Shift+N"}
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
    NoesisField {id:search;Keys.onDownPressed:{list.forceActiveFocus();list.currentIndex=0;}Layout.preferredWidth:Math.min(280,root.width*.22);placeholderText:"Search · Ctrl+K";onTextChanged:{root.query=text;searchDelay.restart();}Accessible.name:"Search learning records"}
    NoesisButton {text:root.section==="Lab"?"+ Experiment":root.section==="Practice"?"+ Problem":"+ Resource";hint:"Ctrl+N";visible:root.section!=="Today";onClicked:createDialog.begin(root.section==="Lab"?"experiment":root.section==="Practice"?"task":"resource","")}
    NoesisButton {text:"+ Path";visible:root.section==="Learn";onClicked:createDialog.begin("path","")}
    NoesisButton {text:"From Zotero";visible:root.section==="Research";onClicked:zoteroDialog.open()}
    NoesisButton {text:"+ Capture";primary:true;onClicked:root.quickCapture()}
    NoesisButton {text:"↻";onClicked:root.send("reconcile");Accessible.name:"Refresh"}
   }
   RowLayout {Layout.fillWidth:true;Layout.fillHeight:true;spacing:0
    ColumnLayout {Layout.fillWidth:!root.selected.id;Layout.preferredWidth:root.selected.id?Math.max(240,root.listSpace*Oasis.listRatio):0;Layout.maximumWidth:root.selected.id?Math.max(240,root.listSpace*Oasis.listRatio):10000;Layout.fillHeight:true;Layout.leftMargin:NoesisStyle.xl;Layout.rightMargin:NoesisStyle.xl;spacing:NoesisStyle.lg
     Text {text:({Today:"Pick up a thread. Follow your curiosity.",Learn:"Paths, courses and the ideas that connect them.",Research:"Read with a question. Return with an explanation.",Practice:"Preserve the struggle. Make the next attempt independent.",Lab:"From prediction to measurement.",Library:"Everything saved, ready to connect."})[root.section];color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;Layout.fillWidth:true}
     ColumnLayout {visible:root.section==="Today"&&!root.query&&!!root.home.continue;Layout.fillWidth:true;spacing:NoesisStyle.sm
      Text {text:"CONTINUE";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
      NoesisRow {Layout.fillWidth:true;title:root.home.continue?.title||"";subtitle:root.home.continue?.unfinished_attempt?"Unfinished attempt · reasoning and exposure preserved":root.home.continue?.position||"Return to your working context";trailing:"Resume →";onClicked:root.select(root.home.continue)}
     }
     RowLayout {Layout.fillWidth:true;visible:root.section==="Today"&&!root.query&&root.rows.length>0
      Text {text:"SUGGESTED NEXT";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;Layout.fillWidth:true}
      NoesisButton {text:Oasis.quiet?"Show":"Quiet";onClicked:{Oasis.quiet=!Oasis.quiet;Oasis.savePreferences();root.load(false);}}
      NoesisButton {text:"All paths";visible:Oasis.pathScope!=="";onClicked:{Oasis.setPathScope("");root.load(false);}}
     }
     ScrollView {id:todayScroll;visible:root.section==="Today"&&!root.query&&!root.loading&&!root.selected.id&&!Oasis.error;Layout.fillWidth:true;Layout.fillHeight:true;clip:true
     ColumnLayout {width:todayScroll.availableWidth;spacing:NoesisStyle.lg
      Text {visible:!root.home.continue;text:root.home.empty_reason==="no-records"?"Begin with something worth understanding":"Your notes are here. Choose a thread to continue.";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.title;wrapMode:Text.Wrap;Layout.fillWidth:true;Layout.topMargin:NoesisStyle.xl}
      Text {visible:!root.home.continue;text:"This vault has no recorded active work. Saved notes are preserved; they do not imply learning progress.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;Layout.maximumWidth:680;Layout.fillWidth:true}
      Text {visible:(root.home.paths||[]).length>0;text:"Learning paths and courses";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body}
      Repeater {model:root.home.paths||[];delegate:NoesisRow {required property var modelData;Layout.fillWidth:true;title:modelData.title;subtitle:"Open outline · progress is recorded separately";trailing:"Open →";onClicked:root.select(modelData)}}
      Text {text:"Explore your other learning vaults";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;Layout.topMargin:NoesisStyle.sm}
      Text {text:"Today is scoped to the selected vault. Switch to continue recorded work or browse an existing path; your files stay in their original vault.";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.maximumWidth:680;Layout.fillWidth:true}
      Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
       Repeater {model:(Oasis.state.vaults||[]).filter(v=>v.managed&&v.path!==Oasis.activeVault);delegate:NoesisButton {required property var modelData;text:modelData.name+" →";enabled:!Oasis.working;onClicked:Oasis.choose(modelData.path)}}
      }
      Rectangle {Layout.fillWidth:true;Layout.preferredHeight:1;color:NoesisStyle.rule;Layout.topMargin:NoesisStyle.lg}
      Text {text:"Start something";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.heading}
      Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
       NoesisButton {text:"Start a learning path";onClicked:createDialog.begin("path","")}
       NoesisButton {text:"Add a course or book";onClicked:createDialog.begin("resource","")}
       NoesisButton {text:"Import from Zotero";onClicked:zoteroDialog.open()}
       NoesisButton {text:"Browse this vault";onClicked:root.section="Library"}
      }
     }
     }
     Text {visible:root.loading;text:"Loading your workspace…";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
     ListView {id:list;visible:root.section!=="Today"||!!root.query||!!root.selected.id||root.rows.length>0;Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:root.rows;keyNavigationEnabled:true;reuseItems:true;spacing:NoesisStyle.xs
      Keys.onReturnPressed:if(currentIndex>=0)root.select(root.rows[currentIndex])
      delegate:NoesisRow {required property var modelData;required property int index;width:list.width;title:modelData.title||modelData.path;subtitle:modelData.reason||((modelData.source_kind||modelData.type||"")+(modelData.status?" · "+modelData.status:""));highlighted:root.selected.id===modelData.id;onClicked:{list.currentIndex=index;root.select(modelData);}}
      ScrollBar.vertical:ScrollBar {}
      NoesisEmpty {anchors.centerIn:parent;width:Math.min(560,parent.width);visible:!root.loading&&root.rows.length===0&&!(root.section==="Today"&&!root.query);title:root.query?"No matching records":root.section==="Today"?root.home.continue?"Room for curiosity":"Your learning has a home":"Start with a question";description:root.query?"Try a title, concept, identifier or a word from your notes.":root.section==="Today"?"Capture something worth exploring, choose a path, or resume when you are ready. No backlog to catch up with.":"Save a source or a thought now. You can organize and connect it as you work.";action:root.query?"Clear search":"Quick capture";onActivated:{if(root.query)search.text="";else root.quickCapture();}}
     }
     NoesisButton {visible:root.cursor!=="";text:"Load 50 more";onClicked:root.load(true);Layout.bottomMargin:NoesisStyle.xl}
    }
    Rectangle {visible:!!root.selected.id;Layout.preferredWidth:1;Layout.fillHeight:true;color:NoesisStyle.rule
     MouseArea {anchors.fill:parent;anchors.margins:-4;cursorShape:Qt.SplitHCursor;property real startX:0;property real startRatio:0;onPressed:mouse=>{startX=mapToItem(root,mouse.x,mouse.y).x;startRatio=Oasis.listRatio;}onPositionChanged:mouse=>{if(pressed)Oasis.listRatio=Math.min(.5,Math.max(.22,startRatio+(mapToItem(root,mouse.x,mouse.y).x-startX)/Math.max(1,root.width-168)));}onReleased:Oasis.savePreferences()}
    }
    ColumnLayout {visible:!!root.selected.id;Layout.fillWidth:true;Layout.fillHeight:true;Layout.margins:NoesisStyle.xl;spacing:NoesisStyle.md
     RowLayout {Layout.fillWidth:true
      ColumnLayout {Layout.fillWidth:true;spacing:NoesisStyle.xs
       Text {text:String(root.selected.source_kind||root.selected.type||"context").toUpperCase();color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
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
     ScrollView {id:readScroll;visible:root.contextTab==="Read";Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumHeight:0;clip:true
      ColumnLayout {id:readingColumn;width:readScroll.availableWidth;spacing:NoesisStyle.md
     Label {visible:!!root.workflow.counts&&root.contextTab==="Read";text:{let c=root.workflow.counts;if(!c)return "";if(root.workflow.kind==="path")return "Path steps "+c.other_units.consumed+" / "+c.other_units.total+" consumed · tasks "+c.assignments.reported_success+" / "+c.assignments.total+" reported success";if(root.selected.source_kind==="book")return "Chapters / sections "+c.other_units.consumed+" / "+c.other_units.total+" read · exercises "+c.assignments.reported_success+" / "+c.assignments.total+" reported success";return "Lectures "+c.lectures.consumed+" / "+c.lectures.total+" · readings "+c.readings.consumed+" / "+c.readings.total+"\nAssignments "+c.assignments.reported_success+" / "+c.assignments.total+" reported success · projects "+c.projects.reported_success+" / "+c.projects.total;}color:NoesisStyle.secondary;wrapMode:Text.Wrap;Layout.fillWidth:true;font.family:NoesisStyle.uiFont}
     ListView {visible:root.contextTab==="Read"&&["course","path"].includes(root.workflow.kind)&&root.relations.length>0&&!root.referenceHidden;Layout.fillWidth:true;Layout.preferredHeight:Math.min(240,root.relations.length*NoesisStyle.row);clip:true;model:root.referenceHidden?[]:root.relations.filter(r=>["contains","orders","assigns","pursues"].includes(r.relation))
      delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:modelData.other_title||modelData.other_id;subtitle:(modelData.other_type||"step")+(modelData.other_status?" · "+modelData.other_status:"");enabled:!!modelData.other_path;onClicked:root.select({id:modelData.other_id,path:modelData.other_path,title:modelData.other_title,type:modelData.other_type})}
      ScrollBar.vertical:ScrollBar {}
     }
     Text {visible:root.contextTab==="Read"&&["paper","project","experiment"].includes(root.workflow.kind)&&root.relations.length>0&&!root.referenceHidden;text:root.workflow.kind==="paper"?"Questions and implementations":"Runs, evidence and source context";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;Layout.fillWidth:true}
     ListView {visible:root.contextTab==="Read"&&["paper","project","experiment"].includes(root.workflow.kind)&&root.relations.length>0&&!root.referenceHidden;Layout.fillWidth:true;Layout.preferredHeight:Math.min(240,root.relations.length*NoesisStyle.row);clip:true;model:root.referenceHidden?[]:root.relations
      delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:modelData.other_title||modelData.other_id;subtitle:(modelData.other_type||"context")+(modelData.other_status?" · "+modelData.other_status:"");enabled:!!modelData.other_path&&!root.referenceHidden;onClicked:root.select({id:modelData.other_id,path:modelData.other_path,title:modelData.other_title,type:modelData.other_type})}
      ScrollBar.vertical:ScrollBar {}
     }
     Text {visible:!!root.selected.code_snapshot;Layout.fillWidth:true;wrapMode:Text.Wrap;text:{let code=root.selected.code_snapshot;if(!code)return "";if(code.availability==="unavailable")return "Code unavailable · "+code.repository;return "Code · "+(code.commit?code.commit.slice(0,12):"no committed revision yet")+(code.dirty?" · uncommitted changes present":" · clean working tree")+"
Observed "+(code.observed_at||"");}color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
     ColumnLayout {visible:root.workflow.kind==="capability";Layout.fillWidth:true;spacing:NoesisStyle.sm
      Text {text:"Assessment criteria";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
      Repeater {model:root.workflow.criteria||[];delegate:Text {required property var modelData;text:"• "+String(modelData);color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;Layout.fillWidth:true}}
      Text {text:"Learner evidence decisions · scoped, never a mastery percentage";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;Layout.fillWidth:true;wrapMode:Text.Wrap}
      Repeater {model:root.workflow.evidence||[];delegate:NoesisRow {required property var modelData;Layout.fillWidth:true;title:(modelData.decision||"Unavailable")+" · "+(modelData.criterion||"evidence");subtitle:(modelData.outcome||"unknown")+" · "+(modelData.assistance||["unknown"]).join(", ")+" · "+(modelData.scope||"scope unknown");enabled:!!modelData.path&&!root.referenceHidden;onClicked:Oasis.note(modelData.path)}}
     }
     Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
      NoesisButton {text:root.selected.source_kind==="video"||root.selected.source_kind==="playlist"?"Continue video ↗":root.selected.local_file||root.selected.zotero_attachment_key?"Open PDF ↗":"Open source ↗";enabled:!root.referenceHidden;visible:["paper","resource","course","unit"].includes(root.selected.type);onClicked:Oasis.run(["read-resource",root.selected.path,"--target-id",root.selected.id,"--reader",root.selected.zotero_uri?"zotero":"sioyek"])}
      NoesisButton {text:"Open problem ↗";visible:root.selected.source_kind==="problem-statement"&&!!root.selected.source;onClicked:Oasis.run(["read-resource",root.selected.path,"--target-id",root.selected.id])}
      NoesisButton {text:"Open implementation ↗";visible:!!root.selected.repository||!!root.selected.code_snapshot?.repository;enabled:!root.referenceHidden&&!Oasis.working;onClicked:Oasis.run(["open-project",root.selected.id])}
      NoesisButton {text:"Actions";hint:"Ctrl+.";enabled:root.contextActions().length>0;onClicked:actionDialog.begin(root.contextActions())}
     }
     RowLayout {Layout.fillWidth:true;visible:root.selected.source_kind==="paper"||root.selected.type==="paper"
      Text {text:"Reading pass";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
      NoesisSelect {id:readingPass;model:["survey","detail","reconstruct","verify"];Layout.fillWidth:true;Accessible.name:"Reading pass"}
     }
     RowLayout {Layout.fillWidth:true;visible:root.contextTab==="Read"&&["paper","resource","course","unit"].includes(root.selected.type)
      NoesisSelect {id:locatorKind;model:["location","page","section","exercise","timestamp"];Layout.preferredWidth:110;Accessible.name:"Resume location kind"}
      NoesisField {id:position;Layout.fillWidth:true;placeholderText:"Resume at page, section or timestamp"}
      NoesisButton {text:"Save place";enabled:!Oasis.working;onClicked:root.saveEvent("study",{state:root.studyUpdate()})}
     }
     Text {visible:root.contextTab==="Read";text:"Equations, diagrams and editing open in Obsidian.";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;wrapMode:Text.Wrap;Layout.fillWidth:true}       TextArea {Layout.fillWidth:true;Layout.preferredHeight:implicitHeight;text:root.referenceHidden?root.workflow.statement||"Reference hidden. Reconstruct before revealing.":root.body;readOnly:true;textFormat:TextEdit.MarkdownText;wrapMode:TextEdit.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;background:null;selectByMouse:true;Accessible.name:"Reading preview";onLinkActivated:link=>{if(/^https?:\/\//.test(link))Quickshell.execDetached(["xdg-open",link]);}}
      }
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
      delegate:NoesisRow {required property var modelData;width:ListView.view.width;rightPadding:["attempt","review"].includes(modelData.event)?140:NoesisStyle.md;NoesisButton {anchors.right:parent.right;anchors.verticalCenter:parent.verticalCenter;text:"Use as evidence";visible:["attempt","review"].includes(modelData.event);enabled:!root.referenceHidden;onClicked:evidenceDialog.begin(modelData)}title:modelData.event+" · "+(modelData.criterion||modelData.outcome||modelData.integrity||"")+(modelData.decision?" · "+modelData.decision:"");subtitle:(modelData.assistance||["unknown"]).join(", ")+" · "+modelData.timestamp;enabled:!root.referenceHidden;onClicked:Oasis.note(modelData.path)}
      NoesisEmpty {anchors.centerIn:parent;width:parent.width;visible:root.history.length===0;title:"History begins with real work";description:"Positions, predictions, attempts and comparisons will appear here. Nothing is inferred from a saved note."}
      ScrollBar.vertical:ScrollBar {}
     }
     ListView {visible:root.contextTab==="Connections";Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:root.relations;spacing:NoesisStyle.xs
      delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:modelData.other_title||modelData.other_id;subtitle:modelData.relation+(modelData.role?" · "+modelData.role:"");enabled:!!modelData.other_path&&!root.referenceHidden;onClicked:root.select({id:modelData.other_id,path:modelData.other_path,title:modelData.other_title,type:modelData.other_type})}
      NoesisEmpty {anchors.centerIn:parent;width:parent.width;visible:root.relations.length===0;title:"Connect the next question";description:"Related resources, prerequisites, implementations and evidence stay linked even when notes move."}
     }

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
    Text {text:Oasis.working?(["read-resource","open-project"].includes(Oasis.operationKind)?"Opening…":"Saving…"):Oasis.error||Oasis.message;color:Oasis.error?NoesisStyle.accent:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
    NoesisButton {text:"Stop";visible:Oasis.working;onClicked:Oasis.cancel()}
   }
  }
 }
 NoesisDialog {id:comparisonDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(560,root.width-48);modal:true;title:"Compare prediction with observation"
  property bool submitting:false
  property var target:({})
  property string vaultScope:""
  onOpened:{target=Object.assign({},root.selected);vaultScope=Oasis.activeVault;predicted.text=target.hypothesis||"";observed.forceActiveFocus();}
  background:Rectangle {color:NoesisStyle.surface;radius:NoesisStyle.radius;border.width:1;border.color:NoesisStyle.rule}
  contentItem:ColumnLayout {spacing:NoesisStyle.md
   NoesisField {id:predicted;Layout.fillWidth:true;placeholderText:"Original prediction or hypothesis"}
   NoesisField {id:observed;Layout.fillWidth:true;placeholderText:"Observed result, with units and uncertainty"}
   NoesisField {id:conditions;Layout.fillWidth:true;placeholderText:"Configuration and code commit · optional"}
   NoesisEditor {id:conclusion;Layout.fillWidth:true;Layout.preferredHeight:120;placeholderText:"Discrepancy, evidence and what to test next…"}
   Text {text:"A successful run does not establish the hypothesis. This preserves the comparison as reported evidence.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
   NoesisButton {id:saveComparison;text:"Save comparison";hint:"Ctrl+Enter";primary:true;enabled:predicted.text.trim()!==""&&observed.text.trim()!==""&&conclusion.text.trim()!==""&&!Oasis.working&&comparisonDialog.vaultScope===Oasis.activeVault;onClicked:{comparisonDialog.submitting=true;Oasis.run(["event",comparisonDialog.target.path,"comparison","--target-id",comparisonDialog.target.id,"--evidence",conclusion.text,"--data",JSON.stringify({prediction:predicted.text,observed:observed.text,configuration:conditions.text,code_snapshot:comparisonDialog.target.code_snapshot||null,conclusion:conclusion.text,assessment:"learner-reported"})]);}}
  }
  Shortcut {sequence:"Ctrl+Return";enabled:comparisonDialog.visible;onActivated:if(saveComparison.enabled)saveComparison.clicked()}
  Connections {target:Oasis;function onFinished(ok){if(comparisonDialog.submitting){comparisonDialog.submitting=false;if(ok){comparisonDialog.close();predicted.text="";observed.text="";conditions.text="";conclusion.text="";}}}}
 }
 NoesisDialog {id:reviewDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(440,root.width-48);modal:true;title:"Plan a later check"
  property bool submitting:false
  property var target:({})
  property string vaultScope:""
  onOpened:{target=Object.assign({},root.selected);vaultScope=Oasis.activeVault;checkPurpose.forceActiveFocus();}
  background:Rectangle {color:NoesisStyle.surface;radius:NoesisStyle.radius;border.width:1;border.color:NoesisStyle.rule}
  contentItem:ColumnLayout {spacing:NoesisStyle.lg
   NoesisSelect {id:checkStage;model:["retry","later","maintenance"];Layout.fillWidth:true}
   NoesisSelect {id:checkAction;model:["schedule","snooze","retire"];Layout.fillWidth:true}
   NoesisEditor {id:checkPurpose;Layout.fillWidth:true;Layout.preferredHeight:100;placeholderText:"What will you reconstruct or verify?"}
   Text {text:"Defaults: 1, 7 or 30 days. A convenience policy, not a competence estimate.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
   NoesisButton {id:saveReview;text:"Save plan";hint:"Ctrl+Enter";primary:true;enabled:checkPurpose.text.trim()!==""&&!Oasis.working&&reviewDialog.vaultScope===Oasis.activeVault;onClicked:{reviewDialog.submitting=true;Oasis.run(["event",reviewDialog.target.path,"review-plan","--target-id",reviewDialog.target.id,"--evidence",checkPurpose.text,"--data",JSON.stringify({stage:checkStage.currentText,action:checkAction.currentText})]);}}
  }
 }
 Shortcut {sequence:"Ctrl+Return";enabled:reviewDialog.visible;onActivated:if(saveReview.enabled)saveReview.clicked()}
 Connections {target:Oasis;function onFinished(ok){if(reviewDialog.submitting){reviewDialog.submitting=false;if(ok){reviewDialog.close();checkPurpose.text="";}}}}
 NoesisZoteroDialog {id:zoteroDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(620,root.width-48);height:Math.min(480,root.height-80);onImported:record=>{let paths=(record.created||[]).concat(record.existing||[]);if(paths.length)root.select({id:record.resource_id,path:paths[0],type:"paper"});}}
 NoesisEvidenceDialog {id:evidenceDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(560,root.width-48);onLookup:query=>{root.capabilitySerial=root.send("query",{kind:["capability"],query:query});};onInspect:identity=>{evidenceDialog.selected=({});evidenceDialog.loading=true;root.capabilityDetailSerial=root.send("record",{record_id:identity});}}
 NoesisActionDialog {id:actionDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(520,root.width-48);onChosen:action=>root.contextAction(action)}
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
