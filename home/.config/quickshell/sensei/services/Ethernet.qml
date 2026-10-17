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
 Process {id:watch;running:true;command:[Quickshell.env("HOME")+"/.local/bin/sensei-ethernet","watch"];stdout:SplitParser {onRead:line=>{try{root.links=JSON.parse(line).links||[];}catch(e){}}}onExited:retry.restart()}
 Timer {id:retry;interval:4000;onTriggered:watch.running=true}
 readonly property bool connected:links.length>0
 readonly property string device:links[0]?.name??""
 function rate(v){return v>=1048576?(v/1048576).toFixed(1)+" MiB/s":v>=1024?(v/1024).toFixed(1)+" KiB/s":Math.round(v)+" B/s";}
 property var details:({})
 function refresh(){if(device&&!scan.running){scan.command=[Quickshell.env("HOME")+"/.local/bin/sensei-ethernet",device];scan.running=true;}}
 onDeviceChanged:refresh()
 Process {id:scan;stdout:StdioCollector {onStreamFinished:{try{root.details=JSON.parse(text);}catch(e){root.details={error:"Details unavailable"};}}}}
 Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==="ethernet")root.refresh();}}
 Timer {interval:10000;repeat:true;running:ShellState.dropdown==="ethernet";onTriggered:root.refresh()}
}
