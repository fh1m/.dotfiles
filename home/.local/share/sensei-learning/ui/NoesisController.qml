pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
 id:root
 property var buildIdentity:({commit:"development",source_dirty:true})
 FileView {path:"@HOME@/.local/share/sensei-learning/build.json";printErrors:false;onLoaded:{try{root.buildIdentity=JSON.parse(text());}catch(error){root.error="Installed build identity could not be read.";}}}
 property var state:({notes:[],files:[],vaults:[],gates:[],reviews:[],questions:[],projects:[],labs:[],sources:[]})
 property bool leaseHeld:false
 property bool preferencesReady:false
 property bool configurationReady:false
 readonly property bool hostReady:leaseHeld&&preferencesReady&&configurationReady
 onHostReadyChanged:if(hostReady){if(pendingOperation.id)checkCancelled();if(openWhenReady)open();}
 property bool openWhenReady:false
 property bool windowOpen:false
 Process {id:hostLease;command:["@HOME@/.local/bin/noesis","host-lease"];stdinEnabled:true;running:true;stdout:SplitParser {onRead:data=>{if(data==="acquired"){root.leaseHeld=true;}else{root.error="Another Noesis host owns this session. Close it before selecting rollback.";if(root.standalone)Qt.quit();}}}onExited:code=>{if(root.hostReady){root.leaseHeld=false;root.windowOpen=false;root.error="Application coordination stopped; reopen Noesis before editing.";}}}
 property bool standalone:Quickshell.env("NOESIS_STANDALONE")==="1"
 property bool exitRequested:false
 property bool exitWithUncertainty:false
 property bool preferenceFailed:false
 property bool operationQueued:false
 property bool uncertainReceipt:false
 property var pendingOperation:({})
 property string instanceToken:operationUuid()
 property var instance:({token:instanceToken,pid:Quickshell.processId,started_at:Date.now()})
 property var acceptedRequests:({})
 property var openRequest:({})
 property string requestFrame:""
 property var pendingRequest:({})
 function markRequest(id,status,error){let ack={version:1,request_id:id,status:status,instance:instanceToken};if(error)ack.error=error;let next=Object.assign({},acceptedRequests);next[id]=ack;let keys=Object.keys(next);if(keys.length>128)delete next[keys[0]];acceptedRequests=next;}
 property string placement:"dedicated"
 property string studyWorkspace:"Study"
 property string returnBehavior:"hide"
 signal flushRequested()
 function flush(){flushRequested();preferencesSave.stop();writePreferences();}
 function hide(){windowOpen=false;flush();snapshot.running=false;reader.running=false;pendingPreview="";refreshPending=false;debounce.stop();}
 function requestExit(acknowledged){exitWithUncertainty=acknowledged===true;if(!standalone){hide();return;}exitRequested=true;flush();shutdownCheck.start();if(working)message="Waiting for the current action and its receipt before closing.";}
 function writePreferences(){if(!hostReady)return;if(preferences.running){preferencesPending=true;return;}preferenceDraftFrame=JSON.stringify(drafts)+"\n";preferences.command=["@HOME@/.local/bin/noesis","window-state","--layouts-json",JSON.stringify(layouts),"--interface-scale",String(NoesisStyle.interfaceScale),"--reading-scale",String(NoesisStyle.readingScale),"--drafts-stdin","--width",String(windowWidth),"--height",String(windowHeight),"--pending-json",JSON.stringify(pendingOperation),"--instance-json",JSON.stringify(instance),"--visible",windowOpen?"on":"off","--placement",placement,"--study-workspace",studyWorkspace,"--return-behavior",returnBehavior,"--path-scope",pathScope,"--path-scope-vault",activeVault,"--workspace",workspace,"--presentation",presentationMode,"--collection",collectionScope?"on":"off","--list-ratio",String(listRatio),"--context-json",JSON.stringify(currentContext),"--monitor",mainMonitor,"--quiet",quiet?"on":"off"];preferences.running=true;}
 Timer {id:shutdownCheck;interval:100;repeat:true;onTriggered:{if(!root.exitRequested){stop();return;}if(root.working||preferencesSave.running||preferences.running||root.preferencesPending)return;if(root.preferenceFailed||(root.uncertainReceipt&&!root.exitWithUncertainty)){root.exitRequested=false;stop();root.windowOpen=false;Qt.callLater(()=>root.windowOpen=true);root.error=root.preferenceFailed?"Draft/preferences could not be saved. Input is retained; try Close again.":"Commit status is uncertain. Inspect the original operation before closing or retrying.";return;}stop();Qt.quit();}}

 property bool legacyInterface:false
 property string workspace:"Today"
 property bool collectionScope:false
 property string presentationMode:Quickshell.env("NOESIS_WINDOW_MODE")||"fullscreen"
 property string mainMonitor:Quickshell.env("NOESIS_MAIN_MONITOR")||"eDP-1"
 property bool quiet:false
 property string pathScope:""
 property string storedPathScope:""
 property string pathScopeVault:""
 property var layouts:({})
 property real listRatio:0.38
 property var currentContext:({})
 property var drafts:({})
 signal captureRequested()
 property int openSerial:0
 property int windowWidth:1440
 property int windowHeight:880
 property string snapshotVault:""
 property string readerVault:""
 property string operationVault:""
 property bool specialistHandoff:false
 property string operationKind:""
 property string operationId:""
 property bool cancellationPending:false
 property string operationInput:""
 property string preferenceDraftFrame:"{}"
 property bool preferencesPending:false
 property string activeVault:""
 property string error:""
 property string message:""
 property var operationResult:({})
 property string operationError:""
 property string previewText:""
 property string previewPath:""
 property string pendingPreview:""
 property bool refreshPending:false
 readonly property bool working:operationQueued||operation.running||receipt.running||cancellationPending
 signal finished(bool ok)
 function refresh(){if(!hostReady)return;if(snapshot.running){refreshPending=true;return;}snapshotVault=activeVault;snapshot.command=["@HOME@/.local/bin/noesis","status","--vault",snapshotVault];if(legacyInterface)snapshot.command.push("--legacy");snapshot.running=true;}
 function operationUuid(){return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g,c=>{let r=Math.floor(Math.random()*16);return (c==="x"?r:(r&3)|8).toString(16);});}
 function run(args){if(!hostReady){error="Another host owns this learning session.";return;}if(exitRequested||working||uncertainReceipt){error="Let the current action finish.";return;}error="";message="";specialistHandoff=["read-resource","open-project"].includes(args[0])||(args[0]==="cli"&&args[1]==="open");operationKind=args[0];operationVault=activeVault;operationResult=({});operationError="";operationId="";cancellationPending=false;let bound=args.slice();operationInput="";if(operationKind==="capture"&&bound.length===2){operationInput=JSON.stringify(bound[1])+"\n";bound=["capture","--stdin-line"];}if(["capture","record","event","attempt","progress","artifact-check","outline-move","link","convolution-observe","convolution-prepare","convolution-check"].includes(operationKind)){operationId=operationUuid();bound.push("--operation-id",operationId);}if(bound[0]!=="use"&&bound[0]!=="window-state"&&bound[0]!=="vaults"){bound.splice(1,0,"--vault",operationVault);}operation.command=["@HOME@/.local/bin/noesis"].concat(bound);let explicit=bound.indexOf("--operation-id");if(explicit>=0)operationId=bound[explicit+1];let unreceiptedImport=["import-csl","import-notes","zotero-import"].includes(operationKind)&&!bound.includes("--dry-run");if(unreceiptedImport&&!operationId)operationId=operationUuid();if(operationId){pendingOperation={id:operationId,vault:operationVault,kind:operationKind,instance:instanceToken,receipt_supported:!unreceiptedImport};operationQueued=true;flush();}else if(specialistHandoff){operationQueued=true;flush();}else operation.running=true;}
 function choose(path){previewText="";previewPath="";pendingPreview="";run(["use",path]);}
 function note(path){run(["cli","open","path="+path]);}
 function preview(path){previewPath=path;previewText="Loading note…";if(reader.running){pendingPreview=path;return;}readerVault=activeVault;reader.command=["@HOME@/.local/bin/noesis","preview",path,"--vault",root.activeVault];reader.running=true;}
 function open(){if(!hostReady){openWhenReady=true;return;}exitRequested=false;windowOpen=true;openSerial++;refresh();savePreferences();}
 function close(){hide();}
 onWindowOpenChanged:{watch.running=legacyInterface&&windowOpen&&activeVault!=="";}
 onLegacyInterfaceChanged:watch.running=legacyInterface&&windowOpen&&activeVault!==""
 function setPathScope(identity){pathScope=identity;storedPathScope=identity;pathScopeVault=activeVault;savePreferences();}
 function savePreferences(){preferenceFailed=false;preferencesSave.restart();}
 onActiveVaultChanged:{pathScope=pathScopeVault===activeVault?storedPathScope:"";watch.running=false;previewText="";previewPath="";state=({notes:[],files:[],vaults:[],gates:[],reviews:[],questions:[],projects:[],labs:[],sources:[]});Qt.callLater(()=>{watch.running=legacyInterface&&windowOpen&&activeVault!=="";if(windowOpen)debounce.restart();});}
 function cancel(){if(!operation.running)return;cancellationPending=true;operation.running=false;error="Checking whether the action committed…";}
 function checkCancelled(){cancellationPending=false;if(pendingOperation.receipt_supported===false){uncertainReceipt=true;error="Import completion is unknown. Inspect the owning vault and preserved source before importing again; no backend receipt is available.";if(windowOpen)refresh();return;}if(operationId){uncertainReceipt=true;receipt.command=["@HOME@/.local/bin/noesis","operation-status",operationId,"--vault",operationVault];receipt.running=true;}else{uncertainReceipt=true;error="Action stopped. Its commit status is uncertain; inspect before retrying.";if(windowOpen)refresh();}}
 FileView {onLoadFailed:code=>{root.configurationReady=true;if(code!==FileViewError.FileNotFound)root.error="Application configuration is unavailable; preserve it before recovery.";};path:"@HOME@/.config/sensei-learning/config.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.activeVault=JSON.parse(text()).active_vault||"";if(root.windowOpen)debounce.restart();}catch(e){root.error=String(e);}root.configurationReady=true;}}
 FileView {path:root.windowOpen&&root.activeVault?root.activeVault+"/"+(root.state.frontier_path||"00 Home/Current Frontier.md"):"";watchChanges:true;printErrors:false;onFileChanged:{reload();if(root.windowOpen)debounce.restart();}}
 Process {id:watch;command:["@HOME@/.local/bin/sensei-learning-watch",root.activeVault];stdout:SplitParser {onRead:debounce.restart()}}
 Timer {id:debounce;interval:400;onTriggered:root.refresh()}
 Process {id:snapshot;command:["@HOME@/.local/bin/noesis","status"];stdout:StdioCollector {onStreamFinished:{try{if(text.trim()&&root.snapshotVault===root.activeVault)root.state=JSON.parse(text);}catch(e){root.error="Could not read the learning index.";}}}stderr:StdioCollector {onStreamFinished:if(root.snapshotVault===root.activeVault&&text.trim())root.error=text.trim()}onExited:(code)=>{if(root.refreshPending){root.refreshPending=false;Qt.callLater(root.refresh);}}}
 Process {id:operation;stdinEnabled:true;onStarted:if(root.operationInput)write(root.operationInput);stdout:StdioCollector {onStreamFinished:if(root.operationVault===root.activeVault){root.message=root.operationKind==="capture"?"Captured locally.":"Action completed.";try{let result=JSON.parse(text);root.operationResult=result;if(root.operationKind==="link")root.message=result.relation==="prerequisite"?"Prerequisite connected.":"Connection saved.";else if(root.operationKind==="course-import")root.message=result.course?"Course outline created.":"Outline reviewed · "+String(result.count||result.entries?.length||0)+" entries";else if(result.event)root.message=result.event.replace(/-/g," ")+" saved"+(result.outcome?" · "+result.outcome:"")+(result.assistance?" · assistance: "+result.assistance.join(", "):"");else if(result.message)root.message=result.message;else if(Array.isArray(result.created))root.message="Imported "+result.created.length+" sources; refreshed "+(result.existing||[]).length+" existing.";else if(result.id&&result.type)root.message=(root.operationKind==="promote"?"Updated ":"Created ")+(result.title||result.type);}catch(error){root.operationResult=({});}}}stderr:StdioCollector {onStreamFinished:if(root.operationVault===root.activeVault&&text.trim()){root.operationError=text.trim();root.error=root.operationError;}}onExited:(code)=>{if(root.cancellationPending||(code!==0&&root.operationId)){root.checkCancelled();return;}root.pendingOperation=({});root.savePreferences();root.finished(code===0&&root.operationVault===root.activeVault);if(code===0&&root.windowOpen)root.refresh();}}
 Process {id:receipt;stdout:StdioCollector {onStreamFinished:{try{let result=JSON.parse(text);root.uncertainReceipt=result.status!=="committed"&&result.status!=="not-committed";if(!root.uncertainReceipt){root.pendingOperation=({});root.savePreferences();}root.error=result.status==="committed"?"The action committed before it stopped.":result.status==="not-committed"?(root.operationError||"The action stopped before committing."):"Commit status is uncertain; inspect before retrying.";if(result.status==="committed"&&result.records.length&&root.operationVault===root.activeVault){root.operationResult=result.records[0];root.finished(true);}else if(result.record_unavailable)root.error="The action committed, but its record is unavailable. Inspect recovery before retrying.";else if(result.status==="not-committed")root.finished(false);if(root.windowOpen)root.refresh();}catch(e){root.error="Could not verify commit status; inspect before retrying.";}}}stderr:StdioCollector {onStreamFinished:if(text.trim())root.error=text.trim()}}
 Process {id:reader;stdout:StdioCollector {onStreamFinished:{if(!root.pendingPreview&&root.readerVault===root.activeVault)root.previewText=text.slice(0,14000);}}stderr:StdioCollector {onStreamFinished:if(root.readerVault===root.activeVault&&text.trim())root.error=text.trim()}onExited:{if(root.pendingPreview){let path=root.pendingPreview;root.pendingPreview="";Qt.callLater(()=>root.preview(path));}}}
 FileView {onLoadFailed:code=>{root.preferencesReady=true;if(code!==FileViewError.FileNotFound)root.error="Saved preferences are unavailable; preserve them before recovery.";};path:"@HOME@/.local/state/sensei-learning/window.json";printErrors:false;onLoaded:{try{let c=JSON.parse(text());root.drafts=c.drafts||({});root.layouts=c.layouts||({});NoesisStyle.interfaceScale=Math.min(2,Math.max(1,c.interface_scale||1));NoesisStyle.readingScale=Math.min(2,Math.max(1,c.reading_scale||1));root.windowWidth=c.width||1440;root.windowHeight=c.height||880;root.workspace=c.workspace||"Today";root.presentationMode=Quickshell.env("NOESIS_WINDOW_MODE")||c.presentation||"fullscreen";root.listRatio=c.list_ratio||0.38;root.currentContext=c.context||({});root.mainMonitor=Quickshell.env("NOESIS_MAIN_MONITOR")||c.monitor||"eDP-1";root.quiet=c.quiet||false;root.collectionScope=c.collection===true;root.placement=c.placement||"dedicated";root.studyWorkspace=c.study_workspace||"Study";root.returnBehavior=c.return_behavior||"hide";root.storedPathScope=c.path_scope||"";root.pathScopeVault=c.path_scope_vault||"";root.pathScope=root.pathScopeVault===root.activeVault?root.storedPathScope:"";if(c.pending_operation?.id){root.pendingOperation=c.pending_operation;root.operationId=c.pending_operation.id;root.operationVault=c.pending_operation.vault;root.operationKind=c.pending_operation.kind;if(root.hostReady)Qt.callLater(()=>root.checkCancelled());}}catch(e){root.error="Saved preferences could not be loaded: "+String(e);}root.preferencesReady=true;}}
 Timer {id:preferencesSave;interval:400;onTriggered:root.writePreferences()}
 Process {id:preferences;stdinEnabled:true;onStarted:write(root.preferenceDraftFrame);onExited:code=>{root.preferenceFailed=code!==0;if(code!==0){root.preferencesPending=false;if(root.operationQueued){root.operationQueued=false;root.error="Could not persist the draft/operation scope. No action was started.";}return;}if(root.preferencesPending){root.preferencesPending=false;root.writePreferences();return;}if(root.operationQueued){root.operationQueued=false;operation.running=true;}}}
 Timer {interval:15000;running:operation.running;onTriggered:{root.error="This action is taking longer than expected; inspect the result before retrying.";}}
 Process {id:requestResolver;command:["@HOME@/.local/bin/noesis","host-request","--stdin-line"];stdinEnabled:true;onStarted:write(root.requestFrame);stdout:StdioCollector {onStreamFinished:{try{let resolved=JSON.parse(text);root.openRequest=resolved;if(resolved.vault&&resolved.vault!==root.activeVault)root.choose(resolved.vault);root.open();}catch(error){root.markRequest(root.pendingRequest.request_id,"rejected",String(error));}}}stderr:StdioCollector {onStreamFinished:if(text.trim())root.markRequest(root.pendingRequest.request_id,"rejected",text.trim())}onExited:code=>{if(code!==0)root.markRequest(root.pendingRequest.request_id,"rejected","Requested owner or record is unavailable; no context was changed.");}}
 IpcHandler {target:"noesis";
  function hello():string{return JSON.stringify({version:1,build:root.buildIdentity,host:root.standalone?"standalone":"embedded",host_ready:root.hostReady,instance:root.instance,visible:root.windowOpen,working:root.working,exit_pending:root.exitRequested,uncertain:root.uncertainReceipt});}
  function open():void{root.open();}
  function hide():void{root.hide();}
  function close():void{root.hide();}
  function exit():void{root.requestExit();}
  function request(payload:string):string{try{let value=JSON.parse(Qt.atob(payload));if(value.version!==1||!value.request_id||!["open","resume","capture"].includes(value.action))throw new Error("Unsupported launch request");if(root.acceptedRequests[value.request_id])return JSON.stringify(root.acceptedRequests[value.request_id]);if(!root.hostReady)throw new Error("Another host owns this learning session");if(root.working||root.uncertainReceipt)throw new Error("Finish or inspect the pending action before changing context");if(requestResolver.running)throw new Error("Another launch request is being resolved");root.pendingRequest=value;root.requestFrame=JSON.stringify(value)+"\n";requestResolver.running=true;let ack={version:1,request_id:value.request_id,status:"received",instance:root.instanceToken};root.acceptedRequests=Object.assign({},root.acceptedRequests,{[value.request_id]:ack});return JSON.stringify(ack);}catch(error){return JSON.stringify({version:1,status:"rejected",error:String(error)});}}
  function requestStatus(id:string):string{return JSON.stringify(root.acceptedRequests[id]||{version:1,status:"unknown"});}
  function status():string{return JSON.stringify(root.state);}
 }

}
