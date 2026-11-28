pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.services
Singleton {
 id:root
 IpcHandler {target:"ethernet-check";function state():string{return JSON.stringify({connected:root.connected,device:root.device,details:root.details,devices:(Networking.devices?.values??[]).map(d=>({name:d.name,type:d.type,connected:d.connected,state:d.state})),wired:DeviceType.Wired});}}
 property var links:[]
 Process {id:watch;running:true;command:[Quickshell.env("HOME")+"/.local/bin/sensei-ethernet","watch"];stdout:SplitParser {onRead:line=>{try{root.links=JSON.parse(line).links||[];}catch(e){}}}onExited:{root.links=[];retry.restart();}}
 Timer {id:retry;interval:4000;onTriggered:watch.running=true}
 readonly property bool connected:links.length>0
 readonly property string device:links[0]?.name??""
 function rate(v){return v>=1048576?(v/1048576).toFixed(1)+" MiB/s":v>=1024?(v/1024).toFixed(1)+" KiB/s":Math.round(v)+" B/s";}
 property var details:({})
 function refresh(){if(device&&!scan.running){scan.command=[Quickshell.env("HOME")+"/.local/bin/sensei-ethernet",device];scan.running=true;}}
 onDeviceChanged:{
    details={};
    if(device){refresh();return;}
    if(ShellState.dropdown==="ethernet")ShellState.dropdown="";
    if(ShellState.systemPage===3)ShellState.systemPage=0;
 }
 Process {id:scan;stdout:StdioCollector {onStreamFinished:{try{const d=JSON.parse(text);if(d.device===root.device)root.details=d;}catch(e){}}}onExited:if(root.device&&command[1]!==root.device)Qt.callLater(root.refresh)}
 Timer {interval:10000;repeat:true;running:ShellState.dropdown==="ethernet";onTriggered:root.refresh()}
}
