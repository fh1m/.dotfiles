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
 property real listRatio:0.38
 property var currentContext:({})
 signal captureRequested()
 property int openSerial:0
 property int windowWidth:1440
 property int windowHeight:880
 property string snapshotVault:""
 property string readerVault:""
 property string operationVault:""
 property string operationKind:""
 property string activeVault:""
 property string error:""
 property string message:""
 property var operationResult:({})
 property string previewText:""
 property string previewPath:""
 property string pendingPreview:""
 property bool refreshPending:false
 readonly property bool working:operation.running
 signal finished(bool ok)
 function refresh(){if(snapshot.running){refreshPending=true;return;}snapshotVault=activeVault;snapshot.command=["@HOME@/.local/bin/noesis","status","--vault",snapshotVault];if(legacyInterface)snapshot.command.push("--legacy");snapshot.running=true;}
 function run(args){if(operation.running){error="Let the current action finish.";return;}error="";message="";operationKind=args[0];operationVault=activeVault;let bound=args.slice();if(bound[0]!=="use"&&bound[0]!=="window-state"&&bound[0]!=="vaults"){bound.splice(1,0,"--vault",operationVault);}operation.command=["@HOME@/.local/bin/noesis"].concat(bound);operation.running=true;}
 function choose(path){previewText="";previewPath="";pendingPreview="";run(["use",path]);}
 function note(path){run(["cli","open","path="+path]);}
 function preview(path){previewPath=path;previewText="Loading note…";if(reader.running){pendingPreview=path;return;}readerVault=activeVault;reader.command=["@HOME@/.local/bin/noesis","preview",path,"--vault",root.activeVault];reader.running=true;}
 function open(){windowOpen=true;openSerial++;refresh();Quickshell.execDetached(["hyprctl","dispatch",'hl.dsp.focus({window="title:^Noesis — Learning workspace$"})']);}
 function close(){windowOpen=false;}
 onWindowOpenChanged:{watch.running=legacyInterface&&windowOpen&&activeVault!=="";}
 onLegacyInterfaceChanged:watch.running=legacyInterface&&windowOpen&&activeVault!==""
 function savePreferences(){preferencesSave.restart();}
 onActiveVaultChanged:{watch.running=false;previewText="";previewPath="";state=({notes:[],files:[],vaults:[],gates:[],reviews:[],questions:[],projects:[],labs:[],sources:[]});Qt.callLater(()=>{watch.running=legacyInterface&&windowOpen&&activeVault!=="";if(windowOpen)debounce.restart();});}
 function cancel(){operation.running=false;error="Action cancelled. Refresh to inspect any completed write.";refresh();}
 FileView {path:"@HOME@/.config/sensei-learning/config.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.activeVault=JSON.parse(text()).active_vault||"";if(root.windowOpen)debounce.restart();}catch(e){root.error=String(e);}}}
 FileView {path:root.activeVault?root.activeVault+"/"+(root.state.frontier_path||"00 Home/Current Frontier.md"):"";watchChanges:true;printErrors:false;onFileChanged:{reload();if(root.windowOpen)debounce.restart();}}
 Process {id:watch;command:["@HOME@/.local/bin/sensei-learning-watch",root.activeVault];stdout:SplitParser {onRead:debounce.restart()}}
 Timer {id:debounce;interval:400;onTriggered:root.refresh()}
 Process {id:snapshot;command:["@HOME@/.local/bin/noesis","status"];stdout:StdioCollector {onStreamFinished:{try{if(text.trim()&&root.snapshotVault===root.activeVault)root.state=JSON.parse(text);}catch(e){root.error="Could not read the learning index.";}}}stderr:StdioCollector {onStreamFinished:if(text.trim())root.error=text.trim()}onExited:(code)=>{if(code===0)root.error="";if(root.refreshPending){root.refreshPending=false;Qt.callLater(root.refresh);}}}
 Process {id:operation;stdout:StdioCollector {onStreamFinished:if(root.operationVault===root.activeVault){root.message=root.operationKind==="capture"?"Captured locally.":text.trim().slice(0,220);try{let result=JSON.parse(text);root.operationResult=result;if(result.event)root.message=result.event.replace(/-/g," ")+" saved"+(result.outcome?" · "+result.outcome:"")+(result.assistance?" · assistance: "+result.assistance.join(", "):"");else if(result.created)root.message="Imported "+result.created.length+" sources; refreshed "+(result.existing||[]).length+" existing.";}catch(error){root.operationResult=({});}}}stderr:StdioCollector {onStreamFinished:if(text.trim())root.error=text.trim()}onExited:(code)=>{root.finished(code===0&&root.operationVault===root.activeVault);if(code===0)root.refresh();}}
 Process {id:reader;stdout:StdioCollector {onStreamFinished:{if(!root.pendingPreview&&root.readerVault===root.activeVault)root.previewText=text.slice(0,14000);}}stderr:StdioCollector {onStreamFinished:if(text.trim())root.error=text.trim()}onExited:{if(root.pendingPreview){let path=root.pendingPreview;root.pendingPreview="";Qt.callLater(()=>root.preview(path));}}}
 Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==="oasis"){ShellState.dropdown="";root.open();}}}
 FileView {path:"@HOME@/.local/state/sensei-learning/window.json";printErrors:false;onLoaded:{try{let c=JSON.parse(text());root.windowWidth=c.width||1440;root.windowHeight=c.height||880;root.workspace=c.workspace||"Today";root.listRatio=c.list_ratio||0.38;root.currentContext=c.context||({});root.mainMonitor=c.monitor||"eDP-1";root.quiet=c.quiet||false;}catch(e){}}}
 Timer {id:preferencesSave;interval:400;onTriggered:{preferences.command=["@HOME@/.local/bin/noesis","window-state","--workspace",root.workspace,"--list-ratio",String(root.listRatio),"--context-json",JSON.stringify(root.currentContext),"--monitor",root.mainMonitor,"--quiet",root.quiet?"on":"off"];preferences.running=true;}}
 Process {id:preferences}
 Timer {interval:15000;running:operation.running;onTriggered:{root.error="This action is taking longer than expected; inspect the result before retrying.";}}
 IpcHandler {target:"noesis";function open():void{root.open();}function toggle():void{root.open();}function close():void{root.close();}function status():string{return JSON.stringify(root.state);}}
 IpcHandler {target:"oasis";function open():void{root.open();}function toggle():void{root.open();}function close():void{root.close();}function status():string{return JSON.stringify(root.state);}}
}
