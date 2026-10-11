pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
 id:root
 property var data:({devices:[],history:[],logs:[]})
 property string error:""
 property var presence:({count:0,devices:[]})
 property var history:({events:[],total:0,offset:0})
 property string query:""
 property int offset:0
 property bool busy:poll.running
 function refresh(){if(!poll.running)poll.running=true;}
 function loadHistory(){if(!historyPoll.running){historyPoll.command=["/home/fh1m/.local/bin/sensei-usb","--history",query,String(offset)];historyPoll.running=true;}}
 function exportReport(){if(!exporter.running)exporter.running=true;}
 FileView {path:"/home/fh1m/.local/state/sensei-usb/presence.json";watchChanges:true;onFileChanged:reload();onLoaded:{try{root.presence=JSON.parse(text());}catch(e){}}}
 Process {id:historyPoll;stdout:StdioCollector {onStreamFinished:{try{root.history=JSON.parse(text);}catch(e){root.error=String(e);}}}}
 Process {id:exporter;command:["/home/fh1m/.local/bin/sensei-usb","--export"];stdout:StdioCollector {onStreamFinished:{try{let j=JSON.parse(text);root.error="Report saved: "+j.path;}catch(e){root.error=String(e);}}}}
 Process {id:poll;command:["/home/fh1m/.local/bin/sensei-usb"];stdout:StdioCollector {onStreamFinished:{try{root.data=JSON.parse(text);root.error=root.data.error||"";}catch(e){root.error=String(e);}}}}
 Timer {interval:2000;repeat:true;running:ShellState.dropdown==="usb";triggeredOnStart:true;onTriggered:root.refresh()}
}
