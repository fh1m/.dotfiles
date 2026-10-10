import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
 id:root
 color:NoesisStyle.surface
 property string section:NoesisController.workspace
 property string learnGroup:"Paths & courses"
 property var home:({})
 property bool collectionScope:NoesisController.collectionScope
 onCollectionScopeChanged:{NoesisController.collectionScope=collectionScope;NoesisController.savePreferences();}
 property var pendingSelection:({})
 function applyLaunch(){let request=NoesisController.openRequest;if(!request.request_id||!worker.running)return;if(request.vault&&request.vault!==NoesisController.activeVault)return;if(request.record){root.section=request.surface||({concept:"Learn",question:"Learn",capability:"Learn",paper:"Research",resource:request.record.source_kind==="paper"?"Research":"Learn",course:"Learn",unit:"Learn",task:"Practice",problem:"Practice",project:"Lab",experiment:"Lab",lab:"Lab"})[request.record.type]||"Library";root.select(Object.assign({},request.record,{id:request.record.record_id}));}if(request.action==="capture")quickCapture();if(request.action==="start")startLearning();NoesisController.markRequest(request.request_id,"ready");NoesisController.openRequest=({});}

 property bool loading:false
 property bool contextLoading:false
 property bool inspectorOpen:false
 property bool focusMode:false
 property bool windowLayerOpen:false
 function toggleFocus(){focusMode=!focusMode;if(focusMode){browseOpen=false;query="";search.text="";}}
 property bool browseOpen:false
 property bool readingPlaceOpen:false
 readonly property bool tight:width<720*NoesisStyle.interfaceScale
 readonly property bool compact:width<1100*NoesisStyle.interfaceScale
 readonly property bool wideInspector:width>=1280*NoesisStyle.interfaceScale
 property string contextTab:"Read"
 NoesisNavigation {id:route}
 property alias navigation:route.entries
 property alias navigationIndex:route.index
 property var frontier:({items:[]})
 property int frontierSerial:0
 property int claimSerial:0
 readonly property bool convolutionWorking:selected.type==="concept"&&(selected.learning_demo==="convolution-1d"||/^convolution(\b|\s|·)/i.test(selected.title||""))
 readonly property bool investigationWorking:["concept","question","capability"].includes(selected.type)&&["Read","Work"].includes(contextTab)
 readonly property bool readingWorking:contextTab==="Read"&&!!selected.id&&!courseWorking&&!investigationWorking&&!["paper","project","experiment","capability"].includes(workflow.kind)&&["resource","unit","stage","note"].includes(selected.type)
 function loadFrontier(cursor){frontierSerial=send("frontier",{record_id:selected.id,cursor:cursor||null});}
 property bool sourceOnSecondDisplay:false
 onSourceOnSecondDisplayChanged:if(sourceOnSecondDisplay&&activeAttempt)practicePage.showReasoning()
 function reviewPrerequisite(row){readinessDialog.begin(row);}
 property var selected:({})
 property var courseRecord:({})
 property var courseMembers:[]
 property string courseProgress:""
 property string courseCursor:""
 property int courseOutlineSerial:0
 property var restoreView:({})
 property var restoreCourse:({})
 function courseReference(){return courseRecord.id?{id:courseRecord.id,path:courseRecord.path,title:courseRecord.title,type:courseRecord.type,source_kind:courseRecord.source_kind,vault:NoesisController.activeVault,vault_id:courseRecord.vault_id,expanded_module:courseStudio.expandedModule,page_anchor:courseStudio.pageAnchor,outline_anchor:courseStudio.outlineAnchor,lesson_anchor:courseStudio.lessonAnchor}:null;}
 function rememberView(){if(navigationIndex<0||!selected.id||navigation[navigationIndex]?.id!==selected.id)return;let entries=navigation.slice();entries[navigationIndex]=Object.assign({},entries[navigationIndex],{vault:selectedVault,vault_id:selected.vault_id,path:selected.path,title:selected.title,_view:{tab:contextTab,anchor:readScroll.ScrollBar.vertical.position,attempt:activeAttempt,protected:referenceHidden,revealed:revealedAttempt,source_anchor:investigation.sourceAnchor,notes_anchor:investigation.notesAnchor,reasoning_only:investigation.reasoningOnly,mechanism_expanded:investigation.mechanismExpanded,reading_anchor:readingPage.sourceAnchor,reading_notes_anchor:readingPage.notesAnchor,reading_notes_only:readingPage.notesOnly,practice_statement_anchor:practicePage.statementAnchor,practice_reasoning_anchor:practicePage.reasoningAnchor,practice_thinking:practicePage.thinking}});navigation=entries;route.persist();}
 readonly property bool courseWorking:section==="Learn"&&contextTab==="Read"&&!!selected.id&&(workflow.kind==="course"||workflow.kind==="path"||selected.type==="unit")
 function courseOpen(row){if(row.unit_kind==="module"){outlineLoading=true;moduleAppend=false;courseStudio.moduleRows=[];courseStudio.moduleCursor="";moduleSerial=send("outline",{record_id:row.id,cursor:0});courseStudio.expand(row);}else openWork(row);}
 function returnCollection(){flushDrafts();let frame=collectionReturn;selected=({});body="";browseOpen=false;if(frame.section&&frame.section!==section)section=frame.section;query=frame.query||"";search.text=query;collectionRestore=frame;load(false);}
 property var collectionReturn:({})
 property var collectionRestore:({})
 property real collectionAnchor:0
 property int collectionIndex:0
 property string selectedVault:""
 readonly property string ownerLabel:(NoesisController.state.vaults||[]).find(v=>v.path===NoesisController.activeVault)?.name||NoesisController.activeVault.split("/").pop()||"Choose a vault"
 property var rows:[]
 property var history:[]
 property var historyDisplay:[]
 property string historyNewerCursor:""
 property string historyCursor:""
 property bool historyAppend:false
 function loadHistory(older,overrideCursor){let cursor=overrideCursor===undefined?(older?historyCursor:null):overrideCursor;historyAppend=!!cursor;historySerial=send("timeline",{record_id:selected.id,cursor:cursor});}
 property string activeAttempt:""
 property string revealedAttempt:""
 property string revealingTarget:""
 property string captureSubmission:""
 property string captureVault:""
 property var relations:[]
 readonly property var readingRelations:["project","experiment"].includes(workflow.kind)?relations.filter(row=>!(workflow.artifacts||[]).some(artifact=>artifact.id===row.other_id&&(!row.other_vault||row.other_vault===NoesisController.activeVault))):relations
 property var artifactInfo:({})
 property var workflow:({})
 property int annotationSerial:0
 property int revisionSerial:0
 property var sourceRevisions:[]
 property string revisionCursor:""
 property string revisionNewerCursor:""
 function startLearning(){learningStart.begin();}
 function beginRecord(kind,medium){createDialog.begin(kind,"",false,medium);}
 function focusTodayQuiet(){todayPage.focusQuiet();}
 function focusSourceRevision(){researchPage.focusRevision();}
 function loadSourceRevisions(cursor){revisionSerial=send("annotation-revisions",{record_id:selected.id,cursor:cursor});}
 function loadAnnotations(cursor,projection){annotationSerial=send("annotations",{record_id:selected.id,cursor:cursor,projection:projection||workflow.projection||selected.zotero_projection});}
 property var learningContext:({})
 property var activityHead:null
 readonly property bool modalOpen:windowLayerOpen||practicePage.contextOpen||[priorityDialog,navigationActions,pendingExit,navigationDrawer,inspectorDrawer,searchPopup,settingsDialog,attemptSettings,captureDialog,createDialog,prerequisiteDialog,readinessDialog,reviewDialog,comparisonDialog,evidenceDialog,materialDialog,outlineDialog,actionDialog,startDialog].some(dialog=>dialog.opened||dialog.visible)
 readonly property int loadedFigures:experimentContext.loadedFigures
 readonly property bool checkOpen:reviewDialog.opened
 readonly property bool priorityOpen:priorityDialog.opened
 readonly property string checkStageName:checkStage.currentText
 readonly property int checkPurposeLength:checkPurpose.text.length
 readonly property bool checkFocused:checkPurpose.activeFocus
 readonly property bool outlineImportOpen:outlineDialog.opened
 readonly property int expandedModuleRows:courseStudio.moduleRows.length
 readonly property bool outlineEditing:courseStudio.editing
 readonly property int outlineIndex:courseStudio.currentIndex
 readonly property bool outlineFocused:courseStudio.listFocused
 property var outlineRows:[]
 property string outlineCursor:""
 property int outlineSerial:0
 property int outlineAppendSerial:0
 property bool outlineLoading:false
 property var selectedState:({})
 property string body:""
 property var documentPreview:({blocks:[]})
 property string query:""
 property string cursor:""
 property int serial:0
 property int latest:0
 property int appendSerial:0
 property int reconcileSerial:0
 property int detailSerial:0
 property int moduleSerial:0
 property bool moduleAppend:false
 property int historySerial:0
 property int relationSerial:0
 property int prerequisiteSerial:0
 property int capabilitySerial:0
 property int capabilityDetailSerial:0
 property int capabilityClaimsSerial:0
 property string submittedEvidence:""
 property var changedPaths:[]
 property bool reconcileAll:false
 property bool watchTransition:true
 property bool referenceHidden:false
 readonly property string reportedOutcome:outcome.currentText
 readonly property string declaredAssistance:assistance.currentText
 readonly property int captureLength:capture.text.length
 readonly property real readScrollFraction:readScroll.ScrollBar.vertical.position
 readonly property real readViewportHeight:courseWorking?courseStudio.height:readScroll.availableHeight
 readonly property real readContentHeight:readingColumn.implicitHeight
 readonly property bool captureOpen:captureDialog.opened
 readonly property bool captureFocused:capture.activeFocus
 readonly property bool searchFocused:search.activeFocus||compactSearch.activeFocus
 readonly property bool inspectorVisible:inspectorOpen&&!!selected.id&&wideInspector&&!focusMode
 readonly property real listSpace:Math.max(640,width-168-(inspectorVisible?240:0))
 readonly property bool coreRunning:worker.running
 readonly property bool watchRunning:watch.running
 readonly property var evidence:practicePage.editor
 readonly property bool practiceThinking:practicePage.thinking
 readonly property real statementHeight:practicePage.statementHeight
 readonly property real reasoningHeight:evidence.height
 readonly property real reasoningViewportHeight:practicePage.reasoningViewportHeight
 readonly property real practiceViewportHeight:practiceHost.availableHeight
 readonly property real practiceScrollFraction:practiceHost.ScrollBar.vertical.position
 readonly property int previewLength:body.length
 readonly property var sections:["Today","Learn","Research","Practice","Lab","Library"]
 readonly property var kinds:({Learn:["path","stage","course","resource","unit","capability","concept","prerequisite"],Research:["paper","resource","question"],Practice:["task","problem","session","practice-session"],Lab:["project","experiment","lab","artifact"]})
 signal supportingResponse(var response)
 function send(action,extra){
  if(!worker.running||!NoesisController.activeVault)return 0;
  let request=Object.assign({version:1,request_id:++serial,vault:NoesisController.activeVault,action:action},extra||{});
  if(action==="reconcile")reconcileSerial=request.request_id;
  worker.write(JSON.stringify(request)+"\n");return request.request_id;
 }
 function load(append){
  loading=true;let unified=collectionScope&&(section==="Today"||section==="Library"||!!query);
  let action=section==="Today"&&!query?"today":"query";
  latest=send(unified?"collection-"+action:action,{vaults:(NoesisController.state.vaults||[]).filter(v=>v.managed).map(v=>v.path),kind:section==="Learn"&&!query?({"Paths & courses":["path","course","resource"],Concepts:["concept","capability","prerequisite"],Sources:["resource","unit","stage"]})[learnGroup]:kinds[section]||null,query:query,resource_kinds:({Learn:!query&&learnGroup==="Paths & courses"?["course","book","playlist"]:["course","book","playlist","video","lecture"],Research:["paper","journal","preprint","article"]})[section]||null,context_vault:NoesisController.currentContext.vault,context_id:NoesisController.currentContext.vault===NoesisController.activeVault||unified?NoesisController.currentContext.id:null,quiet:NoesisController.quiet,path_id:NoesisController.pathScope||null,cursor:append?cursor:0});appendSerial=append?latest:0;
 }

 function loadOutline(append){if(!selected.id)return;outlineLoading=true;outlineSerial=send("outline",{record_id:selected.id,cursor:append?Number(outlineCursor):0});outlineAppendSerial=append?outlineSerial:0;}
 function openWork(row){rememberView();if(!selected.id)collectionReturn={section:section,query:query,index:list.currentIndex,anchor:list.contentY,vault:NoesisController.activeVault};let surface=({concept:"Learn",question:"Learn",capability:"Learn",paper:"Research",task:"Practice",problem:"Practice",experiment:"Lab",project:"Lab",lab:"Lab",path:"Learn",course:"Learn",unit:"Learn",resource:row.source_kind==="paper"?"Research":"Learn"})[row.type];if(surface)section=surface;select(row);}
 function select(row,fromHistory){
  if(row.vault&&row.vault!==NoesisController.activeVault){if(NoesisController.working){NoesisController.error="Finish the current save before switching context.";return;}stashDraft();pendingSelection=Object.assign({},row,{fromHistory:!!fromHistory});NoesisController.choose(row.vault);return;}
  rememberView();stashDraft();if(fromHistory&&row.surface&&row.surface!==section)section=row.surface;restoreView=fromHistory?(row._view||{}):({});if(!selected.id){collectionAnchor=list.contentY;collectionIndex=list.currentIndex;}if(!fromHistory){browseOpen=false;if(query){query="";search.text="";compactSearch.text="";}}if(!fromHistory&&(row.id!==selected.id||selectedVault!==NoesisController.activeVault)){navigation=navigation.slice(0,navigationIndex+1).concat([Object.assign({},row,{surface:section})]);navigationIndex=navigation.length-1;}contextLoading=true;contextTab=["task","problem"].includes(row.type)?"Work":"Read";let changed=row.id!==selected.id||selectedVault!==NoesisController.activeVault;if(changed){readingPlaceOpen=false;activeAttempt="";revealedAttempt="";revealingTarget="";NoesisController.message="";}if(row.type==="course"||row.type==="path"||row.type==="resource"&&["course","book","playlist"].includes(row.source_kind)){courseRecord=Object.assign({},row);courseMembers=[];}selectedVault=NoesisController.activeVault;selected=Object.assign({},row,{vault:NoesisController.activeVault});NoesisController.currentContext=Object.assign({},row,{vault:NoesisController.activeVault});NoesisController.savePreferences();body="";if(changed)documentPreview=({blocks:[]});artifactInfo=({});workflow=({});frontier=({items:[]});learningContext=({});selectedState=({});history=[];historyDisplay=[];historyCursor="";historyNewerCursor="";evidence.text=NoesisController.drafts[draftKey(row)]||"";relations=[];outlineRows=[];outlineCursor="";outlineSerial=0;moduleSerial=0;annotationSerial=0;revisionSerial=0;sourceRevisions=[];revisionCursor="";revisionNewerCursor="";if(changed)referenceHidden=section==="Practice";if(contextTab==="Work")Qt.callLater(()=>{if(!root.modalOpen)evidence.forceActiveFocus();});if(row.id){detailSerial=send("record",{record_id:row.id});historyCursor="";loadHistory(false);relationSerial=send("relations",{record_id:row.id});loadOutline(false);if(["concept","question","capability"].includes(row.type))loadFrontier();route.persist();}else NoesisController.preview(row.path);}
 function refreshContext(){if(!selected.id)return;let tab=contextTab;select(selected,true);contextTab=tab;}
 function draftKey(row){return (row.id===selected.id?selectedVault:NoesisController.activeVault)+":"+row.id;}
 function stashDraft(){if(selected.id){let next=Object.assign({},NoesisController.drafts);next[draftKey(selected)]=evidence.text;NoesisController.drafts=next;NoesisController.savePreferences();}}
 function back(){rememberView();if(navigationIndex>0){navigationIndex--;select(navigation[navigationIndex],true);}else if(selected.id)returnCollection();}
 function forward(){rememberView();if(navigationIndex+1<navigation.length){navigationIndex++;select(navigation[navigationIndex],true);}}
 function quickCapture(){captureVault=NoesisController.activeVault;capture.text=NoesisController.drafts[captureVault+":capture"]||"";captureDialog.open();capture.forceActiveFocus();}
 function submitCapture(){if(root.captureVault!==NoesisController.activeVault){NoesisController.error="Vault changed. Return to the capture’s vault before saving.";return;}root.captureSubmission=capture.text;NoesisController.run(["capture",capture.text]);}
 function courseSummary(){let c=workflow.counts;if(!c)return "";let material=[],assessment=[];if(c.lectures.total)material.push("Lectures "+c.lectures.consumed+" / "+c.lectures.total+" viewed");if(c.readings.total)material.push("Readings "+c.readings.consumed+" / "+c.readings.total+" read");if(c.other_units.total)material.push((selected.source_kind==="book"?"Chapters / sections ":workflow.kind==="path"?"Path steps ":"Other units ")+c.other_units.consumed+" / "+c.other_units.total+" consumed");if(c.assignments.total)assessment.push((selected.source_kind==="book"?"Exercises ":"Assignments ")+c.assignments.reported_success+" / "+c.assignments.total+" reported success");if(c.projects.total)assessment.push("Projects "+c.projects.reported_success+" / "+c.projects.total+" reported success");return [material.join(" · "),assessment.join(" · ")].filter(line=>line!=="").join("\n")||"No outline recorded yet. Add lessons, readings or problems as you work.";}
 function openSource(){NoesisController.run(["read-resource",selected.path,"--target-id",selected.id,"--reader",selected.zotero_uri?"zotero":"sioyek"]);}
 function studyUpdate(status){let state={};if(position.text.trim()||!status)state=locatorKind.currentText==="location"?{position:position.text}:{locator:{kind:locatorKind.currentText,value:position.text}};if(root.selected.source_kind==="paper"||root.selected.type==="paper")state.reading_pass=readingPass.currentText;if(status)state.status=status;return state;}
 function pendingCheck(){
  let referenced=new Set();history.forEach(event=>{if(event.previous_plan)referenced.add(event.previous_plan);(event.resolves_plans||[]).forEach(id=>referenced.add(id));});
  let heads=history.filter(event=>event.event==="review-plan"&&!referenced.has(event.id));
  if(heads.length!==1||heads[0].action==="retire"||history.some(event=>["attempt","review"].includes(event.event)&&["failed","partial","succeeded"].includes(event.outcome)&&event.review_plan_id===heads[0].id))return null;
  return heads[0];
 }
 function contextActions(){
  let items=[];let add=(action,label,reason)=>items.push({action:action,label:label,reason:reason||""});let kind=selected.type;
  if(!selected.id||NoesisController.working)return items;
  if(["task","problem"].includes(kind)&&history.some(event=>["attempt","review"].includes(event.event))&&!referenceHidden&&!activeAttempt)add("evidence","Review latest evidence","Judge a scoped result against a capability criterion");
  if(!referenceHidden)add("question","Ask a question","Preserve the uncertainty and your current explanation");
  if(["paper","task","problem","concept","question"].includes(workflow.kind)||["task","problem","concept","question","resource","unit","course"].includes(kind)){if(!activeAttempt)add("implementation","Connect implementation","Connect your own Git repository; no code is executed");}
  if(["path","course","resource"].includes(kind)||kind==="unit"&&selected.unit_kind==="module")add("unit","Add lesson or chapter","Each unit keeps its own position and history");
  if(["path","course","resource","unit"].includes(kind))add("task","Add problem","Assessment stays separate from consumption");
  if(["project","experiment","lab"].includes(kind))add("run","Add experiment run","Preserve a new prediction and code revision");
  if(["paper","project","experiment","lab"].includes(kind)||selected.source_kind==="paper")add("artifact","Connect data, figure or code","Reference the original output without copying it");
  if(["experiment","lab"].includes(kind))add("comparison","Compare prediction and observation","Record units, uncertainty and the next test");
  if(["paper","unit"].includes(kind)||kind==="resource"&&selected.source_kind!=="course")add("consumed",selected.unit_kind==="lecture"||selected.unit_kind==="video"?"Lecture viewed":"Finished reading","Consumption does not award capability");
  if(["paper","resource","course","unit"].includes(kind))add("pause",selectedState.status==="parked"?"Resume reading":"Pause reading","Keep the resume place and all learning history");
  if(["path","concept","question"].includes(kind))add("capability","Define a capability","Describe an ability and its assessment criteria");
  if(["task","problem"].includes(kind)){if(!activeAttempt)add("attempt-start","Start an attempt","Preserve reasoning before checking a reference");else{if(evidence.text.trim())add("attempt-save","Save outcome","Record the reported result and assistance separately");add("reference",referenceHidden?"Reveal reference":"Hide reference","Reference exposure stays in the attempt history");}add("check","Plan an independent check","Reconstruct later against a specific criterion");}
  if(["task","problem"].includes(kind)&&!activeAttempt)add("transfer","Try a changed problem","Create a separate task to test transfer; earlier attempts stay intact");
  if(kind==="path")add("path","Use path for Today","Suggestions use this path’s frontier and gates");
  if(selected.bibliography_projection&&!referenceHidden)add("bibliography","Open bibliography","Zotero-owned projection stays separate from your analysis");
  if(kind==="artifact")add("checksum","Check checksum","Inspect the referenced artifact without changing it");
  if(["task","problem"].includes(kind)&&!activeAttempt&&pendingCheck())add("perform-check","Perform planned check","Start a protected assessment of your selected check; saving the outcome preserves its result");
  if(kind==="unit"&&[undefined,null,"lecture","video","reading","chapter","section"].includes(selected.unit_kind)&&!referenceHidden)add("material","Replace lesson material","Keep this lesson and its history; start the new source without inheriting completion");
  if(["unit","stage","task","problem","concept","question"].includes(kind)&&!referenceHidden)add("prerequisite","Connect a prerequisite","Reuse an existing concept or problem; explain why it matters here");
  if(["task","problem"].includes(kind))add("attempt-settings","Attempt settings","Choose the mode, reported outcome and declared assistance");
  if(!["activity","relationship","artifact"].includes(kind))add("priority","Today priority","Pin, prioritize or quiet eligible work without changing completion");
  add("history","Learning history","Inspect preserved attempts, notes and evidence");add("connections","Connected context","Inspect source, prerequisites and related work");return items;
 }
 function contextAction(action){
  if(action==="history")contextTab="History";else if(action==="connections")contextTab="Connections";else if(action==="evidence"){let entry=history.slice().reverse().find(event=>["attempt","review"].includes(event.event));if(entry)evidenceDialog.begin(entry);}
  else if(action==="perform-check"){let plan=pendingCheck();if(plan){contextTab="Work";saveEvent("attempt-start",{mode:mode.currentText,scope:selected.title||selected.path,review_plan_id:plan.id});}}
  else if(action==="attempt-settings")attemptSettings.open();
  else if(action==="priority")priorityDialog.begin();
  else if(action==="prerequisite")prerequisiteDialog.begin(root.selected);
  else if(action==="material")materialDialog.begin(root.selected,root.activityHead);
  else if(action==="transfer")createDialog.begin("task",selected.id,true);
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
  else if(action==="path")NoesisController.setPathScope(selected.id);
  else if(action==="bibliography")NoesisController.note(selected.bibliography_projection);
  else if(action==="checksum")NoesisController.run(["artifact-check",selected.id]);
 }
 function saveEvent(event,data){submittedEvidence=evidence.text;if(activeAttempt&&event!=="attempt-start")data.attempt_id=activeAttempt;NoesisController.run(["event",selected.path,event,"--target-id",selected.id,"--evidence",evidence.text,"--data",JSON.stringify(data)]);}
 onSectionChanged:{courseRecord=({});courseMembers=[];courseProgress="";actionDialog.close();startDialog.close();stashDraft();NoesisController.workspace=section;NoesisController.savePreferences();selected=({});history=[];relations=[];detailSerial=0;historySerial=0;annotationSerial=0;revisionSerial=0;sourceRevisions=[];revisionCursor="";revisionNewerCursor="";relationSerial=0;outlineSerial=0;outlineRows=[];body="";documentPreview=({blocks:[]});query="";search.text="";load(false);}
 Component.onCompleted:watch.running=NoesisController.windowOpen&&NoesisController.activeVault!==""
 function flushDrafts(){rememberView();route.persist();draftSave.stop();captureDraftSave.stop();stashDraft();if(captureDialog.opened){let next=Object.assign({},NoesisController.drafts);next[captureVault+":capture"]=capture.text;NoesisController.drafts=next;}if(selected.id){NoesisController.currentContext=Object.assign({},NoesisController.currentContext,{surface:section,context_tab:contextTab,read_anchor:readScroll.ScrollBar.vertical.position,course:root.courseReference()});}NoesisController.savePreferences();}
 Connections {target:NoesisController;
  function onFlushRequested(){root.flushDrafts();}
  function onOpenRequestChanged(){root.applyLaunch();}

  function onWindowOpenChanged(){root.watchTransition=true;watch.running=NoesisController.windowOpen&&NoesisController.activeVault!=="";}
  function onCaptureRequested(){root.quickCapture();}
  function onActiveVaultChanged(){root.courseRecord=({});root.courseMembers=[];root.courseProgress="";root.stashDraft();priorityDialog.close();captureDialog.close();evidenceDialog.close();capabilitySerial=0;capabilityDetailSerial=0;capabilityClaimsSerial=0;actionDialog.close();startDialog.close();prerequisiteDialog.close();readinessDialog.close();createDialog.close();outlineDialog.close();reviewDialog.close();comparisonDialog.close();root.watchTransition=true;watch.running=false;refresh.stop();root.changedPaths=[];root.reconcileAll=false;Qt.callLater(()=>{watch.running=NoesisController.windowOpen&&NoesisController.activeVault!=="";root.applyLaunch();});root.rows=[];root.selected=({});root.body="";root.documentPreview=({blocks:[]});root.history=[];root.detailSerial=0;root.historySerial=0;annotationSerial=0;revisionSerial=0;sourceRevisions=[];revisionCursor="";revisionNewerCursor="";root.relationSerial=0;root.outlineSerial=0;root.outlineRows=[];if(worker.running)root.send("reconcile");if(root.pendingSelection.vault===NoesisController.activeVault){let pending=root.pendingSelection;root.pendingSelection=({});Qt.callLater(()=>root.select(pending,pending.fromHistory));}}
  function onFinished(ok){if(root.revealingTarget){if(ok&&NoesisController.operationResult.event==="assistance"&&NoesisController.operationResult.target?.record_id===root.revealingTarget&&root.selected.id===root.revealingTarget){root.revealedAttempt=root.activeAttempt;root.referenceHidden=false;}root.revealingTarget="";}if(ok){if(NoesisController.operationResult.event==="attempt-start"&&NoesisController.operationResult.target?.record_id===root.selected.id){root.activeAttempt=NoesisController.operationResult.id;root.referenceHidden=true;outcome.currentIndex=0;assistance.currentIndex=0;}else if(NoesisController.operationResult.event==="attempt"&&NoesisController.operationResult.target?.record_id===root.selected.id){root.activeAttempt="";root.revealedAttempt="";root.referenceHidden=false;if(evidence.text===root.submittedEvidence){evidence.text="";root.stashDraft();}}root.send("reconcile");root.refreshContext();}}
 }
 Process {
  id:worker;command:["@HOME@/.local/bin/noesis","serve","--stdio"];stdinEnabled:true;running:NoesisController.windowOpen
  onStarted:{if(root.navigationIndex<0)route.restore();root.send("reconcile");root.applyLaunch();if(NoesisController.currentContext.vault===NoesisController.activeVault&&NoesisController.currentContext.id){let saved=NoesisController.currentContext;if(saved.course?.vault===NoesisController.activeVault&&saved.course.id){root.courseRecord=saved.course;root.restoreCourse=saved.course;root.courseOutlineSerial=root.send("outline",{record_id:saved.course.id,cursor:0});}let frame=root.navigation[root.navigationIndex];let view=frame?.id===saved.id&&frame?.vault===saved.vault?frame._view||{}:{};root.select(Object.assign({},saved,{_view:view}),true);root.restoreView=Object.assign({},view,{tab:saved.context_tab||view.tab,anchor:saved.read_anchor??view.anchor});}}
  stdout:SplitParser {onRead:line=>{
   try{
    let response=JSON.parse(line);root.supportingResponse(response);if(response.vault&&response.vault!==NoesisController.activeVault)return;
    if(response.error){if(![root.latest,root.detailSerial,root.historySerial,root.annotationSerial,root.revisionSerial,root.relationSerial,root.reconcileSerial,root.capabilitySerial,root.capabilityDetailSerial,root.capabilityClaimsSerial,root.prerequisiteSerial,root.moduleSerial,root.outlineSerial].includes(response.request_id))return;root.loading=false;root.contextLoading=false;root.outlineLoading=false;NoesisController.error=response.error;return;}
    let result=response.result;
    if(result.errors){if(result.errors.length)NoesisController.error=result.errors.map(issue=>issue.message||"A learning collection could not be read.").join(" · ");root.load(false);root.refreshContext();return;}
    if(response.request_id===root.latest){root.loading=false;root.home=result;if(result.scope_errors?.length)NoesisController.error="Some learning vaults are unavailable. Available results are shown; refresh after recovery.";root.rows=response.request_id===root.appendSerial?Array.from(new Map(root.rows.concat(result.records||[]).map(row=>[row.vault+":"+(row.id||row.path),row])).values()):(result.records||[]);root.cursor=result.cursor===null||result.cursor===undefined?"":String(result.cursor);if(root.collectionRestore.section===root.section){let frame=root.collectionRestore;root.collectionRestore=({});Qt.callLater(()=>{list.currentIndex=Math.min(root.rows.length-1,frame.index||0);list.contentY=Math.max(0,Math.min(list.contentHeight-list.height,frame.anchor||0));});}}
    if(response.request_id===root.detailSerial){root.contextLoading=false;root.body=result.body||"";root.documentPreview=result.preview||({blocks:[]});root.artifactInfo=result.artifact||({});root.workflow=result.overview||({});root.learningContext=result.learning_context||({});root.selectedState=result.state||({});root.activityHead=result.activity_head||null;root.activeAttempt=result.attempt?.id||"";if(root.activeAttempt){root.referenceHidden=root.revealedAttempt!==root.activeAttempt||!(result.attempt_assistance||[]).includes("reference");mode.currentIndex=Math.max(0,mode.model.indexOf(result.attempt.mode||"derive"));}if(!root.activeAttempt&&["concept","question","capability"].includes(result.props?.type))root.referenceHidden=false;if(!root.activeAttempt&&result.props?.practice_mode==="transfer")mode.currentIndex=4;if(result.attempt_conflict)NoesisController.error="Multiple unfinished attempts need explicit resolution.";root.selected=Object.assign({},root.selected,result.props||{},result.effective_source||{},result.resolved_source||{},{path:result.path,title:result.display_title||root.selected.title,vault_id:result.owner?.vault_id});NoesisController.currentContext=Object.assign({},root.selected,{vault:NoesisController.activeVault,session_state:result.state?.status||"",course:root.courseReference()});NoesisController.savePreferences();position.text=String(result.state?.locator?.value??result.state?.position??"");locatorKind.currentIndex=result.state?.locator?Math.max(0,locatorKind.model.indexOf(result.state.locator.kind)):0;readingPass.currentIndex=Math.max(0,readingPass.model.indexOf(result.state?.reading_pass||"survey"));if(result.state?.conflict)NoesisController.error=result.state.conflict;if(root.restoreView.tab){root.contextTab=root.restoreView.tab;if(root.activeAttempt&&root.restoreView.attempt===root.activeAttempt){root.referenceHidden=!(root.restoreView.protected===false&&(result.attempt_assistance||[]).includes("reference"));root.revealedAttempt=root.referenceHidden?"":root.activeAttempt;}let anchor=root.restoreView.anchor;Qt.callLater(()=>readScroll.ScrollBar.vertical.position=Math.min(1-readScroll.ScrollBar.vertical.size,Math.max(0,anchor||0)));investigation.restoreAnchors(root.restoreView);readingPage.restoreAnchors(root.restoreView);practicePage.restoreAnchors(root.restoreView);root.restoreView=({});}if(root.workflow.kind==="paper")root.loadSourceRevisions(null);if(root.workflow.kind==="course"||root.workflow.kind==="path"){if(root.selected.unit_kind!=="module"){root.courseRecord=root.selected;root.courseProgress=root.courseSummary();}}}
    if(response.request_id===root.courseOutlineSerial){root.courseMembers=result.records||[];root.courseCursor=result.cursor===null||result.cursor===undefined?"":String(result.cursor);let module=root.courseMembers.find(row=>row.id===root.restoreCourse.expanded_module);if(module)root.courseOpen(module);Qt.callLater(()=>courseStudio.restoreAnchors(root.restoreCourse));}
    if(response.request_id===root.outlineSerial){root.outlineLoading=false;root.outlineRows=response.request_id===root.outlineAppendSerial?root.outlineRows.concat(result.records||[]):result.records||[];root.outlineCursor=result.cursor===null||result.cursor===undefined?"":String(result.cursor);if(root.selected.id===root.courseRecord.id){root.courseMembers=root.outlineRows;root.courseCursor=root.outlineCursor;}}
    if(response.request_id===root.moduleSerial){root.outlineLoading=false;let outline=courseStudio;outline.moduleRows=root.moduleAppend?outline.moduleRows.concat(result.records||[]):result.records||[];outline.moduleCursor=result.cursor===null||result.cursor===undefined?"":String(result.cursor);}
    if(response.request_id===root.capabilitySerial){evidenceDialog.capabilities=result.records||[];evidenceDialog.loading=false;}
    if(response.request_id===root.capabilityClaimsSerial&&evidenceDialog.visible){evidenceDialog.appendClaims(result);}
    if(response.request_id===root.capabilityDetailSerial){evidenceDialog.detail(result);evidenceDialog.loading=false;}
    if(response.request_id===root.historySerial){root.historyDisplay=result.activities||[];if(!root.historyAppend)root.history=root.historyDisplay;root.historyCursor=result.cursor||"";root.historyNewerCursor=result.newer_cursor||"";Qt.callLater(()=>historyView.positionViewAtBeginning());}
    if(response.request_id===root.annotationSerial){root.workflow=Object.assign({},root.workflow,result);}
    if(response.request_id===root.revisionSerial){root.sourceRevisions=result.revisions||[];root.revisionCursor=result.cursor||"";root.revisionNewerCursor=result.newer_cursor||"";}
    if(response.request_id===root.claimSerial)root.workflow=Object.assign({},root.workflow,result);
    if(response.request_id===root.frontierSerial)root.frontier=result;
    if(response.request_id===root.relationSerial)root.relations=result.relationships||[];
    if(response.request_id===root.prerequisiteSerial)prerequisiteDialog.results(result.records||[]);
   }catch(error){NoesisController.error="Query response failed: "+String(error);}
  }}
  stderr:StdioCollector {onStreamFinished:if(text.trim())NoesisController.error=text.trim()}
 }
 Process {id:watch;command:["@HOME@/.local/bin/sensei-learning-watch",NoesisController.activeVault];stdout:SplitParser {onRead:line=>{
  try{let event=JSON.parse(line);root.reconcileAll=root.reconcileAll||event.reconcile;root.changedPaths=Array.from(new Set(root.changedPaths.concat(event.paths||[])));}
  catch(error){NoesisController.error=line;root.reconcileAll=true;}
  refresh.restart();
 }}
  onStarted:root.watchTransition=false
  stderr:StdioCollector {onStreamFinished:if(text.trim())NoesisController.error="Filesystem watch failed; refresh to reconcile."}
  onExited:code=>{if(code!==0&&NoesisController.windowOpen&&!root.watchTransition)NoesisController.error="Filesystem watch stopped; refresh to reconcile."}}
 Timer {id:refresh;interval:250;onTriggered:{root.send("reconcile",{paths:root.reconcileAll||root.changedPaths.length>1000?null:root.changedPaths});root.changedPaths=[];root.reconcileAll=false;}}
 Timer {id:searchDelay;interval:150;onTriggered:root.load(false)}
 Shortcut {sequence:"Ctrl+Return";enabled:!(root.convolutionWorking&&root.investigationWorking)&&root.contextTab==="Work"&&!!root.selected.id&&!NoesisController.working&&!root.modalOpen&&(!root.activeAttempt||evidence.text.trim()!=="");onActivated:root.contextAction(root.activeAttempt?"attempt-save":"attempt-start")}
 Shortcut {sequence:"Ctrl+.";enabled:!!root.selected.id&&!NoesisController.working&&root.contextActions().length>0;onActivated:actionDialog.begin(root.contextActions())}
 Shortcut {sequence:"Ctrl+N";onActivated:root.startLearning()}
 Shortcut {sequence:"Ctrl+Shift+O";enabled:root.section==="Learn";onActivated:outlineDialog.begin(["course","path"].includes(root.workflow.kind)?root.selected:null)}
 Shortcut {sequence:"Ctrl+Shift+K";onActivated:{root.collectionScope=!root.collectionScope;root.load(false);}}
 Shortcut {sequence:"Ctrl+Shift+Return";enabled:!!root.selected.id&&["paper","resource","course","unit"].includes(root.selected.type)&&!root.referenceHidden&&!NoesisController.working;onActivated:root.openSource()}
 Shortcut {sequence:"Ctrl+Alt+Left";enabled:!!root.selected.id&&!root.referenceHidden&&!!root.learningContext.parents?.length&&!NoesisController.working;onActivated:root.select(root.learningContext.parents[0])}
 Shortcut {sequence:"Ctrl+Alt+Down";enabled:!!root.selected.id&&!root.referenceHidden&&!!root.learningContext.prerequisites?.length&&!NoesisController.working;onActivated:root.select(root.learningContext.prerequisites[0])}
 Shortcut {sequence:"Ctrl+Alt+Right";enabled:!!root.selected.id&&!root.referenceHidden&&!!root.learningContext.assignments?.length&&!NoesisController.working;onActivated:root.select(root.learningContext.assignments[0])}
 Shortcut {sequence:"Ctrl+Alt+Up";enabled:!!root.selected.id&&!root.referenceHidden&&!!root.learningContext.next_lesson&&!NoesisController.working;onActivated:root.select(root.learningContext.next_lesson)}
 Shortcut {sequence:"Ctrl+Alt+R";enabled:!!root.selected.id&&!root.referenceHidden&&!NoesisController.working&&(root.learningContext.prerequisites||[]).some(row=>row.role==="gate");onActivated:readinessDialog.begin(root.learningContext.prerequisites.find(row=>row.role==="gate"))}
 Shortcut {sequence:"Ctrl+Shift+P";enabled:["unit","stage","task","problem"].includes(root.selected.type)&&!root.referenceHidden&&!NoesisController.working;onActivated:prerequisiteDialog.begin(root.selected)}
 Shortcut {sequence:"Ctrl+PgDown";enabled:["Read","Work"].includes(root.contextTab)&&!!root.selected.id&&!root.modalOpen;onActivated:{let bar=(root.contextTab==="Work"?practiceHost:readScroll).ScrollBar.vertical;bar.position=Math.min(1-bar.size,bar.position+bar.size*.85);}}
 Shortcut {sequence:"Ctrl+PgUp";enabled:["Read","Work"].includes(root.contextTab)&&!!root.selected.id&&!root.modalOpen;onActivated:{let bar=(root.contextTab==="Work"?practiceHost:readScroll).ScrollBar.vertical;bar.position=Math.max(0,bar.position-bar.size*.85);}}
 Shortcut {sequence:"Ctrl+Shift+F";enabled:!!root.selected.id&&!root.modalOpen;onActivated:root.toggleFocus()}
 Shortcut {sequence:"Escape";enabled:root.focusMode&&!root.modalOpen;onActivated:root.focusMode=false}
 Shortcut {sequence:"Ctrl+K";onActivated:{if(root.compact)searchPopup.open();else search.forceActiveFocus();}}
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
 Timer {id:captureDraftSave;interval:500;onTriggered:{let next=Object.assign({},NoesisController.drafts);next[root.captureVault+":capture"]=capture.text;NoesisController.drafts=next;NoesisController.savePreferences();}}
 Timer {id:draftSave;interval:500;onTriggered:root.stashDraft()}
 RowLayout {
  anchors.fill:parent;spacing:0
  Rectangle {visible:!root.compact&&!root.focusMode;Layout.preferredWidth:Math.max(184,168*NoesisStyle.interfaceScale);Layout.fillHeight:true;color:NoesisStyle.surface
   ColumnLayout {anchors.fill:parent;anchors.margins:NoesisStyle.lg;spacing:NoesisStyle.xs
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"YOUR WORKSPACE";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;Layout.topMargin:NoesisStyle.sm;Layout.bottomMargin:NoesisStyle.md}
    Repeater {model:root.sections;delegate:NoesisButton {required property string modelData;variant:"tertiary";text:modelData;Layout.fillWidth:true;textAlignment:Text.AlignLeft;highlighted:root.section===modelData;onClicked:root.section=modelData;Accessible.name:modelData+" workspace";hint:"Ctrl+"+(root.sections.indexOf(modelData)+1)}}
    Item {Layout.fillHeight:true}
    NoesisButton {text:"Quick capture";visible:root.section!=="Today";Layout.fillWidth:true;textAlignment:Text.AlignLeft;onClicked:root.quickCapture();hint:"Ctrl+Shift+N"}
    NoesisButton {text:"Find anything";Layout.fillWidth:true;textAlignment:Text.AlignLeft;onClicked:search.forceActiveFocus();hint:"Ctrl+K"}
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"VAULT";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;Layout.topMargin:NoesisStyle.lg}
    NoesisSelect {Layout.fillWidth:true;model:(NoesisController.state.vaults||[]).map(v=>v.name);currentIndex:(NoesisController.state.vaults||[]).findIndex(v=>v.path===NoesisController.activeVault);onActivated:{let v=NoesisController.state.vaults[currentIndex];if(v)NoesisController.choose(v.path);}}
   }
  }
  ColumnLayout {Layout.fillWidth:true;Layout.fillHeight:true;spacing:0
   Flow {Layout.fillWidth:true;Layout.margins:NoesisStyle.lg;spacing:Math.round(NoesisStyle.sm*NoesisStyle.interfaceScale)
    NoesisButton {text:"Workspaces";visible:root.compact&&!root.tight&&!root.focusMode;onClicked:navigationDrawer.open()}
    NoesisButton {text:"Navigation";visible:root.compact&&root.tight&&!root.focusMode;onClicked:navigationActions.begin([{action:"workspaces",label:"Choose workspace"},{action:"search",label:"Search learning records"},{action:"return",label:"Return to "+root.section+" collection"},{action:"back",label:"Previous activity",reason:"Alt+Left"},{action:"details",label:"Inspect context"},{action:"forward",label:"Go forward"}])}
    NoesisButton {variant:"tertiary";text:root.focusMode?"Leave focus":"Focus view";highlighted:root.focusMode;visible:!!root.selected.id;hint:"Ctrl+Shift+F";onClicked:root.toggleFocus()}
    NoesisButton {variant:"tertiary";text:"← Back to "+root.section;visible:!!root.selected.id&&!root.tight&&!root.focusMode;onClicked:root.returnCollection()}
    NoesisButton {variant:"tertiary";visible:root.navigationIndex>0&&!root.tight;text:"Previous activity";enabled:!!root.selected.id||root.navigationIndex>0;onClicked:root.back();Accessible.name:"Back";hint:"Alt+Left"}
    NoesisButton {variant:"tertiary";text:"Next in history";visible:!root.tight&&root.navigationIndex+1<root.navigation.length;enabled:root.navigationIndex+1<root.navigation.length;onClicked:root.forward();Accessible.name:"Forward";hint:"Alt+Right"}
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;visible:!root.compact&&!root.selected.id;text:root.section;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.heading;width:Math.max(100,implicitWidth);elide:Text.ElideRight}
    NoesisSelect {visible:root.compact&&!!root.selected.id&&!root.focusMode&&!root.courseWorking&&!root.investigationWorking&&root.section!=="Practice";model:["Read","Work","History","Connections"];currentIndex:model.indexOf(root.contextTab);Accessible.name:"Working page section";onActivated:root.contextTab=currentText}
    NoesisButton {text:"Details";visible:root.compact&&!root.tight&&!!root.selected.id&&!root.focusMode;onClicked:root.inspectorOpen=!root.inspectorOpen}
    NoesisButton {text:"Search";visible:root.compact&&!root.tight&&!root.focusMode;onClicked:searchPopup.open()}
    NoesisField {id:search;visible:!root.compact&&!root.focusMode&&!root.selected.id;Keys.onDownPressed:{list.forceActiveFocus();list.currentIndex=0;}width:Math.min(320,Math.max(180,root.width*.25));placeholderText:"Search · Ctrl+K";onTextChanged:{root.query=text;searchDelay.restart();}Accessible.name:"Search learning records"}
    NoesisButton {text:"+ New";hint:"Ctrl+N · create in this workspace";visible:!root.selected.id&&root.section!=="Today"&&!root.compact&&!root.focusMode;onClicked:{let items=[{action:"resource",label:root.section==="Lab"?"Begin an experiment":root.section==="Practice"?"Begin a problem":"Add a resource"}];if(root.section==="Learn")items=items.concat([{action:"concept",label:"Investigate a concept"},{action:"outline",label:"Import a course outline",reason:"Ctrl+Shift+O"},{action:"path",label:"Start a learning path"}]);if(root.section==="Research")items.push({action:"zotero",label:"Import from Zotero"});items.push({action:"capture",label:"Capture a thought",reason:"Ctrl+Shift+N"});startDialog.begin(items);}}
    NoesisButton {text:"Help";variant:"tertiary";onClicked:helpDialog.open()}
    NoesisButton {text:"Start learning";primary:!root.selected.id;onClicked:root.startLearning()}
    NoesisButton {text:root.collectionScope?"All learning vaults":"This vault";hint:"Ctrl+Shift+K · read scope; saves stay in the owning vault";visible:["Today","Library"].includes(root.section);highlighted:root.collectionScope;onClicked:{root.collectionScope=!root.collectionScope;root.load(false);}}
    NoesisButton {visible:!root.compact&&!root.focusMode;text:"Refresh";onClicked:root.send("reconcile");Accessible.name:"Refresh"}
   }
   SplitView {id:workingSplit;Layout.fillWidth:true;Layout.fillHeight:true;Layout.leftMargin:NoesisStyle.lg;Layout.rightMargin:NoesisStyle.lg;orientation:Qt.Horizontal
    handle:Rectangle {implicitWidth:8;color:SplitHandle.hovered?NoesisStyle.rule:NoesisStyle.surface}
    onResizingChanged:if(!resizing&&collectionPane.visible&&root.selected.id){NoesisController.listRatio=Math.min(.5,Math.max(.22,collectionPane.width/width));NoesisController.savePreferences();}
    ColumnLayout {id:collectionPane;visible:!root.selected.id||root.browseOpen||!!root.query;SplitView.fillWidth:!root.selected.id||root.compact;SplitView.preferredWidth:Math.max(280,workingSplit.width*NoesisController.listRatio);SplitView.minimumWidth:Math.min(280,workingSplit.width);spacing:NoesisStyle.lg
     Flow {visible:root.section==="Learn"&&!root.query;Layout.fillWidth:true;spacing:NoesisStyle.sm
      Repeater {model:["Paths & courses","Concepts","Sources"];delegate:NoesisButton {required property string modelData;text:modelData;highlighted:root.learnGroup===modelData;onClicked:{root.learnGroup=modelData;root.load(false);}}}
     }
     NoesisButton {visible:root.section==="Learn"&&root.learnGroup==="Concepts"&&!root.query;text:"Start a concept";primary:true;onClicked:createDialog.begin("concept","")}
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:root.section!=="Today";textFormat:Text.PlainText;text:({Today:"Pick up a thread. Follow your curiosity.",Learn:"Paths, courses and the ideas that connect them.",Research:"Read with a question. Return with an explanation.",Practice:"Preserve the struggle. Make the next attempt independent.",Lab:"From prediction to measurement.",Library:"Everything saved, ready to connect."})[root.section];color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;Layout.fillWidth:true}
     NoesisTodayPage {id:todayPage;visible:root.section==="Today"&&!root.query&&!root.selected.id&&!root.loading;Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumHeight:0;context:root.home;quiet:NoesisController.quiet;collectionScope:root.collectionScope;pathScoped:NoesisController.pathScope!=="";busy:NoesisController.working
      onOpenContext:row=>root.openWork(row)
      onToggleQuiet:{NoesisController.quiet=!NoesisController.quiet;NoesisController.savePreferences();root.load(false);}
      onClearPathScope:{NoesisController.setPathScope("");root.load(false);}
      onStart:kind=>{if(kind==="start")root.startLearning();else if(kind==="convolution-example")createDialog.beginConvolution();else createDialog.begin(kind==="paper"?"resource":kind,"",false,kind==="paper"?"paper":kind==="resource"?"course":undefined);}
      onBrowse:root.section="Library"
     }
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;visible:root.loading;text:"Loading your workspace…";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
     ListView {id:list;visible:root.section!=="Today"||!!root.query||!!root.selected.id;Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:root.rows;keyNavigationEnabled:true;reuseItems:true;spacing:NoesisStyle.xs
      Keys.onReturnPressed:if(currentIndex>=0)root.openWork(root.rows[currentIndex])
      delegate:NoesisRow {required property var modelData;required property int index;width:list.width;title:modelData.title||modelData.path;subtitle:(modelData.vault_name?modelData.vault_name+" · ":"")+(modelData.reason||((modelData.source_kind||modelData.type||"")+(modelData.status?" · "+modelData.status:"")));highlighted:root.selected.id===modelData.id;onClicked:{list.currentIndex=index;root.openWork(modelData);}}
      ScrollBar.vertical:ScrollBar {}
      NoesisEmpty {id:emptyList;anchors.centerIn:parent;width:Math.min(560,parent.width);visible:list.visible&&!root.loading&&root.rows.length===0&&root.section!=="Today";title:root.query?"No matching records":root.section==="Today"?root.home.continue?"Room for curiosity":"Your learning has a home":"Start with a question";description:root.query?"Try a title, concept, identifier or a word from your notes.":root.section==="Today"?"Capture something worth exploring, choose a path, or resume when you are ready. No backlog to catch up with.":"Save a source or a thought now. You can organize and connect it as you work.";action:root.query?"Clear search":"Quick capture";onActivated:{if(root.query)search.text="";else root.quickCapture();}}
     }
     NoesisButton {visible:root.cursor!=="";text:"Load 50 more";onClicked:root.load(true);Layout.bottomMargin:NoesisStyle.xl}
    }
    ColumnLayout {visible:!!root.selected.id&&!root.browseOpen&&!root.query;SplitView.fillWidth:true;SplitView.minimumWidth:Math.min(480,workingSplit.width);spacing:NoesisStyle.md
     RowLayout {visible:!root.compact&&!root.courseWorking&&!root.investigationWorking&&root.section!=="Practice";Layout.fillWidth:true
      ColumnLayout {Layout.fillWidth:true;spacing:NoesisStyle.xs
       Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:String(root.selected.unit_kind||root.selected.source_kind||({task:"problem",prerequisite:"prerequisite",unit:"lesson"})[root.selected.type]||root.selected.type||"context").toUpperCase();color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
       Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:root.selected.title||root.selected.imported_title||root.selected.path||"";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.heading;wrapMode:Text.Wrap;Layout.fillWidth:true}
      }
      NoesisButton {text:"Today priority";visible:!["activity","relationship","artifact"].includes(root.selected.type);onClicked:priorityDialog.begin()}
      NoesisButton {text:"Details";highlighted:root.inspectorOpen;onClicked:root.inspectorOpen=!root.inspectorOpen;hint:"Ctrl+I"}
      NoesisButton {visible:false;text:"Return to collection";onClicked:{root.stashDraft();root.selected=({});}
       Accessible.name:"Close context"}
     }
     Flow {visible:!root.compact&&!root.courseWorking&&!root.investigationWorking&&root.section!=="Practice";Layout.fillWidth:true;spacing:NoesisStyle.xs
      Repeater {model:["Read","Work","History","Connections"];delegate:NoesisButton {required property string modelData;variant:"tertiary";text:modelData;highlighted:root.contextTab===modelData;onClicked:root.contextTab=modelData}}
      Item {Layout.fillWidth:true}
      NoesisButton {visible:!root.readingWorking;text:"Open note ↗";enabled:!root.referenceHidden;onClicked:NoesisController.note(root.selected.path)}
     }
     Label {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:root.contextLoading;text:"Opening context…";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
     Label {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:root.selected.type==="artifact";text:(root.artifactInfo.availability||"Artifact reference")+" · "+(root.artifactInfo.location||"");color:NoesisStyle.secondary;wrapMode:Text.Wrap;Layout.fillWidth:true;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
     Label {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:false;text:root.workflow.latest_comparison?"Last reported result · "+(root.workflow.latest_comparison.observed||root.workflow.latest_comparison.conclusion||"Open history for evidence"):"Preserve a prediction, connect a run and compare what happened.";color:NoesisStyle.secondary;wrapMode:Text.Wrap;Layout.fillWidth:true;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
     NoesisCourseStudio {id:courseStudio;visible:root.courseWorking;Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumHeight:0;course:root.courseRecord.id?root.courseRecord:root.selected;lesson:root.selected;rows:root.courseMembers;cursor:root.courseCursor;preview:root.documentPreview;learningContext:root.learningContext;summary:root.courseProgress;notes:root.evidence.text;savedPlace:String(root.selectedState.locator?.value??root.selectedState.position??"");busy:NoesisController.working||root.outlineLoading
      onOpenMember:row=>root.courseOpen(row)
      onExpandModule:(row,more)=>{root.outlineLoading=true;root.moduleAppend=more;root.moduleSerial=root.send("outline",{record_id:row.id,cursor:more?Number(courseStudio.moduleCursor):0});}
      onMoveMember:(identity,direction)=>NoesisController.run(["outline-move",root.courseRecord.id,identity,direction])
      onLoadMore:{root.outlineLoading=true;root.outlineSerial=root.send("outline",{record_id:root.courseRecord.id,cursor:Number(root.courseCursor)});root.outlineAppendSerial=root.outlineSerial;}
      onImportOutline:outlineDialog.begin(root.courseRecord)
      onShowActions:actionDialog.begin(root.contextActions())
      onOpenSource:root.openSource()
      onReturnOutline:if(root.courseRecord.id)root.select(root.courseRecord)
      onNotesEdited:value=>root.evidence.text=value
      onPreserveNotes:root.saveEvent("study",{state:{}})
      onSavePlace:value=>root.saveEvent("study",{state:{position:value}})
      onReviewReadiness:row=>readinessDialog.begin(row)
     }
     NoesisConvolutionPage {id:convolutionPage;objectName:"convolution-page";workspace:root;visible:root.investigationWorking&&root.convolutionWorking;Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumHeight:0;record:root.selected;frontier:root.frontier;learningContext:root.learningContext;notes:root.evidence.text;attemptId:root.activeAttempt;protectedReference:root.referenceHidden;lastAssessment:root.history.slice().reverse().find(event=>["attempt","review"].includes(event.event))||({});busy:root.contextLoading||!NoesisController.hostReady||NoesisController.working||NoesisController.uncertainReceipt||NoesisController.exitRequested
      onConnectPrerequisite:prerequisiteDialog.begin(root.selected)
      onNotesEdited:value=>{root.evidence.text=value;draftSave.restart();}
      onOpenMember:row=>root.openWork(row)
      onOpenNote:NoesisController.note(root.selected.path)
      onAskQuestion:details=>{createDialog.begin("question",root.selected.id);createDialog.prefill(details);}
      onPreserveNote:root.saveEvent("study",{state:{}})
      onStartChanged:config=>root.saveEvent("attempt-start",{mode:"derive",scope:"Changed convolution case: "+convolutionPage.describe(config),convolution_case:config,assistance:["none"]})
      onEvaluateAttempt:attemptSettings.open()
      onShowHistory:root.contextTab="History"
      onReviewEvidence:{if(convolutionPage.lastAssessment.id)evidenceDialog.begin(convolutionPage.lastAssessment);}
      onInvestigateFailure:createDialog.begin("question",root.selected.id,false,"",convolutionPage.lastAssessment)
      onRevealReference:root.contextAction("reference")
     }
     NoesisInvestigationPage {id:investigation;learningContext:root.learningContext;onReviewReadiness:row=>readinessDialog.begin(row);visible:root.investigationWorking&&!root.convolutionWorking;Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumHeight:0;record:root.selected;lastAssessment:root.history.slice().reverse().find(event=>["attempt","review"].includes(event.event))||({});frontier:root.frontier;preview:root.documentPreview;claimCursor:root.workflow.claim_cursor||"";claimNewerCursor:root.workflow.claim_newer_cursor||"";claims:root.workflow.kind==="capability"?root.workflow.evidence||[]:[];notes:root.evidence.text;depth:root.selectedState.depth||root.selected.investigation?.depth||"normal";status:root.selectedState.status||root.selected.status||"active";attemptId:root.activeAttempt;referenceHidden:root.referenceHidden;busy:root.contextLoading||!NoesisController.hostReady||NoesisController.working||NoesisController.uncertainReceipt||NoesisController.exitRequested
      onConnectPrerequisite:prerequisiteDialog.begin(root.selected)
      onNotesEdited:value=>{root.evidence.text=value;draftSave.restart();}
      onPreserveNote:root.saveEvent("study",{state:{}})
      onShowActions:actionDialog.begin(root.contextActions())
      onStartAttempt:root.saveEvent("attempt-start",{mode:"derive",scope:root.selected.title,assistance:["none"]})
      onEvaluateAttempt:attemptSettings.open()
      onRevealReference:root.contextAction("reference")
      onOpenNote:NoesisController.note(root.selected.path)
      onAskQuestion:createDialog.begin("question",root.selected.id)
      onInvestigateFailure:createDialog.begin("question",root.selected.id,false,"",investigation.lastAssessment)
      onDefineCapability:createDialog.begin("capability",root.selected.id)
      onOpenMember:row=>root.openWork(row)
      onDisposition:value=>root.saveEvent("disposition",{state:{status:value}})
      onChooseDepth:value=>root.saveEvent("disposition",{state:{depth:value}})
      onShowHistory:root.contextTab="History"
      onReviewEvidence:{let entry=root.history.slice().reverse().find(event=>["attempt","review"].includes(event.event));if(entry)evidenceDialog.begin(entry);else{NoesisController.message="Preserve an assessed reconstruction before making an understanding claim.";}}
      onPageClaims:cursor=>root.claimSerial=root.send("claims",{record_id:root.selected.id,cursor:cursor})
      onPageFrontier:cursor=>root.loadFrontier(cursor)
     }
     NoesisReadingPage {id:readingPage;visible:root.readingWorking;Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumHeight:0;record:root.selected;preview:root.documentPreview;notes:root.evidence.text;savedPlace:String(root.selectedState.locator?.value??root.selectedState.position??"");locationKind:root.selectedState.locator?.kind||"location";questions:root.relations.filter(row=>row.other_type==="question");protectedReference:root.referenceHidden;busy:root.contextLoading||!NoesisController.hostReady||NoesisController.working||NoesisController.uncertainReceipt||NoesisController.exitRequested
      onOpenSource:root.openSource()
      onOpenNote:NoesisController.note(root.selected.path)
      onNotesEdited:value=>{root.evidence.text=value;draftSave.restart();}
      onPreserveNotes:root.saveEvent("study",{state:{}})
      onShowActions:actionDialog.begin(root.contextActions())
      onAskQuestion:createDialog.begin("question",root.selected.id)
      onSavePlace:(value,kind)=>{position.text=value;locatorKind.currentIndex=Math.max(0,locatorKind.model.indexOf(kind));root.saveEvent("study",{state:root.studyUpdate()});}
      onOpenQuestion:row=>root.openWork({id:row.other_id,path:row.other_path,title:row.other_title,type:row.other_type,vault:row.other_vault||NoesisController.activeVault})
     }
     ScrollView {id:readScroll;padding:NoesisStyle.xl;background:Rectangle {color:NoesisStyle.canvas;radius:NoesisStyle.radius}visible:root.contextTab==="Read"&&!root.courseWorking&&!root.investigationWorking&&!root.readingWorking;Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumHeight:0;clip:true
      ColumnLayout {id:readingColumn;width:readScroll.availableWidth;spacing:NoesisStyle.md
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;visible:root.compact;text:root.selected.title||root.selected.path||"";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.heading;wrapMode:Text.Wrap;Layout.fillWidth:true}
     Label {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:false;text:root.courseSummary();color:NoesisStyle.secondary;wrapMode:Text.Wrap;Layout.fillWidth:true;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
     NoesisLabPage {id:experimentContext;notesPreview:root.documentPreview;source:root.selected;busy:NoesisController.working;onOpenCode:NoesisController.run(["open-project",root.selected.id]);onRecordComparison:comparisonDialog.open();onBeginRun:root.contextAction("run");onConnectArtifact:root.contextAction("artifact");visible:["project","experiment"].includes(root.workflow.kind)&&!root.referenceHidden;Layout.fillWidth:true;context:root.workflow;onOpenArtifact:row=>root.openWork(row)}
     NoesisLearningContext {visible:!root.referenceHidden;Layout.fillWidth:true;context:root.learningContext;busy:NoesisController.working;onOpenContext:row=>root.select(row);onReviewReadiness:row=>readinessDialog.begin(row)}
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;visible:root.contextTab==="Read"&&["paper","project","experiment"].includes(root.workflow.kind)&&root.readingRelations.length>0&&!root.referenceHidden;text:root.workflow.kind==="paper"?"Questions and implementations":"Runs, evidence and source context";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;Layout.fillWidth:true}
     ListView {visible:root.contextTab==="Read"&&["paper","project","experiment"].includes(root.workflow.kind)&&root.readingRelations.length>0&&!root.referenceHidden;Layout.fillWidth:true;Layout.preferredHeight:Math.min(420,root.height*.42,root.readingRelations.length*NoesisStyle.row);clip:true;model:root.referenceHidden?[]:root.readingRelations
      delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:modelData.other_title||modelData.other_id;subtitle:(modelData.other_type||"context")+(modelData.other_status?" · "+modelData.other_status:"");enabled:!!modelData.other_path&&!root.referenceHidden;onClicked:root.openWork({id:modelData.other_id,path:modelData.other_path,title:modelData.other_title,type:modelData.other_type,vault:modelData.other_vault||NoesisController.activeVault})}
      ScrollBar.vertical:ScrollBar {}
     }
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;visible:!!root.selected.code_snapshot&&!["project","experiment"].includes(root.workflow.kind);Layout.fillWidth:true;wrapMode:Text.Wrap;text:{let code=root.selected.code_snapshot;if(!code)return "";if(code.availability==="unavailable")return "Code unavailable · "+code.repository;return "Code · "+(code.commit?code.commit.slice(0,12):"no committed revision yet")+(code.dirty?" · uncommitted changes present":" · clean working tree")+"
Observed "+(code.observed_at||"");}color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
     ColumnLayout {visible:root.workflow.kind==="capability";Layout.fillWidth:true;spacing:NoesisStyle.sm
      Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Assessment criteria";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
      Repeater {model:root.workflow.criteria||[];delegate:Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;required property var modelData;text:"• "+String(modelData);color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;Layout.fillWidth:true}}
      Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Learner evidence decisions · scoped, never a mastery percentage";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;Layout.fillWidth:true;wrapMode:Text.Wrap}
      Repeater {model:root.workflow.evidence||[];delegate:NoesisRow {required property var modelData;Layout.fillWidth:true;title:(modelData.decision||"Unavailable")+" · "+(modelData.criterion||"evidence");subtitle:(modelData.outcome||"unknown")+" · "+(modelData.assistance||["unknown"]).join(", ")+" · "+(modelData.scope||"scope unknown");enabled:!!modelData.path&&!root.referenceHidden;onClicked:NoesisController.note(modelData.path)}}
     }
     Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm;visible:!["project","experiment"].includes(root.workflow.kind)
      NoesisButton {text:root.selected.source_kind==="video"||root.selected.source_kind==="playlist"?"Continue video ↗":root.selected.local_file||root.selected.zotero_attachment_key?"Open PDF ↗":"Open source ↗";enabled:!root.referenceHidden;visible:!["course","path"].includes(root.workflow.kind)&&["paper","resource","course","unit"].includes(root.selected.type)&&!!(root.selected.source||root.selected.local_file||root.selected.zotero_attachment_key);primary:root.workflow.kind==="paper";hint:"Ctrl+Shift+Enter";onClicked:root.openSource()}
      NoesisButton {text:"Open problem ↗";visible:root.selected.source_kind==="problem-statement"&&!!root.selected.source;onClicked:NoesisController.run(["read-resource",root.selected.path,"--target-id",root.selected.id])}
      NoesisButton {text:"Open implementation ↗";visible:!!root.selected.repository||!!root.selected.code_snapshot?.repository;enabled:!root.referenceHidden&&!NoesisController.working;onClicked:NoesisController.run(["open-project",root.selected.id])}
      NoesisButton {text:"Preserve question";visible:root.workflow.kind==="paper"&&!root.tight;enabled:!NoesisController.working;onClicked:root.contextAction("question")}
      NoesisButton {text:"Start implementation";visible:root.workflow.kind==="paper"&&!root.tight;enabled:!NoesisController.working;onClicked:root.contextAction("implementation")}
      NoesisButton {text:root.workflow.kind==="paper"?"Research actions":"More";hint:"Ctrl+.";enabled:root.contextActions().length>0;onClicked:actionDialog.begin(root.contextActions())}
     }
     NoesisButton {text:root.readingPlaceOpen?"Hide reading place":"Reading pass & saved place";visible:root.tight&&root.workflow.kind==="paper";highlighted:root.readingPlaceOpen;onClicked:root.readingPlaceOpen=!root.readingPlaceOpen}
     RowLayout {Layout.fillWidth:true;visible:(!root.tight||root.readingPlaceOpen)&&(root.selected.source_kind==="paper"||root.selected.type==="paper")
      Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Reading pass";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
      NoesisSelect {id:readingPass;model:["survey","detail","reconstruct","verify"];Layout.fillWidth:true;Accessible.name:"Reading pass"}
     }
     Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm;visible:(!root.tight||root.workflow.kind!=="paper"||root.readingPlaceOpen)&&root.contextTab==="Read"&&["paper","resource","course","unit"].includes(root.selected.type)&&root.selected.unit_kind!=="module"&&(!["course","path"].includes(root.workflow.kind)||!!root.selected.source||!!root.selected.local_file)
      NoesisSelect {id:locatorKind;model:["location","page","section","exercise","timestamp"];Accessible.name:"Resume location kind"}
      NoesisField {id:position;objectName:"source-reading-place";width:Math.min(360,parent.width);placeholderText:"Resume at page, section or timestamp"}
      NoesisButton {text:"Save place";enabled:!NoesisController.working;onClicked:root.saveEvent("study",{state:root.studyUpdate()})}
     }
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;visible:root.contextTab==="Read"&&!["project","experiment"].includes(root.workflow.kind);text:"Equations, diagrams and editing open in Obsidian.";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;wrapMode:Text.Wrap;Layout.fillWidth:true}       NoesisResearchPage {id:researchPage;displayTitle:root.selected.title||"";visible:root.workflow.kind==="paper"&&!root.referenceHidden;Layout.fillWidth:true;context:root.workflow;preview:root.documentPreview;revisions:root.sourceRevisions;revisionCursor:root.revisionCursor;revisionNewerCursor:root.revisionNewerCursor;currentProjection:root.selected.zotero_projection||"";viewportHeight:readScroll.availableHeight;onPageAnnotations:cursor=>root.loadAnnotations(cursor);onChooseSnapshot:path=>root.loadAnnotations(null,path);onPageRevisions:cursor=>root.loadSourceRevisions(cursor)}
       ColumnLayout {Layout.fillWidth:true;spacing:NoesisStyle.lg;visible:!root.referenceHidden&&!["paper","project","experiment"].includes(root.workflow.kind)
        NoesisDocument {Layout.fillWidth:true;Layout.maximumWidth:NoesisStyle.readingWidth;framed:false;blocks:root.referenceHidden?[]:root.documentPreview.blocks||[];onOpenOriginal:NoesisController.note(root.selected.path)}
        Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;visible:(root.documentPreview.specialist_features||[]).length>0||!!root.documentPreview.truncated;text:"Open the original for "+(root.documentPreview.specialist_features||[]).join(", ")+(root.documentPreview.truncated?" and the complete document":"")+".";color:NoesisStyle.secondary;wrapMode:Text.Wrap;Layout.fillWidth:true;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
       }
       NoesisDocument {visible:root.referenceHidden;Layout.fillWidth:true;blocks:root.workflow.statement_preview?.blocks||[];originalAvailable:false}
       Text {visible:root.referenceHidden&&!root.workflow.statement;Layout.fillWidth:true;text:"Reference hidden. Reconstruct before revealing.";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body}

      }
     }
     ScrollView {id:practiceHost;implicitHeight:0;implicitWidth:0;visible:root.contextTab==="Work"&&!root.investigationWorking;Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumHeight:0;clip:true;contentWidth:availableWidth;contentHeight:practicePage.height;ScrollBar.horizontal.policy:ScrollBar.AlwaysOff;ScrollBar.vertical.policy:ScrollBar.AlwaysOn
     NoesisPracticePage {id:practicePage;support:root.relations;onOpenSupport:row=>root.openWork({id:row.other_id,path:row.other_path,title:row.other_title,type:row.other_type,vault:row.other_vault||NoesisController.activeVault,vault_id:row.other_vault_id});lastAssessment:root.history.slice().reverse().find(event=>["attempt","review"].includes(event.event))||({});onInvestigateFailure:createDialog.begin("question",root.selected.id,false,"",lastAssessment);width:practiceHost.availableWidth;height:Math.max(practiceHost.availableHeight,minimumWorkingHeight);contextTitle:root.selected.title||root.selected.path||"";attemptId:root.activeAttempt;statement:root.workflow.statement||"";statementPreview:root.workflow.statement_preview||({blocks:[]});originalProblemAvailable:root.selected.source_kind==="problem-statement"&&!!root.selected.source;onOpenOriginalProblem:NoesisController.run(["read-resource",root.selected.path,"--target-id",root.selected.id]);referenceHidden:root.referenceHidden;compact:root.compact;externalStatement:root.sourceOnSecondDisplay;busy:root.contextLoading||NoesisController.working;settingsLabel:root.activeAttempt?"Outcome: "+outcome.currentText+" · assistance: "+assistance.currentText:"Attempt mode: "+mode.currentText
      onDraftChanged:if(root.selected.id)draftSave.restart()
      onStartAttempt:root.contextAction("attempt-start")
      onSaveAttempt:root.contextAction("attempt-save")
      onRevealReference:root.contextAction("reference")
      onPlanCheck:reviewDialog.open()
      onShowActions:actionDialog.begin([{action:"attempt-settings",label:"Outcome and assistance"}].concat(root.contextActions()))
      onConfigureAttempt:attemptSettings.open()
     }}
     NoesisButton {text:root.section==="Practice"?"← Return to thinking":"← Return to working page";visible:["History","Connections"].includes(root.contextTab);onClicked:root.contextTab=root.section==="Practice"?"Work":"Read"}
     ListView {id:historyView;visible:root.contextTab==="History";Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:root.historyDisplay;spacing:NoesisStyle.sm
      header:Flow {width:historyView.width;spacing:NoesisStyle.sm;NoesisButton {visible:root.historyCursor!=="";text:"Older history";onClicked:root.loadHistory(true)}NoesisButton {visible:root.historyNewerCursor!=="";text:"Newer history";onClicked:root.loadHistory(true,root.historyNewerCursor)}NoesisButton {text:"Latest history";onClicked:root.loadHistory(false)}}
      delegate:ColumnLayout {required property var modelData;width:ListView.view.width;spacing:NoesisStyle.sm
       NoesisRow {Layout.fillWidth:true;title:modelData.event+" · "+(modelData.criterion||modelData.outcome||modelData.integrity||"")+(modelData.decision?" · "+modelData.decision:"");subtitle:(modelData.assistance||["unknown"]).join(", ")+" · "+modelData.timestamp;enabled:!root.referenceHidden;onClicked:NoesisController.note(modelData.path)}
       NoesisButton {text:"Use as evidence";visible:["attempt","review"].includes(modelData.event);enabled:!root.referenceHidden;onClicked:evidenceDialog.begin(modelData)}
      }
      NoesisEmpty {anchors.centerIn:parent;width:parent.width;visible:root.history.length===0;title:"History begins with real work";description:"Positions, predictions, attempts and comparisons will appear here. Nothing is inferred from a saved note."}
      ScrollBar.vertical:ScrollBar {}
     }
     ListView {visible:root.contextTab==="Connections";Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:root.relations;spacing:NoesisStyle.xs
      delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:modelData.other_title||modelData.other_id;subtitle:modelData.relation+(modelData.role?" · "+modelData.role:"");enabled:!!modelData.other_path&&!root.referenceHidden;onClicked:root.openWork({id:modelData.other_id,path:modelData.other_path,title:modelData.other_title,type:modelData.other_type,vault:modelData.other_vault||NoesisController.activeVault})}
      NoesisEmpty {anchors.centerIn:parent;width:parent.width;visible:root.relations.length===0;title:"Connect the next question";description:"Related resources, prerequisites, implementations and evidence stay linked even when notes move."}
     }

    }
    Loader {visible:root.inspectorVisible;SplitView.preferredWidth:320;SplitView.minimumWidth:280;SplitView.maximumWidth:360;sourceComponent:inspectorContent}

   }
   RowLayout {Layout.fillWidth:true;Layout.margins:NoesisStyle.md;visible:!!root.selected.id||NoesisController.error!==""||NoesisController.message!==""||NoesisController.working
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:NoesisController.working?(NoesisController.specialistHandoff?"Opening…":"Saving…"):NoesisController.error||((NoesisController.message?NoesisController.message+" · ":"")+"Owner: "+root.ownerLabel);color:NoesisController.error?NoesisStyle.error:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
    NoesisButton {text:"Inspect pending action";visible:NoesisController.uncertainReceipt;onClicked:pendingExit.open()}
    NoesisButton {text:"Stop";visible:NoesisController.working;onClicked:NoesisController.cancel()}
   }
  }
 }
 Component {id:inspectorContent;
  Rectangle {color:NoesisStyle.surface
     ColumnLayout {anchors.fill:parent;anchors.margins:NoesisStyle.lg;spacing:NoesisStyle.lg
      Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"CONTEXT";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
      Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:root.selected.title||root.selected.path||"";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;wrapMode:Text.Wrap;Layout.fillWidth:true}
      Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Owner: "+root.ownerLabel;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;wrapMode:Text.Wrap;Layout.fillWidth:true}
      Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:root.selected.path||"";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
      Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:root.selected.confidence!==undefined?"Legacy confidence: "+root.selected.confidence+" / 5 · self-report":"Evidence stays scoped. Assistance stays visible.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
      ListView {visible:root.workflow.kind==="paper";Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:root.referenceHidden?[]:root.workflow.annotations||[];spacing:NoesisStyle.md
       header:Column {width:parent.width;spacing:NoesisStyle.sm
        Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;width:parent.width;textFormat:Text.PlainText;text:root.workflow.projection_error||((root.workflow.annotation_count||0)+" imported annotations · snapshot "+(root.workflow.source_version??""));color:root.workflow.projection_error?NoesisStyle.error:NoesisStyle.secondary;wrapMode:Text.Wrap;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
        Flow {width:parent.width;spacing:NoesisStyle.sm
         NoesisButton {text:"Previous annotations";visible:!!root.workflow.newer_cursor;onClicked:root.loadAnnotations(root.workflow.newer_cursor)}
         NoesisButton {text:"More annotations";visible:!!root.workflow.cursor;onClicked:root.loadAnnotations(root.workflow.cursor)}
         NoesisButton {text:"Latest snapshot";visible:!!root.workflow.newer_cursor||!!root.workflow.projection_error;onClicked:root.loadAnnotations(null)}
        }
       }
       delegate:Column {required property var modelData;width:ListView.view.width;spacing:NoesisStyle.sm
        Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"ZOTERO · "+(modelData.page_label?"PAGE "+modelData.page_label:modelData.native_id);color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
        Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:modelData.text||"";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;width:parent.width;visible:text!==""}
        Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:modelData.comment?"Comment: "+modelData.comment:"";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;width:parent.width;visible:text!==""}
       }
      }
      Item {Layout.fillHeight:true;visible:root.workflow.kind!=="paper"}
      NoesisButton {text:"Close inspector";onClicked:root.inspectorOpen=false}
     }
    }
 }
 Drawer {id:inspectorDrawer;edge:Qt.RightEdge;width:Math.min(root.width-24,360*NoesisStyle.interfaceScale);height:root.height;visible:root.inspectorOpen&&!!root.selected.id&&!root.wideInspector&&!root.focusMode;onClosed:root.inspectorOpen=false;contentItem:Loader {sourceComponent:inspectorContent}}
 Drawer {id:navigationDrawer;width:Math.min(root.width-24,300*NoesisStyle.interfaceScale);height:root.height
  background:Rectangle {color:NoesisStyle.surface}
  contentItem:ScrollView {clip:true;ColumnLayout {width:parent.availableWidth;spacing:NoesisStyle.md
   Repeater {model:root.sections;delegate:NoesisButton {required property string modelData;variant:"tertiary";text:modelData;Layout.fillWidth:true;highlighted:root.section===modelData;onClicked:{root.section=modelData;navigationDrawer.close();}}}
   NoesisButton {text:"New learning object";Layout.fillWidth:true;onClicked:{navigationDrawer.close();createDialog.begin(root.section==="Lab"?"experiment":root.section==="Practice"?"task":"resource","");}}
   NoesisButton {text:"Quick capture";Layout.fillWidth:true;onClicked:{navigationDrawer.close();root.quickCapture();}}
   NoesisButton {text:"Settings";Layout.fillWidth:true;onClicked:{navigationDrawer.close();root.openSettings();}}
  }}
 }
 NoesisActionDialog {id:navigationActions;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(560,root.width-32);height:Math.min(520,root.height-32);title:"Navigate your learning";onChosen:action=>{if(action==="workspaces")navigationDrawer.open();else if(action==="search")searchPopup.open();else if(action==="return")root.returnCollection();else if(action==="back")root.back();else if(action==="details")root.inspectorOpen=!root.inspectorOpen;else if(action==="forward")root.forward();}}
 NoesisDialog {id:pendingExit;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(650,root.width-32);height:Math.min(560,root.height-32);title:"Unresolved action"
  contentItem:ScrollView {id:pendingScroll;clip:true;contentWidth:availableWidth
   ColumnLayout {width:pendingScroll.availableWidth;spacing:NoesisStyle.lg
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Noesis cannot verify whether this action committed. Inspect the owning record and receipt before repeating it. Closing keeps this reference for recovery.";color:NoesisStyle.warning;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;Layout.fillWidth:true}
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Vault: "+(NoesisController.pendingOperation.vault||NoesisController.operationVault)+"
Action: "+(NoesisController.pendingOperation.kind||NoesisController.operationKind)+"
"+(NoesisController.pendingOperation.receipt_supported===false?"Local tracking reference: ":"Operation: ")+(NoesisController.pendingOperation.id||NoesisController.operationId||"receipt unavailable");color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;wrapMode:Text.Wrap;Layout.fillWidth:true}
    NoesisButton {text:"Check receipt again";visible:NoesisController.pendingOperation.receipt_supported!==false;enabled:!!NoesisController.operationId&&!NoesisController.working;onClicked:{pendingExit.close();NoesisController.checkCancelled();}}
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;visible:NoesisController.pendingOperation.receipt_supported===false;text:"This import has a local tracking reference, not a backend receipt. Compare the owning records and preserved import source before repeating it.";color:NoesisStyle.warning;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;Layout.fillWidth:true}
    NoesisButton {text:"I inspected the import";visible:NoesisController.pendingOperation.receipt_supported===false;onClicked:{NoesisController.pendingOperation=({});NoesisController.operationId="";NoesisController.uncertainReceipt=false;NoesisController.error="";NoesisController.message="Interrupted import marked as inspected. No records were changed or replayed.";NoesisController.savePreferences();pendingExit.close();}}
    NoesisButton {text:"Close keeping unresolved action";variant:"danger";onClicked:{pendingExit.close();NoesisController.requestExit(true);}}
   }
  }
  footer:NoesisButton {text:"Return to app";primary:true;onClicked:pendingExit.close()}
 }
 NoesisDialog {id:searchPopup;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(700,root.width-32);height:Math.min(600,root.height-32);title:"Search learning records";onOpened:compactSearch.forceActiveFocus()
  contentItem:ColumnLayout {spacing:NoesisStyle.md
   NoesisField {id:compactSearch;Keys.onDownPressed:{compactResults.forceActiveFocus();compactResults.currentIndex=0;}Layout.fillWidth:true;objectName:"learning-search";placeholderText:"Title, concept or identifier";onTextChanged:{root.query=text;searchDelay.restart();}}
   NoesisButton {text:"Start learning from a new source";onClicked:{searchPopup.close();root.startLearning();}}
   ListView {id:compactResults;Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:root.rows;keyNavigationEnabled:true;Keys.onReturnPressed:{if(currentIndex>=0){root.select(root.rows[currentIndex]);compactSearch.text="";searchPopup.close();}}
    delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:modelData.title||modelData.path;subtitle:modelData.vault_name||modelData.type;onClicked:{root.select(modelData);compactSearch.text="";searchPopup.close();}}
    ScrollBar.vertical:ScrollBar {}
   }
  }
 }
 NoesisDialog {id:priorityDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(540,root.width-32);height:Math.min(520,root.height-32);title:"Today priority"
  property var target:({})
  property string vaultScope:""
  property string submittedOperation:""
  property bool submitting:false
  function begin(){target=Object.assign({},root.selected);vaultScope=NoesisController.activeVault;pinChoice.currentIndex=(root.selectedState.pin??root.selected.pin)?1:0;priorityChoice.currentIndex=Math.max(0,["normal","high","quiet"].indexOf(root.selectedState.manual_priority||root.selected.manual_priority||"normal"));submitting=false;open();pinChoice.forceActiveFocus();}
  contentItem:ScrollView {id:priorityScroll;clip:true;contentWidth:availableWidth;ColumnLayout {width:priorityScroll.availableWidth;spacing:NoesisStyle.lg
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;textFormat:Text.PlainText;text:priorityDialog.target.title||priorityDialog.target.path||"";wrapMode:Text.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading}
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;textFormat:Text.PlainText;text:"Pin keeps eligible work at the top. High raises its priority. Quiet silences suggestions, including pins, while preserving resume context. Completed work stays excluded; these controls do not award competence.";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body}
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Pin";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
   NoesisSelect {id:pinChoice;Layout.fillWidth:true;model:["Not pinned","Pinned"];Accessible.name:"Today pin"}
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Suggestion priority";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
   NoesisSelect {id:priorityChoice;Layout.fillWidth:true;model:["Normal","High","Quiet"];Accessible.name:"Today suggestion priority"}
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;textFormat:Text.PlainText;text:"Owner: "+priorityDialog.vaultScope;wrapMode:Text.Wrap;color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
  }}
  footer:Flow {spacing:NoesisStyle.sm
   NoesisButton {text:"Cancel";onClicked:priorityDialog.close()}
   NoesisButton {id:savePriority;text:"Save priority";primary:true;enabled:!NoesisController.working&&priorityDialog.vaultScope===NoesisController.activeVault;onClicked:{priorityDialog.submitting=true;NoesisController.run(["event",priorityDialog.target.path,"disposition","--target-id",priorityDialog.target.id,"--data",JSON.stringify({state:{pin:pinChoice.currentIndex===1,manual_priority:["normal","high","quiet"][priorityChoice.currentIndex]}})]);priorityDialog.submittedOperation=NoesisController.operationId;}}
  }
  Shortcut {sequence:"Ctrl+Return";enabled:priorityDialog.visible;onActivated:if(savePriority.enabled)savePriority.clicked()}
  Connections {target:NoesisController;function onFinished(ok){if(priorityDialog.submitting){priorityDialog.submitting=false;if(ok&&NoesisController.operationResult.operation_id===priorityDialog.submittedOperation)priorityDialog.close();}}}
 }
 NoesisDialog {id:attemptSettings;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(540,root.width-32);height:Math.min(520,root.height-32);title:"Attempt settings";onOpened:mode.forceActiveFocus();onClosed:if(root.contextTab==="Work")evidence.forceActiveFocus()
  Shortcut {sequence:"Ctrl+Return";enabled:attemptSettings.visible;onActivated:attemptSettings.close()}
  footer:RowLayout {NoesisButton {text:"Done";variant:"secondary";onClicked:attemptSettings.close()} NoesisButton {text:"Save reconstruction result";visible:root.investigationWorking&&!!root.activeAttempt;primary:true;enabled:root.evidence.text.trim()!==""&&!NoesisController.working;onClicked:{root.contextAction("attempt-save");attemptSettings.close();}}}
  contentItem:ScrollView {id:attemptScroll;clip:true;contentWidth:availableWidth;ScrollBar.horizontal.policy:ScrollBar.AlwaysOff;ColumnLayout {width:attemptScroll.availableWidth;spacing:NoesisStyle.lg
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Mode";color:NoesisStyle.ink;font.pixelSize:NoesisStyle.label;font.family:NoesisStyle.uiFont}
   NoesisSelect {id:mode;model:["pattern","interface","derive","build","transfer"];currentIndex:2;Layout.fillWidth:true;Accessible.name:"Attempt mode"}
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Reported outcome";visible:!!root.activeAttempt;color:NoesisStyle.ink;font.pixelSize:NoesisStyle.label;font.family:NoesisStyle.uiFont}
   NoesisSelect {id:outcome;objectName:"attempt-outcome";model:["unknown","incomplete","failed","partial","succeeded"];Layout.fillWidth:true;visible:!!root.activeAttempt;Accessible.name:"Reported outcome"}
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Declared assistance";visible:!!root.activeAttempt;color:NoesisStyle.ink;font.pixelSize:NoesisStyle.label;font.family:NoesisStyle.uiFont}
   NoesisSelect {id:assistance;objectName:"attempt-assistance";model:["unknown","none","hint","reference","collaborator","agent"];Layout.fillWidth:true;visible:!!root.activeAttempt;Accessible.name:"Declared assistance"}
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Saved reference exposure stays in the attempt history.";color:NoesisStyle.secondary;font.pixelSize:NoesisStyle.caption;font.family:NoesisStyle.uiFont;wrapMode:Text.Wrap;Layout.fillWidth:true}

  }}
 }
 function openSettings(){settingsDialog.open();}
 NoesisDialog {id:settingsDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(600,root.width-32);height:Math.min(600,root.height-32);title:"Settings"
  footer:NoesisButton {text:"Done";variant:"secondary";onClicked:settingsDialog.close()}
  contentItem:ScrollView {id:settingsScroll;clip:true;contentWidth:availableWidth;ScrollBar.horizontal.policy:ScrollBar.AlwaysOff;ScrollBar.vertical.policy:ScrollBar.AlwaysOn
   ColumnLayout {width:Math.max(0,settingsScroll.availableWidth-16);spacing:NoesisStyle.lg
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Window presentation";color:NoesisStyle.ink;font.pixelSize:NoesisStyle.label;font.family:NoesisStyle.uiFont}
    NoesisSelect {model:["Full screen","Maximized","Tiled","Window"];currentIndex:["fullscreen","workspace","tiled","normal"].indexOf(NoesisController.presentationMode);Layout.fillWidth:true;Accessible.name:"Window presentation";onActivated:{NoesisController.presentationMode=["fullscreen","workspace","tiled","normal"][currentIndex];NoesisController.savePreferences();}}
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Interface size";color:NoesisStyle.ink;font.pixelSize:NoesisStyle.label;font.family:NoesisStyle.uiFont}
    NoesisSelect {model:["100%","125%","150%","200%"];currentIndex:[1,1.25,1.5,2].indexOf(NoesisStyle.interfaceScale);Layout.fillWidth:true;Accessible.name:"Interface size";onActivated:{NoesisStyle.interfaceScale=[1,1.25,1.5,2][currentIndex];NoesisController.savePreferences();}}
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Reading size";color:NoesisStyle.ink;font.pixelSize:NoesisStyle.label;font.family:NoesisStyle.uiFont}
    NoesisSelect {model:["100%","125%","150%","200%"];currentIndex:[1,1.25,1.5,2].indexOf(NoesisStyle.readingScale);Layout.fillWidth:true;Accessible.name:"Reading size";onActivated:{NoesisStyle.readingScale=[1,1.25,1.5,2][currentIndex];NoesisController.savePreferences();}}
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Open new windows on";color:NoesisStyle.ink;font.pixelSize:NoesisStyle.label;font.family:NoesisStyle.uiFont}
    NoesisSelect {model:["Current workspace","Dedicated study workspace"];currentIndex:NoesisController.placement==="dedicated"?1:0;Layout.fillWidth:true;Accessible.name:"Workspace placement";onActivated:{NoesisController.placement=currentIndex?"dedicated":"current";NoesisController.savePreferences();}}
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Study workspace name";color:NoesisStyle.ink;font.pixelSize:NoesisStyle.label;font.family:NoesisStyle.uiFont;visible:NoesisController.placement==="dedicated"}
    NoesisField {text:NoesisController.studyWorkspace;visible:NoesisController.placement==="dedicated";Layout.fillWidth:true;Accessible.name:"Study workspace name";onEditingFinished:{if(text.trim()){NoesisController.studyWorkspace=text.trim();NoesisController.savePreferences();}}}
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"After opening a specialist tool";color:NoesisStyle.ink;font.pixelSize:NoesisStyle.label;font.family:NoesisStyle.uiFont}
    NoesisSelect {model:["Hide Noesis","Keep Noesis visible"];currentIndex:NoesisController.returnBehavior==="hide"?0:1;Layout.fillWidth:true;Accessible.name:"Specialist handoff behavior";onActivated:{NoesisController.returnBehavior=currentIndex?"stay":"hide";NoesisController.savePreferences();}}
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Preferred display";color:NoesisStyle.ink;font.pixelSize:NoesisStyle.label;font.family:NoesisStyle.uiFont}
    NoesisSelect {model:Quickshell.screens.map(s=>s.name);currentIndex:model.indexOf(NoesisController.mainMonitor);Layout.fillWidth:true;Accessible.name:"Preferred display";onActivated:{NoesisController.mainMonitor=currentText;NoesisController.savePreferences();}}
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Workspace changes apply on the next launch. Existing tool windows stay where they are.";color:NoesisStyle.secondary;font.pixelSize:NoesisStyle.caption;font.family:NoesisStyle.uiFont;wrapMode:Text.Wrap;Layout.fillWidth:true}

   }
  }
 }
 NoesisDialog {id:comparisonDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(640,root.width-48);height:Math.min(780*NoesisStyle.interfaceScale,(parent?.height||root.height)-32);modal:true;title:"Compare prediction with observation"
  property bool submitting:false
  property var target:({})
  property string vaultScope:""
  onOpened:{target=Object.assign({},root.selected);vaultScope=NoesisController.activeVault;predicted.text=target.hypothesis||"";observed.forceActiveFocus();}
  background:Rectangle {color:NoesisStyle.surface;radius:NoesisStyle.radius;}
  contentItem:ScrollView {id:comparisonForm;clip:true;contentWidth:availableWidth;ColumnLayout {width:comparisonForm.availableWidth;spacing:NoesisStyle.md
   Text {text:"Prediction";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;renderType:Text.NativeRendering;Layout.fillWidth:true}
   NoesisEditor {id:predicted;Layout.preferredHeight:80*NoesisStyle.interfaceScale;objectName:"comparison-predicted";Accessible.name:"Prediction";Layout.fillWidth:true;placeholderText:"Original prediction or hypothesis"}
   Text {text:"Observed result";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;renderType:Text.NativeRendering;Layout.fillWidth:true}
   NoesisEditor {id:observed;Layout.preferredHeight:80*NoesisStyle.interfaceScale;objectName:"comparison-observed";Accessible.name:"Observed result";Layout.fillWidth:true;placeholderText:"Observed result, with units and uncertainty"}
   Text {text:"Conditions and executed code revision";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;renderType:Text.NativeRendering;Layout.fillWidth:true}
   NoesisEditor {id:conditions;Layout.preferredHeight:Math.max(60*NoesisStyle.interfaceScale,implicitHeight);font.family:NoesisStyle.codeFont;objectName:"comparison-conditions";Accessible.name:"Conditions and executed code revision";Layout.fillWidth:true;placeholderText:"Configuration and code commit · optional"}
   Text {text:"Interpretation and next test";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;renderType:Text.NativeRendering;Layout.fillWidth:true}
   NoesisEditor {id:conclusion;objectName:"comparison-conclusion";Accessible.name:"Interpretation and next test";Layout.fillWidth:true;Layout.preferredHeight:Math.max(120*NoesisStyle.interfaceScale,implicitHeight);placeholderText:"Discrepancy, evidence and what to test next…"}
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"A successful run does not establish the hypothesis. This preserves the comparison as reported evidence.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}

  }}
  footer:NoesisButton {id:saveComparison;text:"Save comparison";hint:"Ctrl+Enter";primary:true;enabled:predicted.text.trim()!==""&&observed.text.trim()!==""&&conclusion.text.trim()!==""&&!NoesisController.working&&comparisonDialog.vaultScope===NoesisController.activeVault;onClicked:{comparisonDialog.submitting=true;NoesisController.run(["event",comparisonDialog.target.path,"comparison","--target-id",comparisonDialog.target.id,"--evidence",conclusion.text,"--data",JSON.stringify({prediction:predicted.text,observed:observed.text,configuration:conditions.text,code_snapshot:comparisonDialog.target.code_snapshot||null,conclusion:conclusion.text,assessment:"learner-reported"})]);}}
  Shortcut {sequence:"Ctrl+Return";enabled:comparisonDialog.visible;onActivated:if(saveComparison.enabled)saveComparison.clicked()}
 Connections {target:NoesisController;
function onFinished(ok){if(comparisonDialog.submitting){comparisonDialog.submitting=false;if(ok){comparisonDialog.close();predicted.text="";observed.text="";conditions.text="";conclusion.text="";}}}}
 }
 NoesisMaterialDialog {id:materialDialog;parent:Overlay.overlay}
 NoesisDialog {id:reviewDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(440,root.width-48);modal:true;title:"Plan a later check"
  property bool submitting:false
  property var target:({})
  property string vaultScope:""
  onOpened:{target=Object.assign({},root.selected);vaultScope=NoesisController.activeVault;checkPurpose.forceActiveFocus();}
  background:Rectangle {color:NoesisStyle.surface;radius:NoesisStyle.radius;}
  contentItem:ColumnLayout {spacing:NoesisStyle.lg
   NoesisSelect {id:checkStage;model:["retry","later","maintenance"];Layout.fillWidth:true}
   NoesisSelect {id:checkAction;model:["schedule","snooze","retire"];Layout.fillWidth:true}
   NoesisEditor {id:checkPurpose;Layout.fillWidth:true;Layout.preferredHeight:100;placeholderText:"What will you reconstruct or verify?"}
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Defaults: 1, 7 or 30 days. A convenience policy, not a competence estimate.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
   NoesisButton {id:saveReview;text:"Save plan";hint:"Ctrl+Enter";primary:true;enabled:checkPurpose.text.trim()!==""&&!NoesisController.working&&reviewDialog.vaultScope===NoesisController.activeVault;onClicked:{reviewDialog.submitting=true;NoesisController.run(["event",reviewDialog.target.path,"review-plan","--target-id",reviewDialog.target.id,"--evidence",checkPurpose.text,"--data",JSON.stringify({stage:checkStage.currentText,action:checkAction.currentText})]);}}
  }
  Shortcut {sequence:"Ctrl+Return";enabled:reviewDialog.visible;onActivated:if(saveReview.enabled)saveReview.clicked()}
 Connections {target:NoesisController;
function onFinished(ok){if(reviewDialog.submitting){reviewDialog.submitting=false;if(ok){reviewDialog.close();checkPurpose.text="";}}}}
 }
 NoesisZoteroDialog {id:zoteroDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(620,root.width-48);height:Math.min(480,root.height-80);onImported:record=>{let paths=(record.created||[]).concat(record.existing||[]);if(paths.length)root.openWork({id:record.resource_id,path:paths[0],type:"paper"});}}
 NoesisEvidenceDialog {id:evidenceDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(560,root.width-48);onLookup:query=>{root.capabilitySerial=root.send("query",{kind:["capability"],query:query});};onMoreClaims:cursor=>{root.capabilityClaimsSerial=root.send("claims",{record_id:evidenceDialog.selected.id,cursor:cursor});};onInspect:identity=>{root.capabilityClaimsSerial=0;evidenceDialog.selected=({});evidenceDialog.loading=true;root.capabilityDetailSerial=root.send("record",{record_id:identity});}}
 NoesisActionDialog {id:actionDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(520,root.width-48);onChosen:action=>root.contextAction(action)}
 NoesisActionDialog {id:startDialog;title:"Start something";parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(520,root.width-48);onChosen:action=>{if(action==="outline")outlineDialog.begin(null);else if(action==="zotero")zoteroDialog.open();else if(action==="capture")root.quickCapture();else if(action==="concept")createDialog.begin("concept","");else createDialog.begin(action==="path"?"path":root.section==="Lab"?"experiment":root.section==="Practice"?"task":"resource","");}}
 NoesisOutlineDialog {id:outlineDialog;onImported:course=>root.select(course)}
 NoesisDialog {
  id:readinessDialog
  property var target:({})
  property string vaultScope:""
  property bool submitting:false
  title:"Is this prerequisite usable here?"
  parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(560,root.width-48)
  function begin(row){target=Object.assign({},row,{contextId:root.selected.id});vaultScope=NoesisController.activeVault;readinessReason.text="";readinessChoice.currentIndex=row.readiness==="passed"?0:1;submitting=false;open();readinessReason.forceActiveFocus();}
  contentItem:ColumnLayout {spacing:NoesisStyle.md
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:readinessDialog.target.title||"";Layout.fillWidth:true;wrapMode:Text.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading}
   NoesisEditor {id:readinessReason;Layout.fillWidth:true;Layout.preferredHeight:140;placeholderText:"What can you now explain or do? What still needs work?"}
   NoesisSelect {id:readinessChoice;Layout.fillWidth:true;model:["Ready for this lesson","Needs more work"]}
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Your decision applies to this lesson's prerequisite. It does not award general competence or change earlier evidence.";Layout.fillWidth:true;wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
   NoesisButton {id:saveReadiness;text:"Save readiness decision";primary:true;hint:"Ctrl+Enter";enabled:readinessReason.text.trim()!==""&&!NoesisController.working&&readinessDialog.vaultScope===NoesisController.activeVault;onClicked:{readinessDialog.submitting=true;NoesisController.run(["event",readinessDialog.target.relationship_path,"disposition","--target-id",readinessDialog.target.relationship_id,"--evidence",readinessReason.text,"--data",JSON.stringify({state:readinessChoice.currentIndex===0?"passed":"active",actor:"learner",scope:readinessDialog.target.contextId})]);}}
  }
  Shortcut {sequence:"Ctrl+Return";enabled:readinessDialog.opened;onActivated:if(saveReadiness.enabled)saveReadiness.clicked()}
 Connections {target:NoesisController;
function onFinished(ok){if(readinessDialog.submitting){readinessDialog.submitting=false;if(ok)readinessDialog.close();}}}
 }
 NoesisPrerequisiteDialog {id:prerequisiteDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(560,root.width-48);onSearch:query=>{root.prerequisiteSerial=root.send("query",{query:query,kind:["concept","capability","task","problem","unit","prerequisite"]});}}
 NoesisHelpDialog {id:helpDialog;parent:Overlay.overlay;anchors.centerIn:parent;onStartLearning:root.startLearning();onSearchRecords:searchPopup.open()}
 NoesisStartDialog {id:learningStart;parent:Overlay.overlay;anchors.centerIn:parent;onBeginLearning:(kind,medium,source,title)=>createDialog.beginSource(kind,medium,source,title);onZotero:zoteroDialog.open()}
 NoesisCreateDialog {id:createDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(560,root.width-48);onCreated:record=>root.openWork(record)}
 NoesisDialog {id:captureDialog;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(560,root.width-48);modal:true;title:"Quick capture";closePolicy:Popup.CloseOnEscape
  background:Rectangle {color:NoesisStyle.surface;radius:NoesisStyle.radius;}
  contentItem:ColumnLayout {spacing:NoesisStyle.lg
   NoesisEditor {id:capture;Keys.onPressed:event=>{if((event.key===Qt.Key_Return||event.key===Qt.Key_Enter)&&(event.modifiers&Qt.ControlModifier)){event.accepted=true;if(capture.text.trim()&&!NoesisController.working)root.submitCapture();}}Layout.fillWidth:true;Layout.preferredHeight:160;placeholderText:"A thought, source, snippet or observation…";onTextChanged:if(root.captureVault)captureDraftSave.restart();Accessible.name:"Quick capture"}
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"No classification needed. Connect it when you are ready.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
   RowLayout {Layout.fillWidth:true
    NoesisButton {text:"Keep draft";onClicked:captureDialog.close()}
    Item {Layout.fillWidth:true}
    NoesisButton {text:"Save capture";primary:true;enabled:capture.text.trim()!==""&&!NoesisController.working;onClicked:root.submitCapture()}
   }
  }
 }
 Connections {target:NoesisController;
function onFinished(ok){if(ok&&root.captureSubmission&&capture.text===root.captureSubmission){capture.text="";captureDialog.close();}root.captureSubmission="";}}
}
