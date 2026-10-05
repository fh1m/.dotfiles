pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
Singleton {
 id:root
 property var devices:[]
 property var notificationRows:[]
 function updateDevices(next){if(!selectedId||!next.some(x=>x.id===selectedId)){let preferred=next.find(x=>x.isPaired&&x.name==="Phone")||next.find(x=>x.isPaired)||next[0];if(preferred)selectedId=preferred.id;}let d=next.find(x=>x.id===selectedId)||next[0]||{};let notes=d.notifications||[];if(JSON.stringify(notificationRows)!==JSON.stringify(notes))notificationRows=notes;if(JSON.stringify(devices)!==JSON.stringify(next))devices=next;}
 property var data:({vpn:{state:"Loading",ips:[],peers:[]},sync:{folders:[],connections:[]},adb:[],config:{host:"",user:"",port:8022}})
 property string clipboardDraft:""
 property string replyDraft:""
 property string notificationQuery:""
 property string commandDraft:""
 property int page:0
 property string selectedId:""
 onSelectedIdChanged:updateDevices(devices)
 readonly property var device:devices.find(d=>d.id===selectedId)||devices[0]||({plugins:[],notifications:[],commands:[],directories:{},battery:{}})
 readonly property bool ready:!!device.isPaired&&!!device.isReachable
 readonly property var phoneBluetooth:(Bluetooth.devices?.values??[]).find(d=>d.address?.toUpperCase()==="1C:E5:7F:B8:4B:46")??null
 readonly property bool phoneNearby:phoneBluetooth?.connected??false
 property var actionQueue:[]
 property string message:""
 property bool success:true
 readonly property bool working:operation.running
 function refresh(){if(!status.running)status.running=true;}
 function action(name,args,id){if(operation.running){let job={name:name,args:args||[],id:id===undefined?(device.id||" ").trim():id};let queue=actionQueue.filter(j=>!(j.name===name&&JSON.stringify(j.args)===JSON.stringify(job.args)));if(queue.length<12){actionQueue=queue.concat([job]);message="Queued · "+name;}else message="Sensei, the action queue is full; let the current requests finish.";return;}operation.command=["timeout","--signal=TERM","30s","/home/fh1m/.local/bin/sensei-phone","action",name,id===undefined?(device.id||""):id,JSON.stringify(args||[])];operation.running=true;message="Working…";}
 function open(){ShellState.dropdownAnchorX=16;ShellState.toggleDropdown("phone");}
 Component.onCompleted:refresh()
 Process {id:events;command:["/home/fh1m/.local/bin/sensei-phone","--watch"];running:true;stdout:SplitParser {onRead:line=>{try{let j=JSON.parse(line);root.updateDevices(j.devices||[]);}catch(e){}}}onExited:restart.start()}
 Timer {id:restart;interval:5000;onTriggered:events.running=true}
 Process {id:status;command:["timeout","20s","/home/fh1m/.local/bin/sensei-phone","--telemetry"];stdout:StdioCollector {onStreamFinished:{try{let j=JSON.parse(text);if(j.devices&&(!events.running||root.devices.length===0))root.updateDevices(j.devices);if(j.error&&!j.devices){root.message=j.error;root.success=false;}else if(JSON.stringify(root.data)!==JSON.stringify(j))root.data=j;}catch(e){root.message=String(e);root.success=false;}}}}
 Process {id:operation;stdout:StdioCollector {onStreamFinished:{try{let j=JSON.parse(text);root.message=j.output||j.error||(j.ok?"Done.":"Action failed.");root.success=!!j.ok;}catch(e){root.message=String(e);root.success=false;}}}onExited:{root.refresh();if(root.actionQueue.length){let job=root.actionQueue[0];root.actionQueue=root.actionQueue.slice(1);Qt.callLater(()=>root.action(job.name,job.args,job.id));}}}
 Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==="phone")root.refresh();}}
 // Device and notification updates are pushed over D-Bus. Mesh/sync telemetry
 // is sampled only while Phone is open, never every second on the idle bar.
 Timer {interval:5000;repeat:true;running:ShellState.dropdown==="phone";onTriggered:root.refresh()}
 IpcHandler {target:"phone";function toggle():void{root.open();}function refreshStatus():void{root.refresh();}function state():string{return JSON.stringify({devices:root.devices.length,ready:root.ready,vpn:root.data.vpn?.state,working:root.working,message:root.message});}}
}
