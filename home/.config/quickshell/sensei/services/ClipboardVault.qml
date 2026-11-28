pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {
 id: root
 property var items: []
 property var detail: ({})
 property int count: 0
 property int events: 0
 property int limit: 150
 property real bytes: 0
 property string query: ""
 property string filter: "all"
 property int selected: 0
 property bool paused:false
 property var pendingAction:null
 property string error: ""
 property bool loading:false
 property bool refreshPending:false
 property string listError:""
 function refresh() {
  debounce.stop();
  if (loading) {refreshPending=true;return;}
  list.requestedQuery=query;list.requestedFilter=filter;
  list.command=["@HOME@/.local/bin/clipboard-vault","list",query,filter,String(limit)];
  loading=true;list.running=true;
 }
 Component.onCompleted:if(ShellState.dropdown==="clipboard")refresh()
 function select(id) { selected=id;if(!preview.running)preview.running=true; }
 function action(name, id) {
 if(id)selected=id;
 if(act.running){pendingAction={name:name,id:selected};return;} if ((selected||name==="pause") && !act.running) {act.command=["@HOME@/.local/bin/clipboard-vault",name,String(selected)];act.running=true;} }
 onQueryChanged: debounce.restart()
 onFilterChanged: refresh()
 Timer { id:debounce; interval:220; onTriggered:root.refresh() }
 FileView {path:"@HOME@/.clipboard/revision";watchChanges:true;printErrors:false;onFileChanged:{reload();if(ShellState.dropdown==="clipboard")debounce.restart();}}
 // Opening the panel reads the vault again. The FileView above re-reads it
 // while the panel is open, whenever a revision changes.
 Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==="clipboard")root.refresh();}}
 Process {
  id:list
  property string requestedQuery:""
  property string requestedFilter:"all"
  stdout:StdioCollector {}
  onExited: code=>{
   const current=requestedQuery===root.query && requestedFilter===root.filter;
   if(current){
    try{
     if(code!==0)throw new Error("Could not read clipboard history. Reopen the vault to retry.");
     const d=JSON.parse(stdout.text);
     if(!Array.isArray(d.items))throw new Error("Clipboard history returned invalid data.");
     root.listError="";root.items=d.items;root.paused=d.paused??false;
     root.count=d.count;root.events=d.events;root.bytes=d.bytes;
     if(!d.items.some(item=>item.id===root.selected)){
      root.selected=0;root.detail=({});
      if(d.items.length)root.select(d.items[0].id);
     }
    }catch(e){root.listError=String(e);}
   }
   root.loading=false;
   if(root.refreshPending||!current){root.refreshPending=false;Qt.callLater(root.refresh);}
  }
 }
 Process { id:preview; property int requested:0; command:["@HOME@/.local/bin/clipboard-vault","detail",String(root.selected),"--plain"];onStarted:requested=root.selected;stdout:StdioCollector { onStreamFinished: {try {if(preview.requested===root.selected)root.detail=JSON.parse(text);}catch(e){root.error=String(e);} } }onExited:if(requested!==root.selected&&root.selected)Qt.callLater(()=>preview.running=true) }
 Process { id:act;stderr:StdioCollector {onStreamFinished:if(text.trim())root.error=text.trim()}onExited: {if(root.pendingAction){const next=root.pendingAction;root.pendingAction=null;Qt.callLater(()=>root.action(next.name,next.id));}root.refresh();if(root.selected && !preview.running)preview.running=true;} }
}
