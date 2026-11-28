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
 property var historyRequest:null
 property var pendingHistory:null
 function refresh(){if(!poll.running)poll.running=true;}
 function startHistory(request){historyRequest=request;historyPoll.command=["@HOME@/.local/bin/sensei-usb","--history",request.query,String(request.offset)];historyPoll.running=true;}
 function loadHistory(){const request={query:query,offset:offset};if(historyPoll.running){pendingHistory=request;return;}startHistory(request);}
 function acceptHistory(text){const request=historyRequest;if(!request||request.query!==query||request.offset!==offset)return;try{root.history=JSON.parse(text);root.error="";}catch(e){root.error=String(e);}}
 onQueryChanged:if(historyPoll.running)pendingHistory={query:query,offset:offset}
 onOffsetChanged:if(historyPoll.running)pendingHistory={query:query,offset:offset}
 function exportReport(){if(!exporter.running)exporter.running=true;}
 FileView {path:"@HOME@/.local/state/sensei-usb/presence.json";watchChanges:true;onFileChanged:reload();onLoaded:{try{root.presence=JSON.parse(text());}catch(e){}}}
 Process {id:historyPoll;stdout:StdioCollector {onStreamFinished:root.acceptHistory(text)}onExited:{root.historyRequest=null;if(root.pendingHistory){const request=root.pendingHistory;root.pendingHistory=null;if(request.query===root.query&&request.offset===root.offset)Qt.callLater(()=>root.startHistory(request));}}}
 Process {id:exporter;command:["@HOME@/.local/bin/sensei-usb","--export"];stdout:StdioCollector {onStreamFinished:{try{let j=JSON.parse(text);root.error="Report saved: "+j.path;}catch(e){root.error=String(e);}}}}
 Process {id:poll;command:["@HOME@/.local/bin/sensei-usb"];stdout:StdioCollector {onStreamFinished:{try{root.data=JSON.parse(text);root.error=root.data.error||"";}catch(e){root.error=String(e);}}}}
 Timer {interval:2000;repeat:true;running:ShellState.dropdown==="usb";triggeredOnStart:true;onTriggered:root.refresh()}
}
