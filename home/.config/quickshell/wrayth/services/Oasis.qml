pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
 id:root
 property var state:({notes:[],files:[],vaults:[],gates:[],reviews:[],questions:[],projects:[],labs:[],sources:[]})
 property bool windowOpen:false
 property bool legacyInterface:false
 property string workspace:"Today"
 property string mainMonitor:"eDP-1"
 property bool quiet:false
 property string pathScope:""
 property string storedPathScope:""
 property string pathScopeVault:""
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
 property string previewText:""
 property string previewPath:""
 property string pendingPreview:""
 property bool refreshPending:false
 readonly property bool working:operation.running||receipt.running||cancellationPending
 signal finished(bool ok)
 function refresh(){if(snapshot.running){refreshPending=true;return;}snapshotVault=activeVault;snapshot.command=["@HOME@/.local/bin/noesis","status","--vault",snapshotVault];if(legacyInterface)snapshot.command.push("--legacy");snapshot.running=true;}
 function operationUuid(){return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g,c=>{let r=Math.floor(Math.random()*16);return (c==="x"?r:(r&3)|8).toString(16);});}
 function run(args){if(working){error="Let the current action finish.";return;}error="";message="";operationKind=args[0];operationVault=activeVault;operationResult=({});operationId="";cancellationPending=false;let bound=args.slice();operationInput="";if(operationKind==="capture"&&bound.length===2){operationInput=JSON.stringify(bound[1])+"\n";bound=["capture","--stdin-line"];}if(["capture","event","attempt","progress","artifact-check"].includes(operationKind)){operationId=operationUuid();bound.push("--operation-id",operationId);}if(bound[0]!=="use"&&bound[0]!=="window-state"&&bound[0]!=="vaults"){bound.splice(1,0,"--vault",operationVault);}operation.command=["@HOME@/.local/bin/noesis"].concat(bound);operation.running=true;}
 function choose(path){previewText="";previewPath="";pendingPreview="";run(["use",path]);}
 function note(path){run(["cli","open","path="+path]);}
 function preview(path){previewPath=path;previewText="Loading note…";if(reader.running){pendingPreview=path;return;}readerVault=activeVault;reader.command=["@HOME@/.local/bin/noesis","preview",path,"--vault",root.activeVault];reader.running=true;}
 function open(){windowOpen=true;openSerial++;refresh();Quickshell.execDetached(["hyprctl","dispatch",'hl.dsp.focus({window="title:^Noesis — Learning workspace$"})']);}
 function close(){windowOpen=false;}
 onWindowOpenChanged:{watch.running=legacyInterface&&windowOpen&&activeVault!=="";}
 onLegacyInterfaceChanged:watch.running=legacyInterface&&windowOpen&&activeVault!==""
 function setPathScope(identity){pathScope=identity;storedPathScope=identity;pathScopeVault=activeVault;savePreferences();}
 function savePreferences(){preferencesSave.restart();}
 onActiveVaultChanged:{pathScope=pathScopeVault===activeVault?storedPathScope:"";watch.running=false;previewText="";previewPath="";state=({notes:[],files:[],vaults:[],gates:[],reviews:[],questions:[],projects:[],labs:[],sources:[]});Qt.callLater(()=>{watch.running=legacyInterface&&windowOpen&&activeVault!=="";if(windowOpen)debounce.restart();});}
 function cancel(){if(!operation.running)return;cancellationPending=true;operation.running=false;error="Checking whether the action committed…";}
 function checkCancelled(){cancellationPending=false;if(operationId){receipt.command=["@HOME@/.local/bin/noesis","operation-status",operationId,"--vault",operationVault];receipt.running=true;}else{error="Action stopped. Its commit status is uncertain; inspect before retrying.";refresh();}}
 FileView {path:"@HOME@/.config/sensei-learning/config.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.activeVault=JSON.parse(text()).active_vault||"";if(root.windowOpen)debounce.restart();}catch(e){root.error=String(e);}}}
 FileView {path:root.activeVault?root.activeVault+"/"+(root.state.frontier_path||"00 Home/Current Frontier.md"):"";watchChanges:true;printErrors:false;onFileChanged:{reload();if(root.windowOpen)debounce.restart();}}
 Process {id:watch;command:["@HOME@/.local/bin/sensei-learning-watch",root.activeVault];stdout:SplitParser {onRead:debounce.restart()}}
 Timer {id:debounce;interval:400;onTriggered:root.refresh()}
 Process {id:snapshot;command:["@HOME@/.local/bin/noesis","status"];stdout:StdioCollector {onStreamFinished:{try{if(text.trim()&&root.snapshotVault===root.activeVault)root.state=JSON.parse(text);}catch(e){root.error="Could not read the learning index.";}}}stderr:StdioCollector {onStreamFinished:if(root.snapshotVault===root.activeVault&&text.trim())root.error=text.trim()}onExited:(code)=>{if(root.refreshPending){root.refreshPending=false;Qt.callLater(root.refresh);}}}
 Process {id:operation;stdinEnabled:true;onStarted:if(root.operationInput)write(root.operationInput);stdout:StdioCollector {onStreamFinished:if(root.operationVault===root.activeVault){root.message=root.operationKind==="capture"?"Captured locally.":text.trim().slice(0,220);try{let result=JSON.parse(text);root.operationResult=result;if(result.event)root.message=result.event.replace(/-/g," ")+" saved"+(result.outcome?" · "+result.outcome:"")+(result.assistance?" · assistance: "+result.assistance.join(", "):"");else if(result.created)root.message="Imported "+result.created.length+" sources; refreshed "+(result.existing||[]).length+" existing.";}catch(error){root.operationResult=({});}}}stderr:StdioCollector {onStreamFinished:if(root.operationVault===root.activeVault&&text.trim())root.error=text.trim()}onExited:(code)=>{if(root.cancellationPending){root.checkCancelled();return;}root.finished(code===0&&root.operationVault===root.activeVault);if(code===0)root.refresh();}}
 Process {id:receipt;stdout:StdioCollector {onStreamFinished:{try{let result=JSON.parse(text);if(root.operationVault!==root.activeVault)return;root.error=result.status==="committed"?"The action committed before it stopped.":result.status==="not-committed"?"The action stopped before committing.":"Commit status is uncertain; inspect before retrying.";if(result.status==="committed"&&result.records.length){root.operationResult=result.records[0];root.finished(true);}else if(result.record_unavailable)root.error="The action committed, but its record is unavailable. Inspect recovery before retrying.";root.refresh();}catch(e){root.error="Could not verify commit status; inspect before retrying.";}}}stderr:StdioCollector {onStreamFinished:if(text.trim())root.error=text.trim()}}
 Process {id:reader;stdout:StdioCollector {onStreamFinished:{if(!root.pendingPreview&&root.readerVault===root.activeVault)root.previewText=text.slice(0,14000);}}stderr:StdioCollector {onStreamFinished:if(root.readerVault===root.activeVault&&text.trim())root.error=text.trim()}onExited:{if(root.pendingPreview){let path=root.pendingPreview;root.pendingPreview="";Qt.callLater(()=>root.preview(path));}}}
 Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==="oasis"){ShellState.dropdown="";root.open();}}}
 FileView {path:"@HOME@/.local/state/sensei-learning/window.json";printErrors:false;onLoaded:{try{let c=JSON.parse(text());root.drafts=c.drafts||({});root.windowWidth=c.width||1440;root.windowHeight=c.height||880;root.workspace=c.workspace||"Today";root.listRatio=c.list_ratio||0.38;root.currentContext=c.context||({});root.mainMonitor=c.monitor||"eDP-1";root.quiet=c.quiet||false;root.storedPathScope=c.path_scope||"";root.pathScopeVault=c.path_scope_vault||"";root.pathScope=root.pathScopeVault===root.activeVault?root.storedPathScope:"";}catch(e){}}}
 Timer {id:preferencesSave;interval:400;onTriggered:{if(preferences.running){root.preferencesPending=true;return;}root.preferenceDraftFrame=JSON.stringify(root.drafts)+"\n";preferences.command=["@HOME@/.local/bin/noesis","window-state","--drafts-stdin","--path-scope",root.pathScope,"--path-scope-vault",root.activeVault,"--workspace",root.workspace,"--list-ratio",String(root.listRatio),"--context-json",JSON.stringify(root.currentContext),"--monitor",root.mainMonitor,"--quiet",root.quiet?"on":"off"];preferences.running=true;}}
 Process {id:preferences;stdinEnabled:true;onStarted:write(root.preferenceDraftFrame);onExited:if(root.preferencesPending){root.preferencesPending=false;preferencesSave.restart();}}
 Timer {interval:15000;running:operation.running;onTriggered:{root.error="This action is taking longer than expected; inspect the result before retrying.";}}
 IpcHandler {target:"noesis";function open():void{root.open();}function toggle():void{root.open();}function close():void{root.close();}function status():string{return JSON.stringify(root.state);}}
 IpcHandler {target:"oasis";function open():void{root.open();}function toggle():void{root.open();}function close():void{root.close();}function status():string{return JSON.stringify(root.state);}}
}
