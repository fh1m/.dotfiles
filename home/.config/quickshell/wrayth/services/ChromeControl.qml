pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {
 id:root
 property var data:({mode:"auto",actual:"closed",nvidiaAvailable:false,settingsPending:false})
 property string error:""
 readonly property bool busy:action.running
 Component.onCompleted: root.refresh()
 function refresh(){if(!query.running&&!action.running)query.running=true;}
 function run(args){if(action.running)return;error="";action.command=["/home/fh1m/.local/bin/sensei-chrome",...args];action.running=true;}
 Process {id:query;command:["/home/fh1m/.local/bin/sensei-chrome","status"];stdout:StdioCollector{onStreamFinished:{try{root.data=JSON.parse(text);}catch(e){root.error=String(e);}}}}
 Process {id:action;onExited:root.refresh();stdout:StdioCollector{onStreamFinished:{try{let d=JSON.parse(text);if(d.error)root.error=d.error;else root.data=d;}catch(e){}}}}
 Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==="monitor")root.refresh();}}
 Timer {interval:2000;repeat:true;running:ShellState.dropdown==="monitor"&&ShellState.monitorPage===2;onTriggered:root.refresh()}
}
