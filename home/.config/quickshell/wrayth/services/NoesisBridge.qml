pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {
 id:root
 property var projection:({})
 property bool publisherLive:false
 readonly property var currentContext:publisherLive?(projection.context||{}):({})
 readonly property string activeVault:currentContext.vault||""
 readonly property bool windowOpen:publisherLive&&projection.visible===true
 function startLearning(){Quickshell.execDetached(["@HOME@/.local/bin/noesis","window","--start"]);}
 function open(){Quickshell.execDetached(["@HOME@/.local/bin/noesis","window"]);}
 function resume(){if(currentContext.id&&currentContext.vault_id)Quickshell.execDetached(["@HOME@/.local/bin/noesis","window","--owner",currentContext.vault,"--vault-id",currentContext.vault_id,"--record-id",currentContext.id]);else open();}
 function capture(){let command=["@HOME@/.local/bin/noesis","window","--capture"];if(currentContext.vault_id)command.push("--owner",currentContext.vault,"--vault-id",currentContext.vault_id);if(currentContext.id)command.push("--record-id",currentContext.id);Quickshell.execDetached(command);}
 FileView {id:contextFile;path:"@HOME@/.local/state/sensei-learning/companion.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoadFailed:root.publisherLive=false;onLoaded:{try{let value=JSON.parse(text());let instance=value.instance;let valid=value.version===1&&Number.isInteger(instance?.pid)&&instance.pid>0&&/^[0-9]+$/.test(String(instance.start_ticks||""));let context={};for(let key of ["id","path","title","type","vault","vault_id","surface","session_state","tab","read_anchor"]){let field=value.context?.[key];if(typeof field==="string")context[key]=field.slice(0,key==="title"?256:8192);else if(key==="read_anchor"&&typeof field==="number"&&Number.isFinite(field))context[key]=Math.min(1,Math.max(0,field));}root.projection=valid?{version:1,instance:{pid:instance.pid,start_ticks:String(instance.start_ticks),token:instance.token},visible:value.visible===true,context:context}:({});root.publisherLive=false;Qt.callLater(()=>processStat.reload());}catch(error){root.projection=({});root.publisherLive=false;}}}
 FileView {id:processStat;path:root.projection.instance?.pid?"/proc/"+root.projection.instance.pid+"/stat":"";printErrors:false;onLoadFailed:root.publisherLive=false;onLoaded:{try{let fields=text().split(") ").pop().trim().split(/\s+/);root.publisherLive=fields[0]!=="Z"&&fields[19]===String(root.projection.instance.start_ticks);}catch(error){root.publisherLive=false;}}}
 Timer {interval:5000;running:!!root.projection.instance?.pid;repeat:true;onTriggered:processStat.reload()}
 Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==="oasis"){ShellState.dropdown="";root.open();}}}
 IpcHandler {target:"noesis-bridge";function state():string{return JSON.stringify({live:root.publisherLive,context:root.currentContext,visible:root.windowOpen});}}
 IpcHandler {target:"oasis";function open():void{root.open();}function toggle():void{root.open();}function close():void{Quickshell.execDetached(["@HOME@/.local/opt/sensei-quickshell/bin/qs","-p",Quickshell.env("NOESIS_HOST")==="embedded"?"@HOME@/.config/quickshell/wrayth":"@HOME@/.config/quickshell/noesis","ipc","call","noesis","hide"]);}}
}
