pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {
 id:root
 IpcHandler {target:"controllers";function state():string{return JSON.stringify({count:root.data.controllers.length,active:root.active,busy:root.busy,selected:root.device.id||"",devices:root.data.controllers.map(c=>({id:c.id,name:c.name,axes:c.axes,pressed:c.pressed,events:c.events||[]})),report:root.report});}function select(id:string):bool{if(!root.data.controllers.some(c=>c.id===id))return false;root.selected=id;return true;}function view(index:int):void{if(index>=0&&index<=3)root.page=index;}}
 property var data:({controllers:[]})
 property string report:"Live input stays on this machine. No device grab."
 readonly property bool active:ShellState.dropdown==='controllers'
 property string exportPath:""
 property string exportCommand:""
 property string exportDevice:""
 property var environments:["host"]
 property int page:0
 onPageChanged:if(page===3)envScan.running=true
 Process {id:envScan;command:[Quickshell.env('HOME')+'/.local/bin/sensei-controllers','environments'];stdout:StdioCollector {onStreamFinished:{try{const d=JSON.parse(text);if(d.environments)root.environments=d.environments;}catch(e){root.report="Environment list unavailable; host testing remains available.";}}}}

 property string selected:""
 readonly property var device:data.controllers.find(c=>c.id===selected)||data.controllers[0]||({})
 function accept(line){try{const d=JSON.parse(line);if(Array.isArray(d.controllers))root.data=d;else if(d.error)root.report=d.error;}catch(e){root.report="Controller response unavailable; refresh to retry.";}}
 function refresh(){if(!scan.running)scan.running=true;}
 function action(name,value){if(worker.running||!device.id)return;if(name.startsWith("ros-"))exportDevice="";worker.command=[Quickshell.env('HOME')+'/.local/bin/sensei-controllers',name,device.id].concat(value!==undefined?[String(value)]:[]);worker.running=true;}
 Component.onCompleted:refresh()
 onActiveChanged:if(active)refresh()
 Timer {interval:10000;repeat:true;running:!root.active;onTriggered:root.refresh()}
 Process {id:scan;command:[Quickshell.env('HOME')+'/.local/bin/sensei-controllers','list'];stdout:StdioCollector {onStreamFinished:root.accept(text)}}
 Timer {id:watchRetry;interval:1000;onTriggered:if(root.active&&!worker.running)watch.running=true}
 Process {id:watch;onExited:if(root.active&&!worker.running)watchRetry.restart();running:root.active&&!worker.running;command:[Quickshell.env('HOME')+'/.local/bin/sensei-controllers','watch'];stdout:SplitParser {onRead:line=>root.accept(line)}}
 readonly property bool busy:worker.running
 Process {id:worker;onExited:root.refresh();stdout:SplitParser {onRead:line=>{try{const d=JSON.parse(line);if(d.path&&d.command){root.exportPath=d.path;root.exportCommand=d.command;root.exportDevice=root.device.id;}root.report=d.error||d.note||(d.phase?d.phase+' · '+d.remaining+'s':d.saved?'Saved '+d.saved:line);}catch(e){root.report='Controller tool returned an unreadable response';}}}}
}
