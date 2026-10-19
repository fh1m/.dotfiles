pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.config
Singleton {
 id:root
 property var data:({devices:[],tools:{},receipt:{},bands:[]})
 readonly property bool available:(data.devices||[]).length>0
 readonly property bool busy:action.running
 property string error:''
 property string note:''
 property var history:[]
 property var receipt:data.receipt||({})
 function run(verb,args){if(action.running)return;error='';note='';if(verb==='fm')SpotifyDesk.action('pause');action.command=[Quickshell.env('HOME')+'/.local/bin/sensei-radio',verb].concat(args||[]);action.running=true;}
 Process {id:watcher;running:MachineProfile.desktop;command:[Quickshell.env('HOME')+'/.local/bin/sensei-radio','watch'];stdout:SplitParser {onRead:line=>{try{root.data=JSON.parse(line);}catch(e){}}}}
 Process {id:action;stdout:StdioCollector {onStreamFinished:{try{const d=JSON.parse(text);root.error=d.error||'';if(d.kind){root.receipt=d;root.note=d.note||'Receiver receipt saved locally.';}else if(d.receipts)root.history=d.receipts;else if(d.opened)root.note='Gqrx opened · it owns the receiver until closed.';else if(d.stopped)root.note='FM stopped. The receiver is available for another action.';else if(d.devices)root.data=d;}catch(e){root.error='Radio action did not return a receipt.';}}}}
}
