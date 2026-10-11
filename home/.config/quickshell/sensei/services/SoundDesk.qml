pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {
 id:root;property int page:0
 readonly property bool active:ShellState.dropdown==='sound'
 onActiveChanged:{events.running=active;if(active)root.refresh();}
 property var data:({sinks:[],sources:[],"sink-inputs":[],"source-outputs":[],cards:[]})
 property var ids:({sinks:[],sources:[],"sink-inputs":[],"source-outputs":[],cards:[],ports:[]});property var routeOutputs:[];property var routeInputs:[]
 function node(kind,id){return (data[kind]||[]).find(n=>n.index===id)||{};}
 function accept(d){let fresh={};for(let kind of ["sinks","sources","sink-inputs","source-outputs","cards"]){let rows=d[kind]||[];if(kind==='sources')rows=rows.filter(n=>!n.name.endsWith('.monitor'));const next=rows.map(n=>n.index);fresh[kind]=JSON.stringify(next)===JSON.stringify(ids[kind])?ids[kind]:next;}const ports=fresh.sinks.map(i=>"sinks:"+i).concat(fresh.sources.map(i=>"sources:"+i));fresh.ports=JSON.stringify(ports)===JSON.stringify(ids.ports)?ids.ports:ports;for(let key of Object.keys(fresh))if(fresh[key]!==ids[key]){ids=fresh;break;}let outputs=(d.sinks||[]).map(n=>({index:n.index,name:n.name,description:n.description})),inputs=(d.sources||[]).filter(n=>!n.name.endsWith('.monitor')).map(n=>({index:n.index,name:n.name,description:n.description}));if(JSON.stringify(outputs)!==JSON.stringify(routeOutputs))routeOutputs=outputs;if(JSON.stringify(inputs)!==JSON.stringify(routeInputs))routeInputs=inputs;data=d;}
 property string error:"";property var pending:[]
 function refresh(){if(!poll.running)poll.running=true;}
 function execute(command){if(act.running){let next=pending.slice();const key=command[1]+':'+command[2];let at=next.findIndex(c=>c[1]+':'+c[2]===key);if(at>=0)next[at]=command;else next.push(command);pending=next;return;}act.command=command;act.running=true;}
 function action(kind,id,value){execute(["/home/fh1m/.local/bin/sensei-audio",kind,String(id),String(value)]);}
 function channel(node,key,value){const values=Object.entries(node.volume??{}).map(([k,v])=>k===key?Math.round(value)+'%':String(v.value));execute(["/home/fh1m/.local/bin/sensei-audio","volume",String(node.index)].concat(values));}
 function level(node){let v=Object.values(node.volume??{});return v.length?parseInt(v[0].value_percent)||0:0;}
 Process {id:poll;command:["/home/fh1m/.local/bin/sensei-audio","list"];stdout:StdioCollector {onStreamFinished:{try{root.accept(JSON.parse(text));}catch(e){}}}}
 Process {id:act;onExited:{audioRefresh.restart();if(root.pending.length){let next=root.pending[0];root.pending=root.pending.slice(1);Qt.callLater(()=>root.execute(next));}}stderr:StdioCollector {onStreamFinished:root.error=text.trim()}}
 Timer {id:audioRefresh;interval:70;onTriggered:root.refresh()}
 Process {id:events;running:ShellState.dropdown==='sound';command:['pactl','subscribe'];stdout:SplitParser {onRead:line=>{if(/sink|source|card|server/.test(line))audioRefresh.restart();}}}
 Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==='sound')root.refresh();}}
 // A low-frequency fallback recovers from a dropped subscription connection.
 Timer {interval:15000;running:ShellState.dropdown==='sound';repeat:true;onTriggered:{root.refresh();if(!events.running)events.running=true;}}

}
