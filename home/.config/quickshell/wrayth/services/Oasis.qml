pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
 id: root
 property var state: ({gates:[],reviews:[],questions:[],projects:[],labs:[],sources:[]})
 property string activeVault: ""
 property string error: ""
 readonly property bool working: operation.running
 function refresh() { if(!snapshot.running) snapshot.running=true; }
 function run(args) { if(operation.running)return;error="";operation.command=["@HOME@/.local/bin/oasis"].concat(args);operation.running=true; }
 function choose(path) {run(["use",path]);}
 function note(path) {run(["cli","open","path="+path]);}
 function open() {ShellState.dropdownAnchorX=16;ShellState.toggleDropdown("oasis");}
 FileView {path:"@HOME@/.config/sensei-learning/config.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.activeVault=JSON.parse(text()).active_vault||"";if(ShellState.dropdown==="oasis")debounce.restart();}catch(e){root.error=String(e);}}}
 FileView {path:root.activeVault?root.activeVault+"/00 Home/Current Frontier.md":"";watchChanges:true;printErrors:false;onFileChanged:{reload();if(ShellState.dropdown==="oasis")debounce.restart();}}
 Timer {id:debounce;interval:200;onTriggered:root.refresh()}
 Process {id:snapshot;command:["@HOME@/.local/bin/oasis","status"];stdout:StdioCollector {onStreamFinished:{try{if(text.trim())root.state=JSON.parse(text);}catch(e){root.error="Could not read the learning index.";}}}stderr:StdioCollector {onStreamFinished:if(text.trim())root.error=text.trim()}onExited:(code)=>{if(code===0)root.error="";}}
 Process {id:operation;stdout:StdioCollector {}stderr:StdioCollector {onStreamFinished:if(text.trim())root.error=text.trim()}onExited:(code)=>{if(code===0)root.refresh();}}
 Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==="oasis")root.refresh();}}
 IpcHandler {target:"oasis";function toggle():void{root.open();}function status():string{return JSON.stringify(root.state);}}
}
