pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.services
Singleton {
 id:root
 readonly property bool active:ShellState.dropdown==='bluetooth'
 property var data:({devices:[],adapters:[],cards:[],sinks:[],streams:[],codecs:{}})
 property int page:0
 property string error:""
 property bool busy:act.running
 function refresh(){if(!poll.running)poll.running=true;}
 function device(address){return (data.devices||[]).find(d=>d.Address===address)||{};}
 function card(address){return (data.cards||[]).find(c=>c.properties?.['api.bluez5.address']===address)||{};}
 function codec(address){return data.codecs?.[address]||{};}
 function action(kind,address,value){if(act.running)return;error='';act.command=['@HOME@/.local/bin/sensei-bluetooth',kind,String(address),String(value)];act.running=true;}
 function tool(command){if(toolProc.running)return;toolProc.command=command;toolProc.running=true;}
 onActiveChanged:{events.running=active;if(active)refresh();}
 Process {id:poll;command:['@HOME@/.local/bin/sensei-bluetooth','snapshot'];stdout:StdioCollector{onStreamFinished:{try{let d=JSON.parse(text);if(d.error)root.error=d.error;else{root.data=d;root.error='';}}catch(e){root.error='Sensei, Bluetooth details could not be read.';}}}}
 Process {id:act;onExited:refreshTimer.restart();stdout:StdioCollector{onStreamFinished:{try{let d=JSON.parse(text);if(d.error)root.error=d.error;}catch(e){}}}}
 Process {id:toolProc}
 Process {id:events;running:root.active;command:['pactl','subscribe'];stdout:SplitParser{onRead:line=>{if(/sink|card|server/.test(line))refreshTimer.restart();}}}
 IpcHandler {target:'bluetooth';function page(value:int):string {root.page=Math.max(0,Math.min(3,value));return String(root.page);}function state():string{return JSON.stringify({page:root.page,busy:root.busy,error:root.error,connected:(Bluetooth.devices?.values??[]).filter(d=>d.connected).length,codecs:root.data.codecs});}}
 Instantiator {model:Bluetooth.devices?.values??[];delegate:QtObject {required property var modelData;property Connections changes:Connections {target:modelData;function onConnectedChanged(){if(root.active)refreshTimer.restart();}function onTrustedChanged(){if(root.active)refreshTimer.restart();}function onBlockedChanged(){if(root.active)refreshTimer.restart();}function onBatteryChanged(){if(root.active)refreshTimer.restart();}}}}
 Timer {id:refreshTimer;interval:180;onTriggered:root.refresh()}
 Timer {interval:10000;running:root.active;repeat:true;onTriggered:{root.refresh();if(!events.running)events.running=true;}}
}
